"""
训练反馈相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger
from typing import Dict, Any, List


@https_fn.on_call()
def fetch_student_feedback(req: https_fn.CallableRequest):
    """
    获取学生的训练反馈列表

    请求参数:
        - studentId: str (required) - 学生ID
        - coachId: str (required) - 教练ID
        - startDate: str (optional) - 开始日期 "yyyy-MM-dd"
        - endDate: str (optional) - 结束日期 "yyyy-MM-dd"
        - limit: int (optional) - 限制数量，默认50

    返回:
        {
            'status': 'success',
            'data': {
                'feedbacks': List[TrainingFeedbackModel]
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        # 获取参数
        student_id = req.data.get('studentId', '').strip()
        coach_id = req.data.get('coachId', '').strip()
        start_date = req.data.get('startDate', '').strip()
        end_date = req.data.get('endDate', '').strip()
        limit = req.data.get('limit', 50)

        # 参数验证
        if not student_id:
            raise https_fn.HttpsError('invalid-argument', 'studentId 不能为空')
        if not coach_id:
            raise https_fn.HttpsError('invalid-argument', 'coachId 不能为空')

        logger.info(f'📖 获取训练反馈 - 学生: {student_id}, 教练: {coach_id}')

        # 构建查询
        db = firestore.client()
        query = db.collection('dailyTrainingFeedback') \
            .where('studentId', '==', student_id) \
            .where('coachId', '==', coach_id)

        # 添加日期范围筛选
        if start_date:
            query = query.where('trainingDate', '>=', start_date)
        if end_date:
            query = query.where('trainingDate', '<=', end_date)

        # 排序和限制
        query = query.order_by('trainingDate', direction=firestore.Query.DESCENDING) \
            .limit(limit)

        # 执行查询
        feedback_docs = query.get()

        # 转换为列表
        feedbacks = []
        for doc in feedback_docs:
            feedback_data = doc.to_dict()
            feedback_data['id'] = doc.id
            feedbacks.append(feedback_data)

        logger.info(f'✅ 找到 {len(feedbacks)} 条反馈记录')

        return {
            'status': 'success',
            'data': {
                'feedbacks': feedbacks
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取训练反馈失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')
