"""
用户相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger, validators, db_helper
from utils.param_parser import parse_float_param
from .models import UserModel, UserLLMProfile
from ai.memory_manager import MemoryManager


# ==================== Firestore触发器 ====================
# 注意：暂时注释掉Firestore触发器，因为首次使用2nd gen functions需要等待Eventarc权限传播
# 可以在权限配置完成后重新启用

# @firestore_fn.on_document_created(document="users/{userId}")
# def on_user_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]):
#     """
#     用户文档创建后的触发器
#     可用于发送欢迎邮件等后续逻辑
#     """
#     try:
#         user_id = event.params['userId']
#         logger.info(f'新用户文档创建: {user_id}')
#         
#         # TODO: 可以在这里添加用户创建后的初始化逻辑
#         # 例如：创建默认设置、发送欢迎邮件等
#         
#         return None
#         
#     except Exception as e:
#         logger.error(f'用户创建触发器失败', e)
#         return None


# ==================== HTTP Callable Functions ====================

@https_fn.on_call()
def create_user_document(req: https_fn.CallableRequest):
    """
    创建用户Firestore文档
    
    请求参数:
        - uid: 用户ID (可选，默认为当前用户)
        - email: 邮箱
        - name: 姓名 (可选)
    
    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        user_id = req.data.get('uid', req.auth.uid)
        email = req.data.get('email', req.auth.token.get('email', ''))
        name = req.data.get('name', '')
        
        # 只能为自己创建文档
        if user_id != req.auth.uid:
            raise https_fn.HttpsError('permission-denied', '只能为自己创建用户文档')
        
        # 检查用户文档是否已存在
        user_doc = db_helper.get_document('users', user_id)
        if user_doc.exists:
            logger.info(f'用户文档已存在: {user_id}')
            return {
                'status': 'success',
                'message': '用户文档已存在'
            }
        
        # 创建用户模型
        user_model = UserModel(
            user_id=user_id,
            email=email,
            name=name,
            role='student'  # 默认角色为学生
        )
        
        # 创建Firestore用户文档
        db_helper.create_document('users', user_id, user_model.to_dict())
        
        logger.info(f'用户文档创建成功: {user_id}')
        
        return {
            'status': 'success',
            'message': '用户文档创建成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'创建用户文档失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def fetch_user_info(req: https_fn.CallableRequest):
    """
    获取用户信息
    
    请求参数:
        - user_id: 用户ID (可选，默认为当前用户)
    
    返回:
        - status: 状态码
        - data: 用户信息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        # 获取用户ID
        user_id = req.data.get('user_id', req.auth.uid)
        
        # 只能查询自己的信息（权限检查）
        if user_id != req.auth.uid:
            raise https_fn.HttpsError('permission-denied', '无权访问其他用户信息')
        
        # 从Firestore获取用户信息
        user_doc = db_helper.get_document('users', user_id)
        
        if not user_doc.exists:
            raise https_fn.HttpsError('not-found', '用户不存在')
        
        user_data = user_doc.to_dict()
        
        logger.info(f'用户信息查询成功: {user_id}')
        
        return {
            'status': 'success',
            'data': user_data
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'获取用户信息失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def update_user_info(req: https_fn.CallableRequest):
    """
    更新用户信息
    
    请求参数:
        - name: 用户名 (可选)
        - avatarUrl: 头像URL (可选)
        - role: 角色 (可选)
        - gender: 性别 (可选)
        - bornDate: 出生日期 (可选, 格式: "yyyy-MM-dd")
        - height: 身高 (可选, 单位: cm)
        - initialWeight: 体重 (可选, 单位: kg)
        - coachId: 教练ID (可选, 仅学生)
    
    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        user_id = req.auth.uid
        update_data = {}
        
        # 只更新提供的字段
        if 'name' in req.data:
            update_data['name'] = req.data['name']
        
        if 'avatarUrl' in req.data:
            update_data['avatarUrl'] = req.data['avatarUrl']
        
        if 'role' in req.data:
            role = req.data['role']
            validators.validate_role(role)
            update_data['role'] = role
        
        if 'gender' in req.data:
            gender = req.data['gender']
            validators.validate_gender(gender)
            update_data['gender'] = gender
        
        if 'bornDate' in req.data:
            update_data['bornDate'] = req.data['bornDate']

        if 'height' in req.data:
            update_data['height'] = parse_float_param(req.data['height'])

        if 'initialWeight' in req.data:
            update_data['initialWeight'] = parse_float_param(req.data['initialWeight'])
        
        if 'coachId' in req.data:
            update_data['coachId'] = req.data['coachId']

        if 'languageCode' in req.data:
            language_code = req.data['languageCode']
            # 验证语言代码格式（可选：en, zh, en_US, zh_CN等）
            if language_code and not isinstance(language_code, str):
                raise https_fn.HttpsError('invalid-argument', 'languageCode 必须是字符串')
            update_data['languageCode'] = language_code

        # Active plan IDs
        if 'activeExercisePlanId' in req.data:
            update_data['activeExercisePlanId'] = req.data['activeExercisePlanId']

        if 'activeDietPlanId' in req.data:
            update_data['activeDietPlanId'] = req.data['activeDietPlanId']

        if 'activeSupplementPlanId' in req.data:
            update_data['activeSupplementPlanId'] = req.data['activeSupplementPlanId']

        if not update_data:
            raise https_fn.HttpsError('invalid-argument', '没有要更新的数据')
        
        # 更新Firestore
        db_helper.update_document('users', user_id, update_data)
        
        logger.info(f'用户信息更新成功: {user_id}')
        
        return {
            'status': 'success',
            'message': '用户信息更新成功'
        }
    
    except https_fn.HttpsError:
        raise
    except ValueError as e:
        raise https_fn.HttpsError('invalid-argument', str(e))
    except Exception as e:
        logger.error(f'更新用户信息失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== LLM Memory 相关 ====================

@https_fn.on_call()
def get_user_llm_profile(req: https_fn.CallableRequest):
    """
    获取用户 LLM Profile
    
    请求参数:
        无（使用当前登录用户）
    
    返回:
        - status: 状态码
        - data: LLM Profile 数据
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        user_id = req.auth.uid
        
        # 获取 LLM Profile
        profile = MemoryManager.get_user_memory(user_id)
        
        logger.info(f'获取用户 LLM Profile 成功: {user_id}')
        
        return {
            'status': 'success',
            'data': profile.to_dict()
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'获取用户 LLM Profile 失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def update_user_preferences(req: https_fn.CallableRequest):
    """
    更新用户训练偏好
    
    请求参数:
        - preferences: dict, 偏好字典
            - preferred_exercises: list (可选)
            - avoided_exercises: list (可选)
            - intensity_preference: str (可选)
            - equipment_preference: list (可选)
            - training_style: list (可选)
            - common_goals: list (可选)
    
    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        user_id = req.auth.uid
        preferences = req.data.get('preferences', {})
        
        if not preferences:
            raise https_fn.HttpsError('invalid-argument', 'preferences 不能为空')
        
        # 更新偏好
        success = MemoryManager.update_preferences(user_id, preferences)
        
        if not success:
            raise https_fn.HttpsError('internal', '更新偏好失败')
        
        logger.info(f'更新用户偏好成功: {user_id}')
        
        return {
            'status': 'success',
            'message': '偏好更新成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'更新用户偏好失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def clear_conversation_history(req: https_fn.CallableRequest):
    """
    清空对话历史

    请求参数:
        无（使用当前登录用户）

    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid

        # 清空对话历史
        success = MemoryManager.clear_conversation_history(user_id)

        if not success:
            raise https_fn.HttpsError('internal', '清空对话历史失败')

        logger.info(f'清空对话历史成功: {user_id}')

        return {
            'status': 'success',
            'message': '对话历史已清空'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'清空对话历史失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def update_active_plan(req: https_fn.CallableRequest):
    """
    更新学生的 active plan ID

    请求参数:
        - planType: str, 计划类型 ('exercise' | 'diet' | 'supplement')
        - planId: str, 计划ID

    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        user_id = req.auth.uid
        plan_type = req.data.get('planType', '').lower()
        plan_id = req.data.get('planId')

        # 验证参数
        if plan_type not in ['exercise', 'diet', 'supplement']:
            raise https_fn.HttpsError(
                'invalid-argument',
                f'无效的计划类型: {plan_type}，必须是 exercise, diet 或 supplement'
            )

        if not plan_id:
            raise https_fn.HttpsError('invalid-argument', 'planId 不能为空')

        # 映射字段名
        field_map = {
            'exercise': 'activeExercisePlanId',
            'diet': 'activeDietPlanId',
            'supplement': 'activeSupplementPlanId'
        }

        field_name = field_map[plan_type]

        # 更新用户文档
        update_data = {field_name: plan_id}
        db_helper.update_document('users', user_id, update_data)

        logger.info(f'更新 Active Plan 成功: user={user_id}, type={plan_type}, planId={plan_id}')

        return {
            'status': 'success',
            'message': 'Active plan 更新成功'
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'更新 Active Plan 失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')

