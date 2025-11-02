"""
学生管理相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger, db_helper
from utils.param_parser import parse_int_param, parse_bool_param
from .models import StudentListItem, StudentPlanInfo
import math


@https_fn.on_call()
def fetch_students(req: https_fn.CallableRequest):
    """
    获取学生列表（含分页、搜索、筛选）
    
    请求参数:
        - page_size: 每页数量 (默认20)
        - page_number: 页码，从1开始 (默认1)
        - search_name: 搜索姓名 (可选)
        - filter_plan_id: 筛选训练计划ID (可选)
        - include_plans: 是否包含计划信息 (默认False，可提升性能)
    
    返回:
        - status: 状态码
        - data: 
            - students: 学生列表
            - total_count: 总学生数
            - has_more: 是否还有更多数据
            - current_page: 当前页码
            - total_pages: 总页数
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        coach_id = req.auth.uid

        # 验证教练身份
        user_doc = db_helper.get_document('users', coach_id)
        if not user_doc.exists:
            raise https_fn.HttpsError('not-found', '用户不存在')

        user_data = user_doc.to_dict()
        if user_data.get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以查看学生列表')

        # 获取参数（处理 Protobuf 包装）
        page_size = parse_int_param(req.data.get('page_size'), 20)
        page_number = parse_int_param(req.data.get('page_number'), 1)
        search_name = req.data.get('search_name', '').strip()
        filter_plan_id = req.data.get('filter_plan_id', '').strip()
        include_plans = parse_bool_param(req.data.get('include_plans'), False)


        # 参数验证
        if page_size < 1 or page_size > 100:
            raise https_fn.HttpsError('invalid-argument', '每页数量必须在1-100之间')
        if page_number < 1:
            raise https_fn.HttpsError('invalid-argument', '页码必须大于0')

        logger.info(f'查询学生列表: coach_id={coach_id}, page={page_number}, size={page_size}, search={search_name}, filter={filter_plan_id}')
        
        # 构建查询
        db = firestore.client()
        query = db.collection('users') \
            .where('role', '==', 'student') \
            .where('coachId', '==', coach_id)
        
        # 添加搜索条件（前缀匹配）
        if search_name:
            query = query.order_by('name') \
                .start_at([search_name]) \
                .end_at([search_name + '\uf8ff'])
        else:
            # 默认按name排序（避免createdAt字段缺失或类型不一致导致的排序错误）
            query = query.order_by('name')
        
        # 获取所有匹配的学生（用于计算总数和筛选）
        all_students_docs = query.get()
        all_students = []
        
        for student_doc in all_students_docs:
            student_data = student_doc.to_dict()

            # 只有在需要时才查询计划信息（性能优化）
            exercise_plan = None
            diet_plan = None
            supplement_plan = None

            if include_plans or filter_plan_id:
                exercise_plan = _get_student_plan(db, student_doc.id, 'exercisePlans')
                diet_plan = _get_student_plan(db, student_doc.id, 'dietPlans')
                supplement_plan = _get_student_plan(db, student_doc.id, 'supplementPlans')

            logger.info(f"exercise_plan: {exercise_plan}")
            logger.info(f"diet_plan: {diet_plan}")
            logger.info(f"supplement_plan: {supplement_plan}")
            # 创建学生列表项
            student_item = StudentListItem(
                student_id=student_doc.id,
                name=student_data.get('name', ''),
                email=student_data.get('email', ''),
                avatar_url=student_data.get('avatarUrl'),
                coach_id=student_data.get('coachId'),
                exercise_plan=exercise_plan,
                diet_plan=diet_plan,
                supplement_plan=supplement_plan,
                created_at=student_data.get('createdAt')
            )

            # 应用计划筛选
            if filter_plan_id:
                # 检查学生是否有该计划
                has_plan = False
                if exercise_plan and exercise_plan.id == filter_plan_id:
                    has_plan = True
                if diet_plan and diet_plan.id == filter_plan_id:
                    has_plan = True
                if supplement_plan and supplement_plan.id == filter_plan_id:
                    has_plan = True

                if has_plan:
                    all_students.append(student_item)
            else:
                all_students.append(student_item)
        
        # 计算分页信息
        total_count = len(all_students)
        total_pages = math.ceil(total_count / page_size) if total_count > 0 else 1
        start_index = (page_number - 1) * page_size
        end_index = start_index + page_size
        has_more = end_index < total_count
        
        # 获取当前页的学生
        page_students = all_students[start_index:end_index]
        
        # 转换为字典格式
        students_data = [student.to_dict() for student in page_students]

        logger.info(f'查询学生列表成功: total={total_count}, page={page_number}, returned={len(students_data)}')
        
        return {
            'status': 'success',
            'data': {
                'students': students_data,
                'total_count': total_count,
                'has_more': has_more,
                'current_page': page_number,
                'total_pages': total_pages
            }
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'查询学生列表失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def delete_student(req: https_fn.CallableRequest):
    """
    删除学生（软删除）
    
    请求参数:
        - student_id: 学生ID
    
    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        coach_id = req.auth.uid
        student_id = req.data.get('student_id', '').strip()
        
        if not student_id:
            raise https_fn.HttpsError('invalid-argument', '学生ID不能为空')
        
        # 验证教练身份
        user_doc = db_helper.get_document('users', coach_id)
        if not user_doc.exists or user_doc.to_dict().get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以删除学生')
        
        # 获取学生信息并验证归属
        student_doc = db_helper.get_document('users', student_id)
        if not student_doc.exists:
            raise https_fn.HttpsError('not-found', '学生不存在')
        
        student_data = student_doc.to_dict()
        if student_data.get('coachId') != coach_id:
            raise https_fn.HttpsError('permission-denied', '该学生不属于您')
        
        # 软删除学生
        db_helper.update_document('users', student_id, {
            'isDeleted': True,
            'deletedAt': firestore.SERVER_TIMESTAMP
        })
        
        # 从所有计划中移除该学生
        db = firestore.client()
        _remove_student_from_plans(db, student_id, 'exercisePlans')
        _remove_student_from_plans(db, student_id, 'dietPlans')
        _remove_student_from_plans(db, student_id, 'supplementPlans')
        
        logger.info(f'学生删除成功: {student_id} by coach {coach_id}')
        
        return {
            'status': 'success',
            'message': '学生已删除'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'删除学生失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== 辅助函数 ====================

def _get_student_plan(db, student_id: str, collection_name: str):
    """获取学生的计划信息"""
    try:
        plans = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .limit(1) \
            .get()
        
        if not plans:
            return None
        
        plan_doc = plans[0]
        plan_data = plan_doc.to_dict()
        
        # 确定计划类型
        plan_type = 'exercise' if collection_name == 'exercisePlans' else \
                    'diet' if collection_name == 'dietPlans' else \
                    'supplement'
        
        return StudentPlanInfo(
            plan_id=plan_doc.id,
            plan_name=plan_data.get('name', ''),
            plan_type=plan_type
        )
    except Exception as e:
        logger.error(f'获取学生计划失败: {collection_name}', e)
        return None


def _remove_student_from_plans(db, student_id: str, collection_name: str):
    """从所有计划中移除学生"""
    try:
        plans = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .get()

        batch = db.batch()
        for plan_doc in plans:
            batch.update(plan_doc.reference, {
                'studentIds': firestore.ArrayRemove([student_id])
            })

        if len(plans) > 0:
            batch.commit()
            logger.info(f'从{len(plans)}个{collection_name}中移除学生: {student_id}')
    except Exception as e:
        logger.error(f'从计划中移除学生失败: {collection_name}', e)


# ==================== 训练记录相关 ====================


@https_fn.on_call()
def fetch_latest_training(req: https_fn.CallableRequest):
    """
    获取学生最新一次的训练记录

    用于确定学生今天应该训练计划的第几天

    返回:
        {
            'status': 'success',
            'data': {
                'training': {
                    'id': str,
                    'date': str,
                    'planSelection': {
                        'exercisePlanId': str,
                        'exerciseDayNumber': int,
                        'dietPlanId': str,
                        'dietDayNumber': int,
                        'supplementPlanId': str,
                        'supplementDayNumber': int
                    },
                    ...
                } | None
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        logger.info(f'📖 获取最新训练记录 - 学生ID: {student_id}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 查询 dailyTraining collection
        trainings_query = db.collection('dailyTraining') \
            .where('studentID', '==', student_id) \
            .order_by('date', direction=firestore.Query.DESCENDING) \
            .limit(1) \
            .get()

        # 如果找到记录，返回第一个（最新的）
        training_data = None
        if trainings_query:
            for training_doc in trainings_query:
                training_data = training_doc.to_dict()
                training_data['id'] = training_doc.id
                logger.info(f'✅ 找到最新训练记录: 日期={training_data.get("date")}, ID={training_doc.id}')
                break

        if not training_data:
            logger.info(f'📖 学生无训练记录: {student_id}')

        return {
            'status': 'success',
            'data': {
                'training': training_data
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取最新训练记录失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')

