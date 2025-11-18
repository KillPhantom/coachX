"""
Exercise Library 处理器

处理动作库的创建、读取、更新、删除等操作
"""

from firebase_functions import https_fn
from firebase_admin import firestore
from typing import Dict, Any

from utils.logger import logger


@https_fn.on_call()
def delete_exercise_template(req: https_fn.CallableRequest):
    """
    删除动作模板（带引用保护）

    请求参数:
        - templateId: str, 模板ID

    返回:
        {
            'status': 'success' | 'error',
            'message': str,
            'plan_count': int (error 时返回)
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        coach_id = req.auth.uid
        template_id = req.data.get('templateId')

        if not template_id:
            raise https_fn.HttpsError('invalid-argument', 'templateId 参数不能为空')

        logger.info(f'🗑️ 删除动作模板 - 教练: {coach_id}, 模板: {template_id}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 1. 查询所有训练计划
        plans_query = db.collection('exercisePlans').where('ownerId', '==', coach_id)
        plans_snapshot = plans_query.stream()

        # 2. 检查引用
        ref_count = 0
        for plan_doc in plans_snapshot:
            plan_data = plan_doc.to_dict()
            days = plan_data.get('days', [])

            for day in days:
                exercises = day.get('exercises', [])
                for exercise in exercises:
                    if exercise.get('exerciseTemplateId') == template_id:
                        ref_count += 1

        # 3. 如果有引用，返回错误
        if ref_count > 0:
            logger.warning(f'⚠️ 模板被 {ref_count} 个计划引用，无法删除')
            raise https_fn.HttpsError(
                'failed-precondition',
                f'模板正被 {ref_count} 个训练计划使用',
                {'plan_count': ref_count}
            )

        # 4. 删除模板
        db.collection('exerciseTemplates').document(template_id).delete()

        logger.info(f'✅ 删除动作模板成功: {template_id}')
        return {'status': 'success', 'message': '删除成功'}

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 删除动作模板失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')
