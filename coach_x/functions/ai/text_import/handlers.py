"""
文本导入 Cloud Functions 处理器

处理从文本导入训练计划的请求
"""

from firebase_functions import https_fn
from typing import Dict, Any
import json

from ..claude_client import get_claude_client
from .prompts import build_text_import_prompt
from ..training_plan.utils import validate_plan_structure, fix_plan_structure
from utils.logger import logger


@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def import_plan_from_text(req: https_fn.CallableRequest):
    """
    从文本导入训练计划

    请求参数:
        - text_content: str, 训练计划文本内容

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
        logger.info(f"📝 文本导入请求 - 用户: {user_id}")

        # 获取参数
        text_content = req.data.get("text_content", "")
        language = req.data.get("language", "中文")

        if not text_content or not text_content.strip():
            raise https_fn.HttpsError("invalid-argument", "text_content 不能为空")

        logger.info(f"文本长度: {len(text_content)} 字符")
        logger.info(f"🌐 语言设置: {language}")
        logger.debug(f"文本内容（前200字）: {text_content[:200]}...")

        # 调用文本解析处理
        result = _import_from_text(text_content, user_id, language)

        return result

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ 文本导入失败: {str(e)}", exc_info=True)
        raise https_fn.HttpsError("internal", f"服务器错误: {str(e)}")


def _import_from_text(
    text_content: str, user_id: str, language: str = "中文"
) -> Dict[str, Any]:
    """
    从文本解析训练计划

    Args:
        text_content: 训练计划文本
        user_id: 用户 ID
        language: 输出语言

    Returns:
        解析结果
    """
    try:
        logger.info("🔍 开始解析文本内容")
        logger.info(f"🌐 语言设置: {language}")

        # 构建 Text Import Prompt
        prompts = build_text_import_prompt(text_content)
        system_prompt = prompts['system']
        user_prompt = prompts['user']

        logger.debug(f"System Prompt 长度: {len(system_prompt)} 字符")
        logger.debug(f"User Prompt 长度: {len(user_prompt)} 字符")

        # 调用 Claude API
        claude_client = get_claude_client()
        response = claude_client.call_claude(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            response_format="json",
        )

        if not response.get("success"):
            error_msg = response.get("error", "未知错误")
            logger.error(f"❌ Claude API 调用失败: {error_msg}")
            return {"status": "error", "error": f"文本解析失败: {error_msg}"}

        # 解析识别结果
        parsed_data = response.get("data", {})

        logger.info(f"✅ 文本解析成功")
        logger.debug(
            f"解析数据: {json.dumps(parsed_data, ensure_ascii=False, indent=2)}"
        )

        # 提取 days 数据（AI 返回的是包含 days 的对象）
        if "days" in parsed_data:
            plan_data = {
                "name": parsed_data.get("name", "训练计划"),
                "description": parsed_data.get("description", ""),
                "days": parsed_data["days"]
            }
        else:
            # 如果 AI 直接返回了 days 数组
            plan_data = {
                "name": "训练计划",
                "description": "",
                "days": parsed_data if isinstance(parsed_data, list) else []
            }

        # 验证和修复计划结构
        if not validate_plan_structure(plan_data):
            logger.warning("⚠️ 解析的计划结构不完整，尝试修复")
            plan_data = fix_plan_structure(plan_data)

        # 设置置信度（文本解析通常比 OCR 更准确）
        confidence = 0.95
        warnings = []

        # 检查是否有空数据的警告
        if not plan_data.get("days"):
            warnings.append("未能识别任何训练日")
            confidence = 0.5
        elif any(not day.get("exercises") for day in plan_data["days"]):
            warnings.append("部分训练日缺少动作")
            confidence = 0.8

        # 构建返回结果
        result = {
            "status": "success",
            "data": {
                "plan": plan_data,
                "confidence": confidence,
                "warnings": warnings,
            },
        }

        logger.info(f"✅ 文本导入处理完成 - 置信度: {confidence:.2%}")
        logger.info(f"解析到 {len(plan_data['days'])} 个训练日")
        if warnings:
            logger.info(f'⚠️ 警告信息: {", ".join(warnings)}')
        logger.info(f"result: {result}")
        return result

    except Exception as e:
        logger.error(f"❌ 文本解析异常: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"文本解析失败: {str(e)}"}
