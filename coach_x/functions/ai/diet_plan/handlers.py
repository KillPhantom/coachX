"""
饮食计划 Cloud Functions 处理器

处理饮食计划相关的 AI 生成请求
"""

from firebase_functions import https_fn, options
from typing import Dict, Any, Optional
import json
from flask import Response

from ..claude_client import get_claude_client
from ..streaming import stream_edit_diet_plan_conversation
from ..claude_skills.skill_caller import call_nutrition_calculator_skill
from utils.logger import logger
from utils.param_parser import parse_int_param, parse_float_param


@https_fn.on_call(
    secrets=["ANTHROPIC_API_KEY"],
    timeout_sec=300,  # Claude Skills 需要较长执行时间
    memory=options.MemoryOption.MB_512
)
def generate_diet_plan_with_skill(req: https_fn.CallableRequest):
    """
    使用 Claude Skill 生成饮食计划

    请求参数:
        - weight_kg: float, 体重（公斤）
        - height_cm: float, 身高（厘米）
        - age: int, 年龄
        - gender: str, 性别 ("male" | "female")
        - activity_level: str, 活动水平
        - goal: str, 目标 ("muscle_gain" | "fat_loss" | "maintenance")
        - body_fat_percentage: float, 可选，体脂率
        - training_plan_id: str, 可选，训练计划ID（用于获取训练计划并应用碳循环）
        - dietary_preferences: list, 可选，饮食偏好
        - meal_count: int, 可选，每日餐数
        - allergies: list, 可选，过敏信息
        - plan_duration_days: int, 可选，计划天数

    返回:
        {
            'status': 'success' | 'error',
            'data': {
                'bmr_kcal': float,
                'tdee_kcal': float,
                'target_calories_kcal': float,
                'diet_plan': {...}  // DietPlanModel 格式
            },
            'message': str
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "用户未登录")

        user_id = req.auth.uid
        logger.info(f"🥗 AI生成饮食计划 - 用户: {user_id}")

        # 获取必需参数
        weight_kg = req.data.get("weight_kg")
        height_cm = req.data.get("height_cm")
        age = req.data.get("age")
        gender = req.data.get("gender")
        activity_level = req.data.get("activity_level")
        goal = req.data.get("goal")

        # 验证必需参数
        if not all([weight_kg, height_cm, age, gender, activity_level, goal]):
            raise https_fn.HttpsError(
                "invalid-argument",
                "缺少必需参数: weight_kg, height_cm, age, gender, activity_level, goal"
            )

        # 构建 skill 参数
        skill_params = {
            "weight_kg": parse_float_param(weight_kg),
            "height_cm": parse_float_param(height_cm),
            "age": parse_int_param(age),
            "gender": gender,
            "activity_level": activity_level,
            "goal": goal,
        }

        # 添加可选参数
        if req.data.get("body_fat_percentage"):
            skill_params["body_fat_percentage"] = parse_float_param(req.data["body_fat_percentage"])

        if req.data.get("meal_count"):
            skill_params["meal_count"] = parse_int_param(req.data["meal_count"])

        if req.data.get("dietary_preferences"):
            skill_params["dietary_preferences"] = req.data["dietary_preferences"]

        if req.data.get("allergies"):
            skill_params["allergies"] = req.data["allergies"]

        # 先处理训练计划和碳循环逻辑
        has_training_plan = False
        training_plan_id = req.data.get("training_plan_id")
        if training_plan_id:
            logger.info(f"引用训练计划: {training_plan_id}")
            # 获取训练计划数据
            from google.cloud import firestore
            db = firestore.client()
            plan_ref = db.collection("exercisePlans").document(training_plan_id)
            plan_doc = plan_ref.get()

            if plan_doc.exists:
                plan_data = plan_doc.to_dict()
                # 转换为 skill 需要的格式
                training_schedule = _convert_training_plan_to_skill_format(plan_data)
                if training_schedule:
                    skill_params["training_plan"] = training_schedule
                    has_training_plan = True

                    # 如果有训练计划，默认启用碳循环
                    if "dietary_preferences" not in skill_params:
                        skill_params["dietary_preferences"] = []
                    if "carb_cycling" not in skill_params["dietary_preferences"]:
                        skill_params["dietary_preferences"].append("carb_cycling")

                    logger.info("✅ 训练计划已转换并启用碳循环")
            else:
                logger.warning(f"⚠️ 训练计划不存在: {training_plan_id}")

        # 获取前端传入的计划天数，默认为 1 天
        plan_duration_days = parse_int_param(req.data.get("plan_duration_days", 1))

        # 如果是碳循环模式，验证天数至少为 3
        if has_training_plan and "carb_cycling" in skill_params.get("dietary_preferences", []):
            if plan_duration_days < 3:
                logger.warning(f"⚠️ 碳循环模式至少需要 3 天，自动调整：{plan_duration_days} -> 3")
                plan_duration_days = 3
            logger.info(f"✅ 碳循环模式，使用 {plan_duration_days} 天计划")
        else:
            logger.info(f"ℹ️ 使用前端传入的计划天数: {plan_duration_days} 天")

        skill_params["plan_duration_days"] = plan_duration_days

        # 记录详细参数
        logger.info("=" * 70)
        logger.info("📋 Skill 调用参数详情:")
        logger.info(f"   plan_duration_days: {skill_params.get('plan_duration_days')}")
        logger.info(f"   meal_count: {skill_params.get('meal_count', 'default')}")
        logger.info(f"   dietary_preferences: {skill_params.get('dietary_preferences', [])}")
        logger.info(f"   完整参数: {json.dumps(skill_params, ensure_ascii=False, indent=2)}")
        logger.info("=" * 70)

        # 调用 nutrition-calculator skill
        skill_result = call_nutrition_calculator_skill(skill_params)

        if not skill_result.get("success"):
            error_msg = skill_result.get("error", "Skill 调用失败")
            logger.error(f"❌ {error_msg}")
            raise https_fn.HttpsError("internal", error_msg)

        # 提取结果
        result_data = skill_result["data"]
        diet_plan_recommendation = result_data.get("diet_plan_recommendation", {})

        logger.info(f"✅ 饮食计划生成成功 - {len(diet_plan_recommendation.get('days', []))} 天")

        return {
            "status": "success",
            "data": {
                "bmr_kcal": result_data.get("bmr_kcal"),
                "tdee_kcal": result_data.get("tdee_kcal"),
                "target_calories_kcal": result_data.get("target_calories_kcal"),
                "diet_plan": diet_plan_recommendation,
            },
            "message": "饮食计划生成成功",
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ 生成饮食计划失败: {str(e)}", exc_info=True)
        raise https_fn.HttpsError("internal", f"服务器错误: {str(e)}")


def _convert_training_plan_to_skill_format(plan_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    将训练计划转换为 skill 需要的格式

    Args:
        plan_data: Firestore 中的训练计划数据

    Returns:
        Skill 格式的训练计划，或 None
    """
    try:
        days = plan_data.get("days", [])
        if not days:
            return None

        schedule = []
        for day_data in days:
            day_num = day_data.get("day", len(schedule) + 1)
            exercises = day_data.get("exercises", [])

            if not exercises:
                # 休息日
                schedule.append({
                    "day": day_num,
                    "type": "rest"
                })
            else:
                # 判断训练类型（简化版，实际可以更智能）
                schedule.append({
                    "day": day_num,
                    "type": "strength",  # 默认力量训练
                    "focus": "full_body",  # 默认全身
                    "intensity": "moderate"  # 默认中等强度
                })

        return {
            "days_per_week": len([s for s in schedule if s.get("type") != "rest"]),
            "schedule": schedule
        }

    except Exception as e:
        logger.error(f"❌ 训练计划转换失败: {str(e)}", exc_info=True)
        return None


