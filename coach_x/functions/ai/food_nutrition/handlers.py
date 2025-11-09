"""
食物营养分析 Cloud Functions 处理器

使用 Claude Vision API 识别食物图片并估算营养成分
"""

from firebase_functions import https_fn
from typing import Dict, Any
import json

from ..claude_client import get_claude_client
from .prompts import build_food_nutrition_prompt
from utils.logger import logger


@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def analyze_food_nutrition(req: https_fn.CallableRequest):
    """
    分析食物图片并返回营养成分估算

    请求参数:
        - image_url: str, 图片的 Firebase Storage URL（公开可访问）
        - language: str, 输出语言（默认"中文"，可选"English"）

    返回:
        {
            'status': 'success' | 'error',
            'data': {
                'foods': [
                    {
                        'name': '食物名称',
                        'estimated_weight': '150g',
                        'macros': {
                            'protein': 4.0,
                            'carbs': 45.0,
                            'fat': 0.5,
                            'calories': 200
                        }
                    },
                    ...
                ]
            },
            'error': str  // 错误信息（如果有）
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "用户未登录")

        user_id = req.auth.uid
        logger.info(f"🍽️ 食物营养分析请求 - 用户: {user_id}")

        # 获取参数
        image_url = req.data.get("image_url", "")
        language = req.data.get("language", "中文")

        if not image_url:
            raise https_fn.HttpsError("invalid-argument", "image_url 不能为空")

        logger.info(f"图片 URL: {image_url}")
        logger.info(f"🌐 语言设置: {language}")

        # 调用分析处理
        result = _analyze_food_image(image_url, user_id, language)

        return result

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ 食物营养分析失败: {str(e)}", exc_info=True)
        raise https_fn.HttpsError("internal", f"服务器错误: {str(e)}")


def _analyze_food_image(
    image_url: str,
    user_id: str,
    language: str = "中文"
) -> Dict[str, Any]:
    """
    分析食物图片的内部实现

    Args:
        image_url: 图片 URL
        user_id: 用户 ID
        language: 输出语言

    Returns:
        分析结果
    """
    try:
        logger.info("🔍 开始分析食物图片")
        logger.info(f"🌐 语言设置: {language}")

        # 构建 AI Prompt
        system_prompt, user_prompt = build_food_nutrition_prompt(language)

        # 调用 Claude Vision API
        claude_client = get_claude_client()
        response = claude_client.call_claude_vision(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            image_url=image_url,
            response_format="json",
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            logger.error(f"❌ Claude Vision API 调用失败: {error_msg}")
            return {
                "status": "error",
                "error": f"图片分析失败: {error_msg}"
            }

        # 解析分析结果
        analysis_data = response.get("data", {})

        logger.info(f"✅ 食物图片分析成功")
        logger.debug(
            f"分析数据: {json.dumps(analysis_data, ensure_ascii=False, indent=2)}"
        )

        # 验证返回数据结构
        if "foods" not in analysis_data:
            logger.warning("⚠️ AI 返回数据缺少 'foods' 字段，尝试修复")
            analysis_data = {"foods": []}

        foods = analysis_data.get("foods", [])
        logger.info(f"✅ 识别到 {len(foods)} 种食物")

        # 验证每个食物项的数据完整性
        validated_foods = []
        for idx, food in enumerate(foods):
            try:
                # 验证必需字段
                if not all(key in food for key in ["name", "estimated_weight", "macros"]):
                    logger.warning(f"⚠️ 食物项 {idx} 数据不完整，跳过")
                    continue

                macros = food.get("macros", {})
                if not all(key in macros for key in ["protein", "carbs", "fat", "calories"]):
                    logger.warning(f"⚠️ 食物项 {idx} 营养数据不完整，跳过")
                    continue

                # 确保数值类型正确
                validated_food = {
                    "name": str(food["name"]),
                    "estimated_weight": str(food["estimated_weight"]),
                    "macros": {
                        "protein": float(macros["protein"]),
                        "carbs": float(macros["carbs"]),
                        "fat": float(macros["fat"]),
                        "calories": int(macros["calories"]),
                    }
                }
                validated_foods.append(validated_food)

                logger.info(
                    f"  - {validated_food['name']} ({validated_food['estimated_weight']}): "
                    f"{validated_food['macros']['calories']} kcal"
                )

            except (ValueError, TypeError, KeyError) as e:
                logger.warning(f"⚠️ 食物项 {idx} 数据验证失败: {e}")
                continue

        # 构建返回结果
        result = {
            "status": "success",
            "data": {
                "foods": validated_foods
            }
        }

        logger.info(f"✅ 食物营养分析完成 - 有效食物: {len(validated_foods)} 种")

        return result

    except Exception as e:
        logger.error(f"❌ 食物图片分析异常: {str(e)}", exc_info=True)
        return {
            "status": "error",
            "error": f"图片分析失败: {str(e)}"
        }
