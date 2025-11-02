"""
食物营养 Cloud Functions 处理器

处理食物营养信息获取请求
"""

from firebase_functions import https_fn
from typing import Dict, Any

from ..claude_client import get_claude_client
from utils.logger import logger


@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def get_food_macros(req: https_fn.CallableRequest):
    """
    AI 获取食物营养信息

    请求参数:
        - food_name: str, 食物名称

    返回:
        {
            'status': 'success' | 'error',
            'data': {
                'protein': float,  // 蛋白质（克/100g）
                'carbs': float,    // 碳水化合物（克/100g）
                'fat': float,      // 脂肪（克/100g）
                'calories': float  // 卡路里（千卡/100g）
            },
            'message': str
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "用户未登录")

        user_id = req.auth.uid
        food_name = req.data.get("food_name", "").strip()

        if not food_name:
            raise https_fn.HttpsError("invalid-argument", "food_name 不能为空")

        logger.info(f"🥗 AI获取食物营养信息 - 用户: {user_id}, 食物: {food_name}")

        # 获取 Claude 客户端
        client = get_claude_client()

        # 构建 system prompt
        system_prompt = """你是一位专业的营养学专家，精通各种食物的营养成分。
你的任务是提供准确的食物营养信息。

要求：
1. 提供每100克食物的营养成分
2. 数值应该是准确的平均值
3. 如果食物名称不明确，请选择最常见的类型
4. 返回纯 JSON 格式，不要包含任何其他文字
5. JSON 格式必须严格遵循：{"protein": float, "carbs": float, "fat": float, "calories": float}"""

        # 构建 user prompt
        user_prompt = f"""请提供 "{food_name}" 每100克的营养成分。

要求：
- protein: 蛋白质含量（克）
- carbs: 碳水化合物含量（克）
- fat: 脂肪含量（克）
- calories: 卡路里（千卡）

请直接返回 JSON 格式的数据，不要包含任何解释或说明。

示例格式：
{{"protein": 31.0, "carbs": 0.0, "fat": 3.6, "calories": 165.0}}"""

        # 调用 Claude API
        response = client.call_claude(
            system_prompt=system_prompt, user_prompt=user_prompt, response_format="json"
        )

        # 检查响应是否成功
        if not response.get("success", False):
            error_msg = response.get("error", "未知错误")
            logger.error(f"❌ Claude API 调用失败: {error_msg}")
            # 返回默认值
            return {
                "status": "success",
                "data": {"protein": 0.0, "carbs": 0.0, "fat": 0.0, "calories": 0.0},
                "message": f"无法自动获取 {food_name} 的营养信息，请手动输入",
            }

        # 获取解析后的数据
        macros_data = response.get("data", {})
        logger.debug(f"Claude 响应: {macros_data}")

        # 验证数据格式
        try:
            required_keys = ["protein", "carbs", "fat", "calories"]
            for key in required_keys:
                if key not in macros_data:
                    raise ValueError(f"缺少必需字段: {key}")

            # 转换为 float 并验证
            result = {
                "protein": float(macros_data["protein"]),
                "carbs": float(macros_data["carbs"]),
                "fat": float(macros_data["fat"]),
                "calories": float(macros_data["calories"]),
            }

            logger.info(f"✅ 成功获取营养信息 - {food_name}: {result}")

            return {
                "status": "success",
                "data": result,
                "message": f"成功获取 {food_name} 的营养信息",
            }

        except (ValueError, KeyError, TypeError) as e:
            logger.error(f"❌ 数据验证失败: {str(e)}, 原始数据: {macros_data}")
            # 返回默认值，避免完全失败
            return {
                "status": "success",
                "data": {"protein": 0.0, "carbs": 0.0, "fat": 0.0, "calories": 0.0},
                "message": f"无法自动获取 {food_name} 的营养信息，请手动输入",
            }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ 获取食物营养信息失败: {str(e)}", exc_info=True)
        # 返回默认值而不是抛出错误，提升用户体验
        return {
            "status": "error",
            "data": {"protein": 0.0, "carbs": 0.0, "fat": 0.0, "calories": 0.0},
            "message": f"获取失败: {str(e)}，请手动输入营养信息",
        }
