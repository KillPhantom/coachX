"""
Plans CRUD 处理器

处理训练计划的创建、读取、更新、删除等操作
"""

from firebase_functions import https_fn
from firebase_admin import firestore
from typing import Dict, Any
import time

from .models import ExercisePlan, DietPlan
from utils.logger import logger


@https_fn.on_call()
def exercise_plan(req: https_fn.CallableRequest):
    """
    训练计划操作路由
    
    请求参数:
        - action: str, 操作类型 ('create', 'update', 'get', 'delete', 'list', 'copy')
        - planId: str, 计划ID（create时可选，其他必需）
        - planData: dict, 计划数据（create和update时需要）
    
    返回:
        {
            'status': 'success' | 'error',
            'data': {...}
            'message': str
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        user_id = req.auth.uid
        action = req.data.get('action', '').lower()
        
        if not action:
            raise https_fn.HttpsError('invalid-argument', 'action 参数不能为空')
        
        logger.info(f'📋 训练计划操作 - 用户: {user_id}, 操作: {action}')
        
        # 根据 action 分发
        if action == 'create':
            return _create_plan(req, user_id)
        elif action == 'update':
            return _update_plan(req, user_id)
        elif action == 'get':
            return _get_plan(req, user_id)
        elif action == 'delete':
            return _delete_plan(req, user_id)
        elif action == 'list':
            return _list_plans(req, user_id)
        elif action == 'copy':
            return _copy_plan(req, user_id)
        else:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'不支持的操作: {action}'
            )
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 训练计划操作失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _create_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    创建训练计划
    
    Args:
        req: 请求对象
        user_id: 用户ID
    
    Returns:
        创建结果
    """
    try:
        plan_data = req.data.get('planData', {})
        
        if not plan_data:
            raise https_fn.HttpsError('invalid-argument', 'planData 不能为空')
        
        # 验证计划数据
        validation_error = _validate_plan_data(plan_data)
        if validation_error:
            raise https_fn.HttpsError('invalid-argument', validation_error)
        
        # 获取 Firestore 实例
        db = firestore.client()
        
        # 生成新的文档ID
        plan_ref = db.collection('exercisePlans').document()
        plan_id = plan_ref.id
        
        # 设置时间戳
        now = int(time.time() * 1000)
        
        # 构建完整的计划文档
        plan_doc = {
            'id': plan_id,
            'name': plan_data.get('name', ''),
            'description': plan_data.get('description', ''),
            'days': plan_data.get('days', []),
            'ownerId': user_id,
            'studentIds': [],
            'createdAt': now,
            'updatedAt': now,
        }
        
        # 保存到 Firestore
        plan_ref.set(plan_doc)
        
        logger.info(f'✅ 训练计划创建成功 - ID: {plan_id}')
        
        return {
            'status': 'success',
            'data': {
                'planId': plan_id,
                'plan': plan_doc
            },
            'message': '创建成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 创建计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'创建失败: {str(e)}')


def _update_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    更新训练计划
    
    Args:
        req: 请求对象
        user_id: 用户ID
    
    Returns:
        更新结果
    """
    try:
        plan_id = req.data.get('planId', '')
        plan_data = req.data.get('planData', {})
        
        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')
        
        if not plan_data:
            raise https_fn.HttpsError('invalid-argument', 'planData 不能为空')
        
        # 验证计划数据
        validation_error = _validate_plan_data(plan_data)
        if validation_error:
            raise https_fn.HttpsError('invalid-argument', validation_error)
        
        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('exercisePlans').document(plan_id)
        
        # 检查计划是否存在
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')
        
        # 检查权限
        plan_owner_id = plan_doc.to_dict().get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权修改此计划')
        
        # 更新时间戳
        now = int(time.time() * 1000)
        
        # 构建更新数据
        update_data = {
            'name': plan_data.get('name', ''),
            'description': plan_data.get('description', ''),
            'days': plan_data.get('days', []),
            'updatedAt': now,
        }
        
        # 更新 Firestore
        plan_ref.update(update_data)
        
        logger.info(f'✅ 训练计划更新成功 - ID: {plan_id}')
        
        return {
            'status': 'success',
            'data': {
                'planId': plan_id
            },
            'message': '更新成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 更新计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'更新失败: {str(e)}')


def _get_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    获取训练计划详情
    
    Args:
        req: 请求对象
        user_id: 用户ID
    
    Returns:
        计划详情
    """
    try:
        plan_id = req.data.get('planId', '')
        
        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')
        
        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('exercisePlans').document(plan_id)
        
        # 获取计划文档
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')
        
        plan_data = plan_doc.to_dict()
        
        # 检查权限
        plan_owner_id = plan_data.get('ownerId', '')
        student_ids = plan_data.get('studentIds', [])
        
        # 允许计划所有者或被分配的学生查看
        if plan_owner_id != user_id and user_id not in student_ids:
            raise https_fn.HttpsError('permission-denied', '无权查看此计划')
        
        logger.info(f'✅ 获取训练计划成功 - ID: {plan_id}')
        
        return {
            'status': 'success',
            'data': {
                'plan': plan_data
            }
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


def _delete_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    删除训练计划
    
    Args:
        req: 请求对象
        user_id: 用户ID
    
    Returns:
        删除结果
    """
    try:
        plan_id = req.data.get('planId', '')
        
        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')
        
        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('exercisePlans').document(plan_id)
        
        # 检查计划是否存在
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')
        
        # 检查权限
        plan_owner_id = plan_doc.to_dict().get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权删除此计划')
        
        # 删除计划
        plan_ref.delete()
        
        logger.info(f'✅ 训练计划删除成功 - ID: {plan_id}')
        
        return {
            'status': 'success',
            'data': {
                'planId': plan_id
            },
            'message': '删除成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 删除计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'删除失败: {str(e)}')


def _list_plans(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    列出用户的训练计划
    
    注意：此功能由 fetch_available_plans 在 students/handlers.py 中实现
    这里保留接口以便未来扩展
    
    Args:
        req: 请求对象
        user_id: 用户ID
    
    Returns:
        计划列表
    """
    try:
        # 获取 Firestore 实例
        db = firestore.client()
        
        # 查询用户拥有的计划
        plans_query = db.collection('exercisePlans') \
            .where('ownerId', '==', user_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING)
        
        plans_docs = plans_query.stream()
        
        plans = []
        for doc in plans_docs:
            plan_data = doc.to_dict()
            plans.append(plan_data)
        
        logger.info(f'✅ 获取训练计划列表成功 - 数量: {len(plans)}')
        
        return {
            'status': 'success',
            'data': {
                'plans': plans
            }
        }
    
    except Exception as e:
        logger.error(f'❌ 获取计划列表失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


def _copy_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    复制训练计划
    
    Args:
        req: 请求对象
        user_id: 用户ID
    
    Returns:
        新计划ID
    """
    try:
        plan_id = req.data.get('planId', '')
        
        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')
        
        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('exercisePlans').document(plan_id)
        
        # 获取原计划
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')
        
        original_plan = plan_doc.to_dict()
        
        # 检查权限（只有所有者可以复制）
        plan_owner_id = original_plan.get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权复制此计划')
        
        # 创建新的计划文档
        new_plan_ref = db.collection('exercisePlans').document()
        new_plan_id = new_plan_ref.id
        
        # 构建新计划数据
        now = int(time.time() * 1000)
        new_plan = {
            'id': new_plan_id,
            'name': f"{original_plan.get('name', '')} (副本)",
            'description': original_plan.get('description', ''),
            'days': original_plan.get('days', []),
            'ownerId': user_id,
            'studentIds': [],  # 新计划不继承学生分配
            'createdAt': now,
            'updatedAt': now,
        }
        
        # 保存新计划
        new_plan_ref.set(new_plan)
        
        logger.info(f'✅ 训练计划复制成功 - 原ID: {plan_id}, 新ID: {new_plan_id}')
        
        return {
            'status': 'success',
            'data': {
                'planId': new_plan_id,
                'plan': new_plan
            },
            'message': '复制成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 复制计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'复制失败: {str(e)}')


def _validate_plan_data(plan_data: Dict[str, Any]) -> str:
    """
    验证计划数据
    
    Args:
        plan_data: 计划数据
    
    Returns:
        错误信息，如果验证通过则返回空字符串
    """
    # 验证名称
    name = plan_data.get('name', '').strip()
    if not name:
        return 'planName 不能为空'
    
    # 验证训练日
    days = plan_data.get('days', [])
    if not isinstance(days, list):
        return 'days 必须是数组'
    
    if len(days) == 0:
        return '至少需要一个训练日'
    
    # 验证每个训练日
    for i, day in enumerate(days):
        if not isinstance(day, dict):
            return f'第 {i+1} 个训练日数据格式错误'
        
        exercises = day.get('exercises', [])
        if not isinstance(exercises, list):
            return f'第 {i+1} 个训练日的 exercises 必须是数组'
        
        if len(exercises) == 0:
            return f'第 {i+1} 个训练日至少需要一个动作'
        
        # 验证每个动作
        for j, exercise in enumerate(exercises):
            if not isinstance(exercise, dict):
                return f'第 {i+1} 个训练日的第 {j+1} 个动作数据格式错误'
            
            exercise_name = exercise.get('name', '').strip()
            if not exercise_name:
                return f'第 {i+1} 个训练日的第 {j+1} 个动作名称不能为空'
            
            sets = exercise.get('sets', [])
            if not isinstance(sets, list) or len(sets) == 0:
                return f'第 {i+1} 个训练日的第 {j+1} 个动作至少需要一组'
    
    return ''


@https_fn.on_call()
def fetch_available_plans(req: https_fn.CallableRequest):
    """
    获取教练的所有可用计划
    
    返回:
        - status: 状态码
        - data:
            - exercise_plans: 训练计划列表
            - diet_plans: 饮食计划列表
            - supplement_plans: 补剂计划列表
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        coach_id = req.auth.uid
        
        # 获取 Firestore 实例
        db = firestore.client()
        
        # 查询三种计划
        exercise_plans = _get_coach_plans(db, coach_id, 'exercisePlans')
        diet_plans = _get_coach_plans(db, coach_id, 'dietPlans')
        supplement_plans = _get_coach_plans(db, coach_id, 'supplementPlans')
        
        logger.info(f'✅ 查询可用计划成功: coach_id={coach_id}, 训练:{len(exercise_plans)}, 饮食:{len(diet_plans)}, 补剂:{len(supplement_plans)}')
        
        return {
            'status': 'success',
            'data': {
                'exercise_plans': exercise_plans,
                'diet_plans': diet_plans,
                'supplement_plans': supplement_plans
            }
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 查询可用计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _get_coach_plans(db, coach_id: str, collection_name: str):
    """
    获取教练的计划列表

    Args:
        db: Firestore 实例
        coach_id: 教练ID
        collection_name: 集合名称（exercisePlans, dietPlans, supplementPlans）

    Returns:
        计划列表
    """
    try:
        plans_query = db.collection(collection_name) \
            .where('ownerId', '==', coach_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING) \
            .get()

        plans = []
        for plan_doc in plans_query:
            plan_data = plan_doc.to_dict()
            # 返回完整的计划数据，添加文档ID
            plan_data['id'] = plan_doc.id
            plans.append(plan_data)

        logger.info(f'📋 获取教练计划成功: {collection_name}, 数量: {len(plans)}')
        return plans
    except Exception as e:
        logger.error(f'❌ 获取教练计划失败: {collection_name}, 错误: {str(e)}', exc_info=True)
        return []


# ==================== Diet Plan Handlers ====================


@https_fn.on_call()
def diet_plan(req: https_fn.CallableRequest):
    """
    饮食计划操作路由

    请求参数:
        - action: str, 操作类型 ('create', 'update', 'get', 'delete', 'list', 'copy')
        - planId: str, 计划ID（create时可选，其他必需）
        - planData: dict, 计划数据（create和update时需要）

    返回:
        {
            'status': 'success' | 'error',
            'data': {...}
            'message': str
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid
        action = req.data.get('action', '').lower()

        if not action:
            raise https_fn.HttpsError('invalid-argument', 'action 参数不能为空')

        logger.info(f'🥗 饮食计划操作 - 用户: {user_id}, 操作: {action}')

        # 根据 action 分发
        if action == 'create':
            return _create_diet_plan(req, user_id)
        elif action == 'update':
            return _update_diet_plan(req, user_id)
        elif action == 'get':
            return _get_diet_plan(req, user_id)
        elif action == 'delete':
            return _delete_diet_plan(req, user_id)
        elif action == 'list':
            return _list_diet_plans(req, user_id)
        elif action == 'copy':
            return _copy_diet_plan(req, user_id)
        else:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'不支持的操作: {action}'
            )

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 饮食计划操作失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _create_diet_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    创建饮食计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        创建结果
    """
    try:
        plan_data = req.data.get('planData', {})

        if not plan_data:
            raise https_fn.HttpsError('invalid-argument', 'planData 不能为空')

        # 验证计划数据
        validation_error = _validate_diet_plan_data(plan_data)
        if validation_error:
            raise https_fn.HttpsError('invalid-argument', validation_error)

        # 获取 Firestore 实例
        db = firestore.client()

        # 生成新的文档ID
        plan_ref = db.collection('dietPlans').document()
        plan_id = plan_ref.id

        # 设置时间戳
        now = int(time.time() * 1000)

        # 构建完整的计划文档
        plan_doc = {
            'id': plan_id,
            'name': plan_data.get('name', ''),
            'description': plan_data.get('description', ''),
            'days': plan_data.get('days', []),
            'ownerId': user_id,
            'studentIds': [],
            'createdAt': now,
            'updatedAt': now,
        }

        # 保存到 Firestore
        plan_ref.set(plan_doc)

        logger.info(f'✅ 饮食计划创建成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': plan_id,
                'plan': plan_doc
            },
            'message': '创建成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 创建饮食计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'创建失败: {str(e)}')


def _update_diet_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    更新饮食计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        更新结果
    """
    try:
        plan_id = req.data.get('planId', '')
        plan_data = req.data.get('planData', {})

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        if not plan_data:
            raise https_fn.HttpsError('invalid-argument', 'planData 不能为空')

        # 验证计划数据
        validation_error = _validate_diet_plan_data(plan_data)
        if validation_error:
            raise https_fn.HttpsError('invalid-argument', validation_error)

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('dietPlans').document(plan_id)

        # 检查计划是否存在
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        # 检查权限
        plan_owner_id = plan_doc.to_dict().get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权修改此计划')

        # 更新时间戳
        now = int(time.time() * 1000)

        # 构建更新数据
        update_data = {
            'name': plan_data.get('name', ''),
            'description': plan_data.get('description', ''),
            'days': plan_data.get('days', []),
            'updatedAt': now,
        }

        # 更新 Firestore
        plan_ref.update(update_data)

        logger.info(f'✅ 饮食计划更新成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': plan_id
            },
            'message': '更新成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 更新饮食计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'更新失败: {str(e)}')


def _get_diet_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    获取饮食计划详情

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        计划详情
    """
    try:
        plan_id = req.data.get('planId', '')

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('dietPlans').document(plan_id)

        # 获取计划文档
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        plan_data = plan_doc.to_dict()

        # 检查权限
        plan_owner_id = plan_data.get('ownerId', '')
        student_ids = plan_data.get('studentIds', [])

        # 允许计划所有者或被分配的学生查看
        if plan_owner_id != user_id and user_id not in student_ids:
            raise https_fn.HttpsError('permission-denied', '无权查看此计划')

        logger.info(f'✅ 获取饮食计划成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'plan': plan_data
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取饮食计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


def _delete_diet_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    删除饮食计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        删除结果
    """
    try:
        plan_id = req.data.get('planId', '')

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('dietPlans').document(plan_id)

        # 检查计划是否存在
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        # 检查权限
        plan_owner_id = plan_doc.to_dict().get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权删除此计划')

        # 删除计划
        plan_ref.delete()

        logger.info(f'✅ 饮食计划删除成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': plan_id
            },
            'message': '删除成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 删除饮食计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'删除失败: {str(e)}')


def _list_diet_plans(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    列出用户的饮食计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        计划列表
    """
    try:
        # 获取 Firestore 实例
        db = firestore.client()

        # 查询用户拥有的计划
        plans_query = db.collection('dietPlans') \
            .where('ownerId', '==', user_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING)

        plans_docs = plans_query.stream()

        plans = []
        for doc in plans_docs:
            plan_data = doc.to_dict()
            plans.append(plan_data)

        logger.info(f'✅ 获取饮食计划列表成功 - 数量: {len(plans)}')

        return {
            'status': 'success',
            'data': {
                'plans': plans
            }
        }

    except Exception as e:
        logger.error(f'❌ 获取饮食计划列表失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


def _copy_diet_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    复制饮食计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        新计划ID
    """
    try:
        plan_id = req.data.get('planId', '')

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('dietPlans').document(plan_id)

        # 获取原计划
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        original_plan = plan_doc.to_dict()

        # 检查权限（只有所有者可以复制）
        plan_owner_id = original_plan.get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权复制此计划')

        # 创建新的计划文档
        new_plan_ref = db.collection('dietPlans').document()
        new_plan_id = new_plan_ref.id

        # 构建新计划数据
        now = int(time.time() * 1000)
        new_plan = {
            'id': new_plan_id,
            'name': f"{original_plan.get('name', '')} (副本)",
            'description': original_plan.get('description', ''),
            'days': original_plan.get('days', []),
            'ownerId': user_id,
            'studentIds': [],  # 新计划不继承学生分配
            'createdAt': now,
            'updatedAt': now,
        }

        # 保存新计划
        new_plan_ref.set(new_plan)

        logger.info(f'✅ 饮食计划复制成功 - 原ID: {plan_id}, 新ID: {new_plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': new_plan_id,
                'plan': new_plan
            },
            'message': '复制成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 复制饮食计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'复制失败: {str(e)}')


def _validate_diet_plan_data(plan_data: Dict[str, Any]) -> str:
    """
    验证饮食计划数据

    Args:
        plan_data: 计划数据

    Returns:
        错误信息，如果验证通过则返回空字符串
    """
    # 验证名称
    name = plan_data.get('name', '').strip()
    if not name:
        return 'planName 不能为空'

    # 验证饮食日
    days = plan_data.get('days', [])
    if not isinstance(days, list):
        return 'days 必须是数组'

    if len(days) == 0:
        return '至少需要一个饮食日'

    # 验证每个饮食日
    for i, day in enumerate(days):
        if not isinstance(day, dict):
            return f'第 {i+1} 个饮食日数据格式错误'

        meals = day.get('meals', [])
        if not isinstance(meals, list):
            return f'第 {i+1} 个饮食日的 meals 必须是数组'

        if len(meals) == 0:
            return f'第 {i+1} 个饮食日至少需要一个餐次'

        # 验证每个餐次
        for j, meal in enumerate(meals):
            if not isinstance(meal, dict):
                return f'第 {i+1} 个饮食日的第 {j+1} 个餐次数据格式错误'

            meal_name = meal.get('name', '').strip()
            if not meal_name:
                return f'第 {i+1} 个饮食日的第 {j+1} 个餐次名称不能为空'

            items = meal.get('items', [])
            if not isinstance(items, list) or len(items) == 0:
                return f'第 {i+1} 个饮食日的第 {j+1} 个餐次至少需要一个食物'

    return ''


# ==================== Supplement Plan Handlers ====================


@https_fn.on_call()
def supplement_plan(req: https_fn.CallableRequest):
    """
    补剂计划操作路由

    请求参数:
        - action: str, 操作类型 ('create', 'update', 'get', 'delete', 'list', 'copy')
        - planId: str, 计划ID（create时可选，其他必需）
        - planData: dict, 计划数据（create和update时需要）

    返回:
        {
            'status': 'success' | 'error',
            'data': {...}
            'message': str
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid
        action = req.data.get('action', '').lower()

        if not action:
            raise https_fn.HttpsError('invalid-argument', 'action 参数不能为空')

        logger.info(f'💊 补剂计划操作 - 用户: {user_id}, 操作: {action}')

        # 根据 action 分发
        if action == 'create':
            return _create_supplement_plan(req, user_id)
        elif action == 'update':
            return _update_supplement_plan(req, user_id)
        elif action == 'get':
            return _get_supplement_plan(req, user_id)
        elif action == 'delete':
            return _delete_supplement_plan(req, user_id)
        elif action == 'list':
            return _list_supplement_plans(req, user_id)
        elif action == 'copy':
            return _copy_supplement_plan(req, user_id)
        else:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'不支持的操作: {action}'
            )

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 补剂计划操作失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _create_supplement_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    创建补剂计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        创建结果
    """
    try:
        plan_data = req.data.get('planData', {})

        if not plan_data:
            raise https_fn.HttpsError('invalid-argument', 'planData 不能为空')

        # 验证计划数据
        validation_error = _validate_supplement_plan_data(plan_data)
        if validation_error:
            raise https_fn.HttpsError('invalid-argument', validation_error)

        # 获取 Firestore 实例
        db = firestore.client()

        # 生成新的文档ID
        plan_ref = db.collection('supplementPlans').document()
        plan_id = plan_ref.id

        # 设置时间戳
        now = int(time.time() * 1000)

        # 构建完整的计划文档
        plan_doc = {
            'id': plan_id,
            'name': plan_data.get('name', ''),
            'description': plan_data.get('description', ''),
            'days': plan_data.get('days', []),
            'ownerId': user_id,
            'studentIds': [],
            'createdAt': now,
            'updatedAt': now,
        }

        # 保存到 Firestore
        plan_ref.set(plan_doc)

        logger.info(f'✅ 补剂计划创建成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': plan_id,
                'plan': plan_doc
            },
            'message': '创建成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 创建补剂计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'创建失败: {str(e)}')


def _update_supplement_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    更新补剂计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        更新结果
    """
    try:
        plan_id = req.data.get('planId', '')
        plan_data = req.data.get('planData', {})

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        if not plan_data:
            raise https_fn.HttpsError('invalid-argument', 'planData 不能为空')

        # 验证计划数据
        validation_error = _validate_supplement_plan_data(plan_data)
        if validation_error:
            raise https_fn.HttpsError('invalid-argument', validation_error)

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('supplementPlans').document(plan_id)

        # 检查计划是否存在
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        # 检查权限
        plan_owner_id = plan_doc.to_dict().get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权修改此计划')

        # 更新时间戳
        now = int(time.time() * 1000)

        # 构建更新数据
        update_data = {
            'name': plan_data.get('name', ''),
            'description': plan_data.get('description', ''),
            'days': plan_data.get('days', []),
            'updatedAt': now,
        }

        # 更新 Firestore
        plan_ref.update(update_data)

        logger.info(f'✅ 补剂计划更新成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': plan_id
            },
            'message': '更新成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 更新补剂计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'更新失败: {str(e)}')


def _get_supplement_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    获取补剂计划详情

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        计划详情
    """
    try:
        plan_id = req.data.get('planId', '')

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('supplementPlans').document(plan_id)

        # 获取计划文档
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        plan_data = plan_doc.to_dict()

        # 检查权限
        plan_owner_id = plan_data.get('ownerId', '')
        student_ids = plan_data.get('studentIds', [])

        # 允许计划所有者或被分配的学生查看
        if plan_owner_id != user_id and user_id not in student_ids:
            raise https_fn.HttpsError('permission-denied', '无权查看此计划')

        logger.info(f'✅ 获取补剂计划成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'plan': plan_data
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取补剂计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


def _delete_supplement_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    删除补剂计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        删除结果
    """
    try:
        plan_id = req.data.get('planId', '')

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('supplementPlans').document(plan_id)

        # 检查计划是否存在
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        # 检查权限
        plan_owner_id = plan_doc.to_dict().get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权删除此计划')

        # 删除计划
        plan_ref.delete()

        logger.info(f'✅ 补剂计划删除成功 - ID: {plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': plan_id
            },
            'message': '删除成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 删除补剂计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'删除失败: {str(e)}')


def _list_supplement_plans(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    列出用户的补剂计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        计划列表
    """
    try:
        # 获取 Firestore 实例
        db = firestore.client()

        # 查询用户拥有的计划
        plans_query = db.collection('supplementPlans') \
            .where('ownerId', '==', user_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING)

        plans_docs = plans_query.stream()

        plans = []
        for doc in plans_docs:
            plan_data = doc.to_dict()
            plans.append(plan_data)

        logger.info(f'✅ 获取补剂计划列表成功 - 数量: {len(plans)}')

        return {
            'status': 'success',
            'data': {
                'plans': plans
            }
        }

    except Exception as e:
        logger.error(f'❌ 获取补剂计划列表失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'获取失败: {str(e)}')


def _copy_supplement_plan(req: https_fn.CallableRequest, user_id: str) -> Dict[str, Any]:
    """
    复制补剂计划

    Args:
        req: 请求对象
        user_id: 用户ID

    Returns:
        新计划ID
    """
    try:
        plan_id = req.data.get('planId', '')

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 获取 Firestore 实例
        db = firestore.client()
        plan_ref = db.collection('supplementPlans').document(plan_id)

        # 获取原计划
        plan_doc = plan_ref.get()
        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', '计划不存在')

        original_plan = plan_doc.to_dict()

        # 检查权限（只有所有者可以复制）
        plan_owner_id = original_plan.get('ownerId', '')
        if plan_owner_id != user_id:
            raise https_fn.HttpsError('permission-denied', '无权复制此计划')

        # 创建新的计划文档
        new_plan_ref = db.collection('supplementPlans').document()
        new_plan_id = new_plan_ref.id

        # 构建新计划数据
        now = int(time.time() * 1000)
        new_plan = {
            'id': new_plan_id,
            'name': f"{original_plan.get('name', '')} (副本)",
            'description': original_plan.get('description', ''),
            'days': original_plan.get('days', []),
            'ownerId': user_id,
            'studentIds': [],  # 新计划不继承学生分配
            'createdAt': now,
            'updatedAt': now,
        }

        # 保存新计划
        new_plan_ref.set(new_plan)

        logger.info(f'✅ 补剂计划复制成功 - 原ID: {plan_id}, 新ID: {new_plan_id}')

        return {
            'status': 'success',
            'data': {
                'planId': new_plan_id,
                'plan': new_plan
            },
            'message': '复制成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 复制补剂计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'复制失败: {str(e)}')


def _validate_supplement_plan_data(plan_data: Dict[str, Any]) -> str:
    """
    验证补剂计划数据

    Args:
        plan_data: 计划数据

    Returns:
        错误信息，如果验证通过则返回空字符串
    """
    # 验证名称
    name = plan_data.get('name', '').strip()
    if not name:
        return 'planName 不能为空'

    # 验证补剂日
    days = plan_data.get('days', [])
    if not isinstance(days, list):
        return 'days 必须是数组'

    if len(days) == 0:
        return '至少需要一个补剂日'

    # 验证每个补剂日
    for i, day in enumerate(days):
        if not isinstance(day, dict):
            return f'第 {i+1} 个补剂日数据格式错误'

        timings = day.get('timings', [])
        if not isinstance(timings, list):
            return f'第 {i+1} 个补剂日的 timings 必须是数组'

        if len(timings) == 0:
            return f'第 {i+1} 个补剂日至少需要一个时间段'

        # 验证每个时间段
        for j, timing in enumerate(timings):
            if not isinstance(timing, dict):
                return f'第 {i+1} 个补剂日的第 {j+1} 个时间段数据格式错误'

            timing_name = timing.get('name', '').strip()
            if not timing_name:
                return f'第 {i+1} 个补剂日的第 {j+1} 个时间段名称不能为空'

            supplements = timing.get('supplements', [])
            if not isinstance(supplements, list) or len(supplements) == 0:
                return f'第 {i+1} 个补剂日的第 {j+1} 个时间段至少需要一个补剂'

            # 验证每个补剂
            for k, supplement in enumerate(supplements):
                if not isinstance(supplement, dict):
                    return f'第 {i+1} 个补剂日第 {j+1} 个时间段的第 {k+1} 个补剂数据格式错误'

                supplement_name = supplement.get('name', '').strip()
                if not supplement_name:
                    return f'第 {i+1} 个补剂日第 {j+1} 个时间段的第 {k+1} 个补剂名称不能为空'

                supplement_amount = supplement.get('amount', '').strip()
                if not supplement_amount:
                    return f'第 {i+1} 个补剂日第 {j+1} 个时间段的第 {k+1} 个补剂用量不能为空'

    return ''


# ==================== Student Plan Handlers ====================


@https_fn.on_call()
def get_student_assigned_plans(req: https_fn.CallableRequest):
    """
    获取分配给学生的计划

    学生专用API，返回分配给当前学生的计划（训练、饮食、补剂）
    每类计划只返回一个（取最新分配的）

    返回:
        {
            'status': 'success',
            'data': {
                'exercise_plan': {...} | None,
                'diet_plan': {...} | None,
                'supplement_plan': {...} | None
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        logger.info(f'📚 获取学生计划 - 学生ID: {student_id}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 查询三种计划（筛选 studentIds 包含当前学生）
        exercise_plan = _get_student_assigned_plan(db, student_id, 'exercisePlans')
        diet_plan = _get_student_assigned_plan(db, student_id, 'dietPlans')
        supplement_plan = _get_student_assigned_plan(db, student_id, 'supplementPlans')

        logger.info(f'✅ 获取学生计划成功 - 学生ID: {student_id}, '
                   f'训练:{"有" if exercise_plan else "无"}, '
                   f'饮食:{"有" if diet_plan else "无"}, '
                   f'补剂:{"有" if supplement_plan else "无"}')

        return {
            'status': 'success',
            'data': {
                'exercise_plan': exercise_plan,
                'diet_plan': diet_plan,
                'supplement_plan': supplement_plan
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取学生计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _get_student_assigned_plan(db, student_id: str, collection_name: str):
    """
    获取分配给学生的单个计划（取最新的一个）

    Args:
        db: Firestore 实例
        student_id: 学生ID
        collection_name: 集合名称（exercisePlans, dietPlans, supplementPlans）

    Returns:
        计划数据 或 None（如果没有分配计划）
    """
    try:
        logger.info(f'🔍 开始查询 {collection_name} - 学生ID: {student_id}')

        # 查询 studentIds 包含当前学生ID的计划
        plans_query = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING) \
            .limit(1) \
            .get()

        # 转换为列表以获取结果数量
        results = list(plans_query)
        logger.info(f'🔍 查询返回文档数量: {len(results)}')

        # 如果找到计划，返回第一个（最新的）
        if results:
            for plan_doc in results:
                plan_data = plan_doc.to_dict()
                plan_data['id'] = plan_doc.id
                logger.info(f'📋 找到学生计划: {collection_name}, ID: {plan_doc.id}')
                logger.info(f'📋 计划的 studentIds: {plan_data.get("studentIds", [])}')
                return plan_data

        # 没有找到计划
        logger.info(f'📋 学生无计划: {collection_name}')
        return None

    except Exception as e:
        logger.error(f'❌ 查询学生计划失败: {collection_name}, 错误: {str(e)}', exc_info=True)
        return None


@https_fn.on_call()
def get_student_all_plans(req: https_fn.CallableRequest):
    """
    获取学生所有可见计划（包括教练分配的和自己创建的）

    返回:
        {
            'status': 'success',
            'data': {
                'exercise_plans': [...],
                'diet_plans': [...],
                'supplement_plans': [...]
            }
        }
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        student_id = req.auth.uid

        logger.info(f'📚 获取学生所有计划 - 学生ID: {student_id}')

        # 获取 Firestore 实例
        db = firestore.client()

        # 查询三种计划（教练分配 + 自己创建）
        exercise_plans = _get_student_all_plans_by_type(db, student_id, 'exercisePlans')
        diet_plans = _get_student_all_plans_by_type(db, student_id, 'dietPlans')
        supplement_plans = _get_student_all_plans_by_type(db, student_id, 'supplementPlans')

        logger.info(f'✅ 获取学生所有计划成功 - 学生ID: {student_id}, '
                   f'训练:{len(exercise_plans)}, 饮食:{len(diet_plans)}, 补剂:{len(supplement_plans)}')

        return {
            'status': 'success',
            'data': {
                'exercise_plans': exercise_plans,
                'diet_plans': diet_plans,
                'supplement_plans': supplement_plans
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 获取学生所有计划失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _get_student_all_plans_by_type(db, student_id: str, collection_name: str):
    """
    获取学生某一类型的所有计划（教练分配 + 自己创建）

    Args:
        db: Firestore 实例
        student_id: 学生ID
        collection_name: 集合名称（exercisePlans, dietPlans, supplementPlans）

    Returns:
        计划列表
    """
    try:
        plans = []

        # 查询1: studentIds 包含当前学生ID的计划（教练分配的）
        assigned_query = db.collection(collection_name) \
            .where('studentIds', 'array_contains', student_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING) \
            .get()

        for plan_doc in assigned_query:
            plan_data = plan_doc.to_dict()
            plan_data['id'] = plan_doc.id
            plans.append(plan_data)

        # 查询2: ownerId 等于当前学生ID的计划（自己创建的）
        owned_query = db.collection(collection_name) \
            .where('ownerId', '==', student_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING) \
            .get()

        # 去重：避免同一个计划被添加两次（如果学生既是owner又在studentIds中）
        existing_ids = {plan['id'] for plan in plans}
        for plan_doc in owned_query:
            if plan_doc.id not in existing_ids:
                plan_data = plan_doc.to_dict()
                plan_data['id'] = plan_doc.id
                plans.append(plan_data)

        logger.info(f'📋 获取学生计划成功: {collection_name}, 数量: {len(plans)}')
        return plans

    except Exception as e:
        logger.error(f'❌ 获取学生计划失败: {collection_name}, 错误: {str(e)}', exc_info=True)
        return []


@https_fn.on_call()
def assign_plan(req: https_fn.CallableRequest):
    """
    分配或取消分配计划给学生

    请求参数:
        - action: str, 操作类型 ('assign' | 'unassign')
        - planType: str, 计划类型 ('exercise' | 'diet' | 'supplement')
        - planId: str, 计划ID
        - studentIds: list[str], 学生ID列表

    返回:
        {
            'status': 'success' | 'error',
            'message': str,
            'data': {
                'updated_count': int  # 更新的学生数量
            }
        }
    """
    try:
        # 验证用户登录
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid

        # 验证用户是教练
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists or user_doc.to_dict().get('role') != 'coach':
            raise https_fn.HttpsError(
                'permission-denied',
                '只有教练才能分配计划'
            )

        # 获取参数
        action = req.data.get('action', '').lower()
        plan_type = req.data.get('planType', '').lower()
        plan_id = req.data.get('planId')
        student_ids = req.data.get('studentIds', [])

        # 验证参数
        if action not in ['assign', 'unassign']:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'无效的操作类型: {action}，必须是 assign 或 unassign'
            )

        if plan_type not in ['exercise', 'diet', 'supplement']:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'无效的计划类型: {plan_type}，必须是 exercise, diet 或 supplement'
            )

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        if not student_ids or not isinstance(student_ids, list):
            raise https_fn.HttpsError(
                'invalid-argument',
                'studentIds 必须是非空列表'
            )

        logger.info(
            f'📋 计划分配操作 - 教练: {user_id}, 操作: {action}, '
            f'类型: {plan_type}, 计划: {plan_id}, 学生: {len(student_ids)}个'
        )

        # 获取计划集合名称
        collection_name = _get_collection_name(plan_type)

        # 验证计划存在且属于当前教练
        plan_ref = db.collection(collection_name).document(plan_id)
        plan_doc = plan_ref.get()

        if not plan_doc.exists:
            raise https_fn.HttpsError('not-found', f'计划不存在: {plan_id}')

        plan_data = plan_doc.to_dict()
        if plan_data.get('ownerId') != user_id:
            raise https_fn.HttpsError(
                'permission-denied',
                '您没有权限操作此计划'
            )

        # 验证所有学生都属于当前教练
        for student_id in student_ids:
            student_doc = db.collection('users').document(student_id).get()
            if not student_doc.exists:
                raise https_fn.HttpsError(
                    'not-found',
                    f'学生不存在: {student_id}'
                )

            student_data = student_doc.to_dict()
            if student_data.get('coachId') != user_id:
                raise https_fn.HttpsError(
                    'permission-denied',
                    f'学生 {student_id} 不属于您'
                )

        # 执行分配或取消分配
        if action == 'assign':
            # 使用 arrayUnion 添加学生ID
            plan_ref.update({
                'studentIds': firestore.ArrayUnion(student_ids),
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            logger.info(f'✅ 分配成功: {len(student_ids)}个学生添加到计划 {plan_id}')
        else:
            # 使用 arrayRemove 移除学生ID
            plan_ref.update({
                'studentIds': firestore.ArrayRemove(student_ids),
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            logger.info(f'✅ 取消分配成功: {len(student_ids)}个学生从计划 {plan_id} 移除')

        return {
            'status': 'success',
            'message': f'{"分配" if action == "assign" else "取消分配"}成功',
            'data': {
                'updated_count': len(student_ids)
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'❌ 计划分配操作失败: {str(e)}', exc_info=True)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


def _get_collection_name(plan_type: str) -> str:
    """
    根据计划类型获取Firestore集合名称

    Args:
        plan_type: 计划类型 ('exercise', 'diet', 'supplement')

    Returns:
        集合名称
    """
    collection_map = {
        'exercise': 'exercisePlans',
        'diet': 'dietPlans',
        'supplement': 'supplementPlans'
    }
    return collection_map.get(plan_type, 'exercisePlans')



