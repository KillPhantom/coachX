"""
学生训练记录相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger, db_helper
from typing import Dict, Any


@https_fn.on_call()
def fetch_today_training(req: https_fn.CallableRequest):
    """
    获取学生指定日期的训练记录

    请求参数:
        - date: str, 日期格式 "yyyy-MM-dd"

    返回:
        {
            'status': 'success',
            'data': {
                'training': DailyTrainingModel | None
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid
        date = req.data.get('date', '').strip()

        if not date:
            raise https_fn.HttpsError('invalid-argument', '日期不能为空')

        # 验证日期格式 (简单验证)
        if len(date) != 10 or date.count('-') != 2:
            raise https_fn.HttpsError(
                'invalid-argument',
                '日期格式错误，应为 yyyy-MM-dd'
            )

        logger.info(f'📖 获取训练记录 - 学生: {student_id}, 日期: {date}')

        # 查询 dailyTraining collection
        db = firestore.client()
        trainings_query = db.collection('dailyTraining') \
            .where('studentID', '==', student_id) \
            .where('date', '==', date) \
            .limit(1) \
            .get()

        # 查找匹配的记录
        training_data = None
        if trainings_query:
            for training_doc in trainings_query:
                training_data = training_doc.to_dict()
                training_data['id'] = training_doc.id
                logger.info(f'✅ 找到训练记录: ID={training_doc.id}')
                break

        if not training_data:
            logger.info(f'📖 未找到训练记录: {student_id} - {date}')

        return {
            'status': 'success',
            'data': training_data
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取训练记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def upsert_today_training(req: https_fn.CallableRequest):
    """
    创建或更新学生训练记录

    请求参数: 完整的DailyTrainingModel JSON
        - id: str (可选，如果为空则创建新记录)
        - studentID: str
        - coachID: str
        - date: str
        - planSelection: dict
        - diet: dict (可选)
        - exercises: list (可选)
        - supplements: list (可选)
        - completionStatus: str (可选)
        - isReviewed: bool (可选)

    返回:
        {
            'status': 'success',
            'data': {
                'id': document_id
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid
        training_data = dict(req.data)

        # 验证必需字段
        student_id = training_data.get('studentID', '').strip()
        coach_id = training_data.get('coachID', '').strip()
        date = training_data.get('date', '').strip()

        if not student_id or not coach_id or not date:
            raise https_fn.HttpsError(
                'invalid-argument',
                '缺少必需字段: studentID, coachID, date'
            )

        # 验证权限：只能操作自己的记录
        if student_id != user_id:
            raise https_fn.HttpsError(
                'permission-denied',
                '只能保存自己的训练记录'
            )

        logger.info(f'💾 保存训练记录 - 学生: {student_id}, 日期: {date}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 查询是否已存在该日期的记录
        existing_query = db.collection('dailyTraining') \
            .where('studentID', '==', student_id) \
            .where('date', '==', date) \
            .limit(1) \
            .get()

        doc_id = training_data.get('id', '').strip()
        doc_ref = None

        # 准备保存的数据（移除id字段，Firestore不需要）
        save_data = {k: v for k, v in training_data.items() if k != 'id'}

        # 如果存在记录，更新它
        if existing_query:
            for existing_doc in existing_query:
                doc_id = existing_doc.id
                doc_ref = existing_doc.reference
                logger.info(f'📝 更新已存在的记录: {doc_id}')
                doc_ref.update(save_data)
                break
        else:
            # 创建新记录
            if doc_id:
                # 如果提供了ID，使用指定ID创建
                doc_ref = db.collection('dailyTraining').document(doc_id)
                doc_ref.set(save_data)
                logger.info(f'✨ 创建新记录（指定ID）: {doc_id}')
            else:
                # 自动生成ID
                doc_ref = db.collection('dailyTraining').add(save_data)[1]
                doc_id = doc_ref.id
                logger.info(f'✨ 创建新记录（自动ID）: {doc_id}')

        logger.info(f'✅ 训练记录保存成功: {doc_id}')

        return {
            'status': 'success',
            'data': {
                'id': doc_id
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 保存训练记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')
