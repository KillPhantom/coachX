"""
Claude Skills 调用辅助函数

支持调用 nutrition-calculator skill 生成饮食计划
"""

import os
import json
from typing import Dict, Any, Optional

from ..claude_client import get_claude_client
from .skill_manager import get_or_create_nutrition_skill
from utils.logger import logger


def call_nutrition_calculator_skill(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    调用 nutrition-calculator skill 生成饮食计划

    Args:
        params: Skill 输入参数
            - weight_kg: float
            - height_cm: float
            - age: int
            - gender: str ("male" | "female")
            - activity_level: str
            - goal: str ("muscle_gain" | "fat_loss" | "maintenance")
            - body_fat_percentage: float (可选)
            - training_plan: dict (可选)
            - dietary_preferences: list (可选)
            - meal_count: int (可选)
            - allergies: list (可选)
            - plan_duration_days: int (可选)

    Returns:
        {
            "success": bool,
            "data": {
                "bmr_kcal": float,
                "tdee_kcal": float,
                "target_calories_kcal": float,
                "diet_plan_recommendation": {...}
            },
            "error": str (if failed)
        }
    """
    try:
        logger.info("🔧 调用 nutrition-calculator skill")
        logger.debug(f"输入参数: {json.dumps(params, ensure_ascii=False)}")

        # 获取或创建 skill（自动管理）
        skill_id = get_or_create_nutrition_skill()
        logger.info(f"✅ Skill ID: {skill_id}")

        # 提取关键参数用于 prompt
        plan_days = params.get("plan_duration_days", 1)

        # 构建用户请求
        user_prompt = f"""Execute the nutrition-calculator skill with the following parameters.

Parameters:
{json.dumps(params, ensure_ascii=False, indent=2)}

CRITICAL REQUIREMENTS:
1. Use EXACTLY {plan_days} day(s) for the diet plan (plan_duration_days={plan_days})
2. Return ONLY the raw JSON output from the skill
3. Do NOT add any explanation, summary, or commentary
4. Do NOT wrap the result in markdown code blocks
5. The response must be valid JSON that can be parsed directly

Generate a {plan_days}-day diet plan as specified in the parameters."""

        # 调用 Claude API with Skill
        claude_client = get_claude_client()
        response = claude_client.call_claude_with_skill(
            user_prompt=user_prompt,
            skill_id=skill_id
        )

        if not response.get("success"):
            error_msg = response.get("error", "Claude API 调用失败")
            logger.error(f"❌ {error_msg}")

            # 记录原始响应以便调试
            raw_text = response.get("raw_text", "")
            if raw_text:
                logger.error("原始响应文本（前 1000 字符）:")
                logger.error(raw_text[:1000])

            return {"success": False, "error": error_msg}

        # 解析返回数据
        result_data = response.get("data", {})

        logger.info(f"✅ 获取到数据，包含以下键: {list(result_data.keys())}")

        # 验证必需字段
        if "diet_plan_recommendation" not in result_data:
            logger.error("❌ 返回数据缺少 diet_plan_recommendation 字段")
            logger.error(f"当前数据键: {list(result_data.keys())}")
            logger.error(f"完整数据: {json.dumps(result_data, ensure_ascii=False, indent=2)[:1000]}")
            return {
                "success": False,
                "error": "Skill 返回数据格式错误"
            }

        logger.info("✅ Skill 调用成功")
        logger.info(f"📊 BMR: {result_data.get('bmr_kcal')} kcal")
        logger.info(f"📊 TDEE: {result_data.get('tdee_kcal')} kcal")
        logger.info(f"📊 目标热量: {result_data.get('target_calories_kcal')} kcal")

        return {
            "success": True,
            "data": result_data
        }

    except Exception as e:
        logger.error(f"❌ Skill 调用异常: {str(e)}", exc_info=True)
        return {
            "success": False,
            "error": f"Skill 调用失败: {str(e)}"
        }


def _build_user_request(params: Dict[str, Any]) -> str:
    """
    构建用户请求文本

    Args:
        params: 输入参数

    Returns:
        格式化的用户请求
    """
    # 提取必需参数
    weight = params.get("weight_kg")
    height = params.get("height_cm")
    age = params.get("age")
    gender = params.get("gender")
    activity_level = params.get("activity_level")
    goal = params.get("goal")

    # 构建基础请求
    request_parts = [
        f"请帮我制定一个饮食计划：",
        f"- 体重：{weight}kg",
        f"- 身高：{height}cm",
        f"- 年龄：{age}岁",
        f"- 性别：{gender}",
        f"- 活动水平：{activity_level}",
        f"- 目标：{goal}",
    ]

    # 添加可选参数
    if params.get("body_fat_percentage"):
        request_parts.append(f"- 体脂率：{params['body_fat_percentage']}%")

    if params.get("meal_count"):
        request_parts.append(f"- 每日餐数：{params['meal_count']}餐")

    if params.get("plan_duration_days"):
        request_parts.append(f"- 计划天数：{params['plan_duration_days']}天")

    if params.get("dietary_preferences"):
        prefs = ", ".join(params["dietary_preferences"])
        request_parts.append(f"- 饮食偏好：{prefs}")

    if params.get("allergies"):
        allergies = ", ".join(params["allergies"])
        request_parts.append(f"- 过敏信息：{allergies}")

    if params.get("training_plan"):
        request_parts.append(f"- 训练计划：已提供（采用碳循环策略）")

    return "\n".join(request_parts)
