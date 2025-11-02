"""
图片导入 Cloud Functions 处理器

处理从图片导入训练计划的请求
"""

from firebase_functions import https_fn
from typing import Dict, Any
import json

from ..claude_client import get_claude_client
from .prompts import build_vision_import_prompt
from ..training_plan.utils import validate_plan_structure, fix_plan_structure
from utils.logger import logger


@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def import_plan_from_image(req: https_fn.CallableRequest):
    """
    从图片导入训练计划

    请求参数:
        - image_url: str, 图片的 Firebase Storage URL（公开可访问）

    返回:
        {
            'status': 'success' | 'error',
            'data': {
                'plan': {...},
                'confidence': 0.95,
                'warnings': [...]
            }
            'error': str  // 错误信息（如果有）
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError("unauthenticated", "用户未登录")

        user_id = req.auth.uid
        logger.info(f"📷 图片导入请求 - 用户: {user_id}")

        # 获取参数
        image_url = req.data.get("image_url", "")
        language = req.data.get("language", "中文")

        if not image_url:
            raise https_fn.HttpsError("invalid-argument", "image_url 不能为空")

        logger.info(f"图片 URL: {image_url}")
        logger.info(f"🌐 语言设置: {language}")

        # 调用识别处理
        result = _import_from_image(image_url, user_id, language)

        return result

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ 图片导入失败: {str(e)}", exc_info=True)
        raise https_fn.HttpsError("internal", f"服务器错误: {str(e)}")


def _import_from_image(
    image_url: str, user_id: str, language: str = "中文"
) -> Dict[str, Any]:
    """
    从图片识别训练计划

    Args:
        image_url: 图片 URL
        user_id: 用户 ID
        language: 输出语言

    Returns:
        识别结果
    """
    try:
        logger.info("🔍 开始识别图片内容")
        logger.info(f"🌐 语言设置: {language}")

        # 构建 Vision Prompt
        system_prompt, user_prompt = build_vision_import_prompt(language)

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
            return {"status": "error", "error": f"图片识别失败: {error_msg}"}

        # 解析识别结果
        recognized_data = response.get("data", {})

        logger.info(f"✅ 图片识别成功")
        logger.debug(
            f"识别数据: {json.dumps(recognized_data, ensure_ascii=False, indent=2)}"
        )

        # 提取置信度和警告
        confidence = recognized_data.get("confidence", 0.8)
        warnings = recognized_data.get("warnings", [])

        # 验证和修复计划结构
        if not validate_plan_structure(recognized_data):
            logger.warning("⚠️ 识别的计划结构不完整，尝试修复")
            recognized_data = fix_plan_structure(recognized_data)

        # 构建返回结果
        result = {
            "status": "success",
            "data": {
                "plan": recognized_data,
                "confidence": confidence,
                "warnings": warnings,
            },
        }

        logger.info(f"✅ 图片导入处理完成 - 置信度: {confidence:.2%}")
        if warnings:
            logger.info(f'⚠️ 警告信息: {", ".join(warnings)}')

        return result

    except Exception as e:
        logger.error(f"❌ 图片识别异常: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"图片识别失败: {str(e)}"}
