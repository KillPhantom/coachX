"""
批量创建动作模板的处理器
"""

from firebase_admin import firestore
from firebase_functions import https_fn
from typing import Dict, Any, List
from utils.logger import logger


@https_fn.on_call()
def create_exercise_templates_batch(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    批量创建动作模板

    Args:
        req.data: {
            "coach_id": str,
            "exercise_names": List[str]
        }

    Returns:
        {
            "status": "success",
            "data": {
                "template_id_map": {
                    "深蹲": "template_id_1",
                    "卧推": "template_id_2"
                }
            }
        }
    """
    try:
        # 验证输入
        coach_id = req.data.get('coach_id')
        exercise_names = req.data.get('exercise_names', [])

        if not coach_id:
            raise ValueError('Missing coach_id')

        if not exercise_names or not isinstance(exercise_names, list):
            raise ValueError('Invalid exercise_names')

        logger.info(f'🔧 开始批量创建 {len(exercise_names)} 个模板 - Coach: {coach_id}')

        # 初始化 Firestore
        db = firestore.client()
        template_id_map = {}

        # 批量创建模板
        batch = db.batch()

        for exercise_name in exercise_names:
            # 创建新模板文档
            template_ref = db.collection('exerciseTemplates').document()

            template_data = {
                'name': exercise_name,
                'tags': [],  # 默认空标签
                'ownerId': coach_id,  # ✅ 修正：使用 ownerId 而不是 coachId
                'videoUrls': [],  # ✅ 新增：视频 URL 列表
                'thumbnailUrls': [],  # ✅ 新增：缩略图 URL 列表
                'imageUrls': [],  # ✅ 新增：图片 URL 列表
                'textGuidance': None,  # ✅ 新增：文字说明（可选）
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            }

            batch.set(template_ref, template_data)
            template_id_map[exercise_name] = template_ref.id

            logger.info(f'  ✅ 准备创建: {exercise_name} -> {template_ref.id}')

        # 提交批量操作
        batch.commit()
        logger.info(f'✅ 批量创建完成: {len(template_id_map)} 个模板')

        return {
            'status': 'success',
            'data': {
                'template_id_map': template_id_map
            }
        }

    except Exception as e:
        logger.error(f'❌ 批量创建模板失败: {str(e)}', exc_info=True)
        return {
            'status': 'error',
            'error': str(e)
        }
