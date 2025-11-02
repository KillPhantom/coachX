"""
训练计划 Cloud Functions 处理器

处理训练计划相关的 AI 生成请求
"""

from firebase_functions import https_fn, options
from typing import Dict, Any, Optional
import json
from flask import Response

from ..claude_client import get_claude_client
from .prompts import (
    build_full_plan_prompt,
    build_next_day_prompt,
    build_exercises_prompt,
    build_sets_prompt,
    build_optimize_prompt,
    build_structured_plan_prompt,
)
from .utils import validate_plan_structure, fix_plan_structure
from ..models import AIGenerationResponse
from utils.logger import logger
from utils.param_parser import parse_int_param, parse_float_param


@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def generate_ai_training_plan(req: https_fn.CallableRequest):
    """
    AI 生成训练计划主入口

    请求参数:
        - prompt: str, 用户输入的提示词
        - type: str, 生成类型 ('full_plan', 'next_day', 'exercises', 'sets', 'optimize')
        - context: dict, 可选，上下文信息（已有的计划内容）
        - studentId: str, 可选，学生ID（用于个性化）

    返回:
        {
            'status': 'success' | 'error',
            'data': {...}  // 生成的数据
            'error': str  // 错误信息（如果有）
        }

    注意:
        使用 Firebase Functions Secrets 管理 ANTHROPIC_API_KEY
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "用户未登录")

        user_id = req.auth.uid
        logger.info(f"🤖 AI生成请求 - 用户: {user_id}")

        # 获取参数
        prompt = req.data.get("prompt", "")
        generation_type = req.data.get("type", "full_plan")
        context = req.data.get("context", {})
        student_id = req.data.get("studentId")
        params = req.data.get("params")  # 新增：结构化参数

        if not prompt and not params and generation_type != "optimize":
            raise https_fn.HttpsError(
                "invalid-argument", "prompt 或 params 不能同时为空"
            )

        logger.info(f"生成类型: {generation_type}")
        if prompt:
            logger.debug(f"Prompt: {prompt[:100]}...")
        if params:
            logger.debug(f"Params: {params}")

        # 根据类型分发到不同的处理函数
        if generation_type == "full_plan":
            result = _generate_full_plan(prompt, user_id, params)
        elif generation_type == "next_day":
            result = _suggest_next_day(prompt, context, user_id)
        elif generation_type == "exercises":
            result = _suggest_exercises(prompt, context, user_id)
        elif generation_type == "sets":
            result = _suggest_sets(prompt, context, user_id)
        elif generation_type == "optimize":
            result = _optimize_plan(context, user_id)
        else:
            raise https_fn.HttpsError(
                "invalid-argument", f"不支持的生成类型: {generation_type}"
            )

        return result

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ AI生成失败: {str(e)}", exc_info=True)
        raise https_fn.HttpsError("internal", f"服务器错误: {str(e)}")


def _generate_full_plan(
    prompt: str, user_id: str, params: Optional[dict] = None
) -> Dict[str, Any]:
    """
    生成完整训练计划

    Args:
        prompt: 用户输入的需求描述（可选，如果有 params）
        user_id: 用户ID
        params: 结构化参数（可选，优先使用）

    Returns:
        包含完整计划的响应
    """
    try:
        logger.info("📝 生成完整训练计划")

        # 提取语言参数
        language = params.get("language", "中文") if params else "中文"
        logger.info(f"🌐 语言设置: {language}")

        # 构建 Prompt（优先使用结构化参数）
        if params:
            logger.info("使用结构化参数生成")
            system_prompt, user_prompt = build_structured_plan_prompt(params)
        else:
            logger.info("使用文本 prompt 生成")
            system_prompt, user_prompt = build_full_plan_prompt(prompt, language)

        # 调用 Claude API
        claude_client = get_claude_client()
        response = claude_client.call_claude(
            system_prompt=system_prompt, user_prompt=user_prompt, response_format="json"
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            logger.error(f"❌ Claude API 调用失败: {error_msg}")
            return {"status": "error", "error": error_msg}

        # 解析生成的计划
        plan_data = response.get("data", {})

        # 验证数据结构
        if not validate_plan_structure(plan_data):
            logger.warning("⚠️ 计划结构验证失败，尝试修复")
            plan_data = fix_plan_structure(plan_data)

        logger.info(f'✅ 完整计划生成成功 - {len(plan_data.get("days", []))} 个训练日')

        return {"status": "success", "data": {"plan": plan_data}}

    except Exception as e:
        logger.error(f"❌ 完整计划生成失败: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"生成失败: {str(e)}"}


def _suggest_next_day(
    prompt: str, context: Dict[str, Any], user_id: str
) -> Dict[str, Any]:
    """
    推荐下一个训练日

    Args:
        prompt: 用户目标/需求
        context: 上下文（包含已有的训练日）
        user_id: 用户ID

    Returns:
        包含推荐训练日的响应
    """
    try:
        logger.info("📅 推荐下一个训练日")

        # 提取语言参数
        language = context.get("language", "中文")
        logger.info(f"🌐 语言设置: {language}")

        existing_days = context.get("days", [])

        # 构建 Prompt
        system_prompt, user_prompt = build_next_day_prompt(
            existing_days, prompt, language
        )

        # 调用 Claude API
        claude_client = get_claude_client()
        response = claude_client.call_claude(
            system_prompt=system_prompt, user_prompt=user_prompt, response_format="json"
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            return {"status": "error", "error": error_msg}

        day_data = response.get("data", {})

        logger.info(f'✅ 训练日推荐成功 - Day {day_data.get("day", "?")}')

        return {"status": "success", "data": {"days": [day_data]}}

    except Exception as e:
        logger.error(f"❌ 训练日推荐失败: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"推荐失败: {str(e)}"}


def _suggest_exercises(
    prompt: str, context: Dict[str, Any], user_id: str
) -> Dict[str, Any]:
    """
    推荐动作

    Args:
        prompt: 训练日类型
        context: 上下文（包含已有的动作）
        user_id: 用户ID

    Returns:
        包含推荐动作的响应
    """
    try:
        logger.info("💪 推荐动作")

        # 提取语言参数
        language = context.get("language", "中文")
        logger.info(f"🌐 语言设置: {language}")

        day_type = prompt
        existing_exercises = context.get("exercises", [])

        # 构建 Prompt
        system_prompt, user_prompt = build_exercises_prompt(
            day_type, existing_exercises, language
        )

        # 调用 Claude API
        claude_client = get_claude_client()
        response = claude_client.call_claude(
            system_prompt=system_prompt, user_prompt=user_prompt, response_format="json"
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            return {"status": "error", "error": error_msg}

        data = response.get("data", {})
        exercises = data.get("exercises", [])

        logger.info(f"✅ 动作推荐成功 - {len(exercises)} 个动作")

        return {"status": "success", "data": {"exercises": exercises}}

    except Exception as e:
        logger.error(f"❌ 动作推荐失败: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"推荐失败: {str(e)}"}


def _suggest_sets(prompt: str, context: Dict[str, Any], user_id: str) -> Dict[str, Any]:
    """
    推荐 Sets 配置

    Args:
        prompt: 动作名称
        context: 上下文（用户水平等）
        user_id: 用户ID

    Returns:
        包含推荐 Sets 的响应
    """
    try:
        logger.info("🎯 推荐 Sets 配置")

        # 提取语言参数
        language = context.get("language", "中文")
        logger.info(f"🌐 语言设置: {language}")

        exercise_name = prompt
        user_level = context.get("userLevel", "中级")

        # 构建 Prompt
        system_prompt, user_prompt = build_sets_prompt(
            exercise_name, user_level, language
        )

        # 调用 Claude API
        claude_client = get_claude_client()
        response = claude_client.call_claude(
            system_prompt=system_prompt, user_prompt=user_prompt, response_format="json"
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            return {"status": "error", "error": error_msg}

        data = response.get("data", {})
        sets = data.get("sets", [])
        note = data.get("note", "")

        logger.info(f"✅ Sets 推荐成功 - {len(sets)} 组")

        return {"status": "success", "data": {"sets": sets, "note": note}}

    except Exception as e:
        logger.error(f"❌ Sets 推荐失败: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"推荐失败: {str(e)}"}


def _optimize_plan(context: Dict[str, Any], user_id: str) -> Dict[str, Any]:
    """
    优化训练计划

    Args:
        context: 当前计划数据
        user_id: 用户ID

    Returns:
        包含优化建议的响应
    """
    try:
        logger.info("🔧 优化训练计划")

        # 提取语言参数
        language = context.get("language", "中文")
        logger.info(f"🌐 语言设置: {language}")

        current_plan = context.get("plan", {})

        if not current_plan:
            return {"status": "error", "error": "未提供计划数据"}

        # 构建 Prompt
        system_prompt, user_prompt = build_optimize_prompt(current_plan, language)

        # 调用 Claude API
        claude_client = get_claude_client()
        response = claude_client.call_claude(
            system_prompt=system_prompt, user_prompt=user_prompt, response_format="json"
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            return {"status": "error", "error": error_msg}

        data = response.get("data", {})
        suggestions = data.get("suggestions", [])
        optimized_plan = data.get("optimized_plan")

        logger.info(f"✅ 计划优化成功 - {len(suggestions)} 条建议")

        return {
            "status": "success",
            "data": {"suggestions": suggestions, "optimizedPlan": optimized_plan},
        }

    except Exception as e:
        logger.error(f"❌ 计划优化失败: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"优化失败: {str(e)}"}


# ==================== 流式生成训练计划 ====================


@https_fn.on_request(
    timeout_sec=540,
    secrets=["ANTHROPIC_API_KEY"],
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post", "options"]),
)
def edit_plan_conversation(req: https_fn.Request) -> Response:
    """
    对话式编辑训练计划（SSE）

    通过 Server-Sent Events 实时推送修改建议和思考过程

    请求参数（JSON Body）:
        - user_id: str, 用户ID（用于获取 memory）
        - plan_id: str, 计划ID
        - user_message: str, 用户的修改请求
        - current_plan: dict, 当前完整计划数据

    返回:
        SSE 流式响应，事件格式：
        data: {"type": "thinking", "content": "..."}
        data: {"type": "analysis", "content": "..."}
        data: {"type": "suggestion", "data": {...}}
        data: {"type": "complete", "message": "..."}
        data: {"type": "error", "error": "..."}
    """
    try:
        logger.info("🔄 收到编辑对话请求")

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

        # 导入流式编辑模块
        from ..streaming import stream_edit_plan_conversation

        def generate():
            """SSE 生成器"""
            try:
                # 调用流式编辑
                for event in stream_edit_plan_conversation(
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
                "X-Accel-Buffering": "no",  # 禁用 Nginx 缓冲
                "Connection": "keep-alive",
            },
        )

    except Exception as e:
        logger.error(f"❌ 编辑对话处理失败: {str(e)}", exc_info=True)
        error_event = json.dumps(
            {"type": "error", "error": f"服务器错误: {str(e)}"}, ensure_ascii=False
        )
        return Response(f"data: {error_event}\n\n", mimetype="text/event-stream")


@https_fn.on_request(
    timeout_sec=540,
    secrets=["ANTHROPIC_API_KEY"],
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post", "options"]),
)
def stream_training_plan(req: https_fn.Request) -> Response:
    """
    流式生成训练计划（SSE）

    通过 Server-Sent Events 实时推送生成进度
    每生成一天就立即返回，用户可以看到实时进度

    请求参数（JSON Body）:
        - goal: str, 训练目标
        - level: str, 训练水平
        - muscle_groups: list, 目标肌群
        - days_per_week: int, 每周训练天数
        - duration_minutes: int, 每次训练时长
        - workload: str, 训练量
        - exercises_per_day_min: int
        - exercises_per_day_max: int
        - sets_per_exercise_min: int
        - sets_per_exercise_max: int
        - training_styles: list
        - equipment: list
        - notes: str (可选)

    返回:
        SSE 流式响应，事件格式：
        data: {"type": "thinking", "content": "..."}
        data: {"type": "day_complete", "day": 1, "data": {...}}
        data: {"type": "complete", "message": "..."}
        data: {"type": "error", "error": "..."}
    """
    try:
        logger.info("🔄 收到流式生成请求")

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

        logger.info(
            f'参数: goal={params.get("goal")}, days={params.get("days_per_week")}'
        )

        # 导入流式生成模块
        from ..streaming import stream_generate_training_plan

        def generate():
            """SSE 生成器"""
            try:
                # 调用流式生成
                for event in stream_generate_training_plan(params):
                    # 格式化为 SSE 格式
                    event_data = json.dumps(event, ensure_ascii=False)
                    yield f"data: {event_data}\n\n"

                    # 如果是错误或完成，结束流
                    if event.get("type") in ["error", "complete"]:
                        break

            except Exception as e:
                logger.error(f"❌ 流式生成异常: {str(e)}", exc_info=True)
                error_event = json.dumps(
                    {"type": "error", "error": f"生成失败: {str(e)}"},
                    ensure_ascii=False,
                )
                yield f"data: {error_event}\n\n"

        # 返回 SSE 响应
        return Response(
            generate(),
            mimetype="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",  # 禁用 Nginx 缓冲
                "Connection": "keep-alive",
            },
        )

    except Exception as e:
        logger.error(f"❌ 流式生成处理失败: {str(e)}", exc_info=True)
        error_event = json.dumps(
            {"type": "error", "error": f"服务器错误: {str(e)}"}, ensure_ascii=False
        )
        return Response(f"data: {error_event}\n\n", mimetype="text/event-stream")