@https_fn.on_request(
    timeout_sec=540,
    secrets=["ANTHROPIC_API_KEY"],
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post", "options"]),
)
def edit_diet_plan_conversation(req: https_fn.Request) -> Response:
    """
    对话式编辑饮食计划（SSE）

    请求参数（JSON Body）:
        - user_id: str, 用户ID
        - plan_id: str, 计划ID
        - user_message: str, 用户的修改请求
        - current_plan: dict, 当前完整计划数据

    返回:
        SSE 流式响应
    """
    try:
        logger.info("🔄 收到饮食计划编辑对话请求")

        # 获取请求数据
        try:
            params = req.get_json()
            if not params:
                raise ValueError("请求体为空")
        except Exception as e:
            logger.error(f"❌ 解析请求失败: {str(e)}")
            return Response(
                f'data: {json.dumps({"type": "error", "error": "请求格式错误"}, ensure_ascii=False)}\n\n',
                mimetype="text/event-stream",
            )

        user_id = params.get("user_id")
        plan_id = params.get("plan_id")
        user_message = params.get("user_message")
        current_plan = params.get("current_plan")

        # 验证必需参数
        if not all([user_id, plan_id, user_message, current_plan]):
            error_event = json.dumps(
                {"type": "error", "error": "缺少必需参数"}, ensure_ascii=False
            )
            return Response(f"data: {error_event}\n\n", mimetype="text/event-stream")

        logger.info(f"用户: {user_id}, 计划: {plan_id}")
        logger.info(f"用户请求: {user_message[:100]}...")

        def generate():
            """SSE 生成器"""
            try:
                # 调用流式编辑
                for event in stream_edit_diet_plan_conversation(
                    user_id=user_id,
                    user_message=user_message,
                    current_plan=current_plan,
                    plan_id=plan_id,
                ):
                    # 格式化为 SSE 格式
                    event_data = json.dumps(event, ensure_ascii=False)
                    yield f"data: {event_data}\n\n"

                    # 如果是错误或完成，结束流
                    if event.get("type") in ["error", "complete"]:
                        break

            except Exception as e:
                logger.error(f"❌ 流式编辑异常: {str(e)}", exc_info=True)
                error_event = json.dumps(
                    {"type": "error", "error": f"编辑失败: {str(e)}"},
                    ensure_ascii=False,
                )
                yield f"data: {error_event}\n\n"

        # 返回 SSE 响应
        return Response(
            generate(),
            mimetype="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
                "Connection": "keep-alive",
            },
        )

    except Exception as e:
        logger.error(f"❌ 编辑对话处理失败: {str(e)}", exc_info=True)
        error_event = json.dumps(
            {"type": "error", "error": f"服务器错误: {str(e)}"}, ensure_ascii=False
        )
        return Response(f"data: {error_event}\n\n", mimetype="text/event-stream")
