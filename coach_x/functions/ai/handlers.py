"""
AI Cloud Functions 处理器（统一导出入口）

本文件已重构为模块化结构，实际实现位于子目录：
- training_plan/ - 训练计划相关
- diet_plan/ - 饮食计划相关
- image_import/ - 图片导入相关
- food_macros/ - 食物营养相关
"""

# 训练计划模块
from .training_plan.handlers import (
    generate_ai_training_plan,
    stream_training_plan,
    edit_plan_conversation,
)

# 饮食计划模块
from .diet_plan.handlers import (
    generate_diet_plan_with_skill,
    edit_diet_plan_conversation,
)

# 图片导入模块
from .image_import.handlers import (
    import_plan_from_image,
)

from .image_import.supplement_handlers import (
    import_supplement_plan_from_image,
)

# 文本导入模块
from .text_import.handlers import (
    import_plan_from_text,
)

# 食物营养模块
from .food_macros.handlers import (
    get_food_macros,
)

from .food_nutrition.handlers import (
    analyze_food_nutrition,
)

# 聊天模块
from .chat.handlers import (
    chat_with_ai,
)

# 向后兼容导出
__all__ = [
    # Training Plan
    'generate_ai_training_plan',
    'stream_training_plan',
    'edit_plan_conversation',

    # Diet Plan
    'generate_diet_plan_with_skill',
    'edit_diet_plan_conversation',

    # Image Import
    'import_plan_from_image',
    'import_supplement_plan_from_image',

    # Text Import
    'import_plan_from_text',

    # Food Macros
    'get_food_macros',
    'analyze_food_nutrition',

    # Chat
    'chat_with_ai',

    # Supplement Plan
    'generate_supplement_plan_conversation',
]


# ==================== Supplement Plan Module ====================

from firebase_functions import https_fn, options
from firebase_admin import firestore
from flask import Response
import json
from utils.logger import logger


@https_fn.on_request(
    timeout_sec=540,
    secrets=["ANTHROPIC_API_KEY"],
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post", "options"]),
)
def generate_supplement_plan_conversation(req: https_fn.Request) -> Response:
    """
    补剂计划对话生成（SSE流式）

    HTTP POST /generate_supplement_plan_conversation

    请求体:
    {
      "user_id": str,
      "user_message": str,
      "training_plan_id": str (可选),
      "diet_plan_id": str (可选),
      "conversation_history": List[dict] (可选)
    }

    响应: Server-Sent Events
    data: {"type": "thinking", "content": "..."}
    data: {"type": "analysis", "content": "..."}
    data: {"type": "suggestion", "data": {...}}
    data: {"type": "complete"}
    """
    try:
        logger.info("💊 收到补剂计划对话生成请求")

        # 解析请求数据
        try:
            data = req.get_json()
            if not data:
                raise ValueError("请求体为空")
        except Exception as e:
            logger.error(f"❌ 解析请求失败: {str(e)}")
            return Response(
                f'data: {json.dumps({"type": "error", "error": "请求格式错误"}, ensure_ascii=False)}\n\n',
                mimetype='text/event-stream'
            )

        user_id = data.get('user_id')
        user_message = data.get('user_message')
        training_plan_id = data.get('training_plan_id')
        diet_plan_id = data.get('diet_plan_id')
        conversation_history = data.get('conversation_history', [])

        if not user_id or not user_message:
            return Response(
                f'data: {json.dumps({"type": "error", "error": "缺少必需参数"}, ensure_ascii=False)}\n\n',
                mimetype='text/event-stream'
            )

        logger.info(f'💊 补剂计划对话 - User: {user_id}, Message: {user_message[:50]}...')

        # 获取训练计划和饮食计划
        training_plan = None
        diet_plan = None

        db = firestore.client()

        # 获取训练计划（使用 _get_plan）
        if training_plan_id:
            try:
                plan_ref = db.collection('exercisePlans').document(training_plan_id)
                plan_doc = plan_ref.get()
                if plan_doc.exists:
                    training_plan = plan_doc.to_dict()
                    # 验证权限
                    if training_plan.get('ownerId') != user_id:
                        logger.warning(f'⚠️ 用户 {user_id} 无权访问训练计划 {training_plan_id}')
                        training_plan = None
                    else:
                        logger.info(f'✅ 获取训练计划成功: {training_plan.get("name")}')
            except Exception as e:
                logger.error(f'❌ 获取训练计划失败: {str(e)}')

        # 获取饮食计划（使用 _get_diet_plan）
        if diet_plan_id:
            try:
                plan_ref = db.collection('dietPlans').document(diet_plan_id)
                plan_doc = plan_ref.get()
                if plan_doc.exists:
                    diet_plan = plan_doc.to_dict()
                    # 验证权限
                    if diet_plan.get('ownerId') != user_id:
                        logger.warning(f'⚠️ 用户 {user_id} 无权访问饮食计划 {diet_plan_id}')
                        diet_plan = None
                    else:
                        logger.info(f'✅ 获取饮食计划成功: {diet_plan.get("name")}')
            except Exception as e:
                logger.error(f'❌ 获取饮食计划失败: {str(e)}')

        # 如果没有提供ID，尝试获取最新的plans（可选）
        if not training_plan and not training_plan_id:
            logger.info('📋 未提供训练计划ID，尝试获取最新训练计划')
            try:
                from plans.handlers import _get_coach_plans
                plans = _get_coach_plans(db, user_id, 'exercisePlans')
                if plans:
                    training_plan = plans[0]
                    logger.info(f'✅ 使用最新训练计划: {training_plan.get("name")}')
            except Exception as e:
                logger.warning(f'⚠️ 获取最新训练计划失败: {str(e)}')

        if not diet_plan and not diet_plan_id:
            logger.info('🍽️ 未提供饮食计划ID，尝试获取最新饮食计划')
            try:
                from plans.handlers import _get_coach_plans
                plans = _get_coach_plans(db, user_id, 'dietPlans')
                if plans:
                    diet_plan = plans[0]
                    logger.info(f'✅ 使用最新饮食计划: {diet_plan.get("name")}')
            except Exception as e:
                logger.warning(f'⚠️ 获取最新饮食计划失败: {str(e)}')

        # 调用流式生成
        from .streaming import stream_generate_supplement_plan_conversation

        def generate():
            for event in stream_generate_supplement_plan_conversation(
                user_id=user_id,
                user_message=user_message,
                training_plan=training_plan,
                diet_plan=diet_plan,
                conversation_history=conversation_history
            ):
                yield f'data: {json.dumps(event, ensure_ascii=False)}\n\n'

        return Response(
            generate(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'X-Accel-Buffering': 'no'
            }
        )

    except Exception as e:
        logger.error(f'❌ 补剂计划对话失败: {str(e)}', exc_info=True)
        return Response(
            f'data: {json.dumps({"type": "error", "error": str(e)}, ensure_ascii=False)}\n\n',
            mimetype='text/event-stream'
        )
