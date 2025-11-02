"""
补剂计划图片导入 Cloud Functions 处理器

处理从图片导入补剂计划的请求
"""

from firebase_functions import https_fn
from typing import Dict, Any
import json

from ..claude_client import get_claude_client
from .supplement_prompts import build_supplement_vision_import_prompt
from utils.logger import logger


@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def import_supplement_plan_from_image(req: https_fn.CallableRequest):
    """
    从图片导入补剂计划

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
        logger.info(f"📷 补剂计划图片导入请求 - 用户: {user_id}")

        # 获取参数
        image_url = req.data.get("image_url", "")
        language = req.data.get("language", "中文")

        if not image_url:
            raise https_fn.HttpsError("invalid-argument", "image_url 不能为空")

        logger.info(f"图片 URL: {image_url}")
        logger.info(f"🌐 语言设置: {language}")

        # 调用识别处理
        result = _import_supplement_from_image(image_url, user_id, language)

        return result

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f"❌ 补剂计划图片导入失败: {str(e)}", exc_info=True)
        raise https_fn.HttpsError("internal", f"服务器错误: {str(e)}")


def _import_supplement_from_image(
    image_url: str, user_id: str, language: str = "中文"
) -> Dict[str, Any]:
    """
    从图片识别补剂计划

    Args:
        image_url: 图片 URL
        user_id: 用户 ID
        language: 输出语言

    Returns:
        识别结果
    """
    try:
        logger.info("🔍 开始识别补剂计划图片内容")
        logger.info(f"🌐 语言设置: {language}")

        # 构建 Vision Prompt
        system_prompt, user_prompt = build_supplement_vision_import_prompt(language)

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
        try:
            # Claude Vision API 返回的数据结构:
            # {'success': True, 'data': parsed_json, 'raw_text': content}
            # 如果已经解析成功，直接使用 data；否则使用 raw_text 重新解析
            if "data" in response and response["data"]:
                plan_data = response["data"]
                logger.info(f"✅ 直接使用已解析的 JSON 数据")
            elif "raw_text" in response:
                content_text = response.get("raw_text", "")
                if not content_text:
                    raise ValueError("API 返回内容为空")

                logger.info(f"📝 原始识别结果长度: {len(content_text)} 字符")
                logger.info(f"原始内容前200字符: {content_text[:200]}")

                # 解析 JSON
                try:
                    plan_data = json.loads(content_text)
                except json.JSONDecodeError as e:
                    logger.error(f"❌ JSON 解析失败: {str(e)}")
                    logger.error(f"原始内容: {content_text[:500]}")
                    # 尝试提取 JSON（可能包含在其他文本中）
                    import re

                    json_match = re.search(r"\{.*\}", content_text, re.DOTALL)
                    if json_match:
                        plan_data = json.loads(json_match.group())
                    else:
                        raise
            else:
                raise ValueError("响应中缺少必要的数据字段")

            logger.info(f"✅ JSON 解析成功")

            # 验证和修复计划结构
            plan_data = _validate_and_fix_supplement_plan(plan_data)

            # 提取置信度和警告
            confidence = plan_data.pop("confidence", 0.8)
            warnings = plan_data.pop("warnings", [])

            logger.info(f"✅ 补剂计划识别成功")
            logger.info(f"📊 置信度: {confidence}")
            logger.info(f"天数: {len(plan_data.get('days', []))}")
            logger.info(f"⚠️ 警告数量: {len(warnings)}")

            return {
                "status": "success",
                "data": {
                    "plan": plan_data,
                    "confidence": confidence,
                    "warnings": warnings,
                },
            }

        except Exception as e:
            logger.error(f"❌ 解析识别结果失败: {str(e)}", exc_info=True)
            return {"status": "error", "error": f"解析识别结果失败: {str(e)}"}

    except Exception as e:
        logger.error(f"❌ 识别处理失败: {str(e)}", exc_info=True)
        return {"status": "error", "error": f"识别处理失败: {str(e)}"}


def _validate_and_fix_supplement_plan(plan_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    验证并修复补剂计划结构

    Args:
        plan_data: 原始计划数据

    Returns:
        修复后的计划数据
    """
    # 确保必要字段存在
    if "name" not in plan_data or not plan_data["name"]:
        plan_data["name"] = "导入的补剂计划"

    if "description" not in plan_data:
        plan_data["description"] = ""

    if "days" not in plan_data or not isinstance(plan_data["days"], list):
        plan_data["days"] = []

    # 验证并修复每个补剂日
    for i, day in enumerate(plan_data["days"]):
        if not isinstance(day, dict):
            continue

        # 确保 day 编号正确
        if "day" not in day:
            day["day"] = i + 1

        # 确保 name 字段存在
        if "name" not in day or not day["name"]:
            day["name"] = f"Day {day['day']}"

        # 确保 timings 字段存在
        if "timings" not in day or not isinstance(day["timings"], list):
            day["timings"] = []

        # 验证并修复每个时间段
        for timing in day["timings"]:
            if not isinstance(timing, dict):
                continue

            # 确保 name 字段存在
            if "name" not in timing or not timing["name"]:
                timing["name"] = "未知时间段"

            # 确保 note 字段存在
            if "note" not in timing:
                timing["note"] = ""

            # 确保 supplements 字段存在
            if "supplements" not in timing or not isinstance(
                timing["supplements"], list
            ):
                timing["supplements"] = []

            # 验证并修复每个补剂
            for supplement in timing["supplements"]:
                if not isinstance(supplement, dict):
                    continue

                # 确保 name 字段存在
                if "name" not in supplement or not supplement["name"]:
                    supplement["name"] = "未知补剂"

                # 确保 amount 字段存在
                if "amount" not in supplement or not supplement["amount"]:
                    supplement["amount"] = "适量"

                # 确保 note 字段存在
                if "note" not in supplement:
                    supplement["note"] = ""

    # 添加必要的字段（用于 SupplementPlanModel）
    plan_data["id"] = ""  # 服务端填充
    plan_data["ownerId"] = ""  # 服务端填充
    plan_data["studentIds"] = []
    plan_data["createdAt"] = 0  # 服务端填充
    plan_data["updatedAt"] = 0  # 服务端填充
    plan_data["cyclePattern"] = ""  # 可选

    logger.info(f"✅ 补剂计划结构验证完成")

    return plan_data
