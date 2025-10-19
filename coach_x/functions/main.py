# CoachX Cloud Functions (Python)
# 
# Firebase Functions for CoachX AI教练学生管理平台

from firebase_functions import https_fn, options
from firebase_admin import initialize_app, firestore, auth
import logging

# 初始化Firebase Admin
initialize_app()

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 全局配置
options.set_global_options(max_instances=10)

# ==================== 用户管理 ====================

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
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        
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
        logger.error(f'获取用户信息失败: {str(e)}')
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def update_user_info(req: https_fn.CallableRequest):
    """
    更新用户信息
    
    请求参数:
        - name: 用户名 (可选)
        - avatar_url: 头像URL (可选)
    
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
        if 'avatar_url' in req.data:
            update_data['avatarUrl'] = req.data['avatar_url']
        
        if not update_data:
            raise https_fn.HttpsError('invalid-argument', '没有要更新的数据')
        
        # 添加更新时间
        update_data['updatedAt'] = firestore.SERVER_TIMESTAMP
        
        # 更新Firestore
        db = firestore.client()
        db.collection('users').document(user_id).update(update_data)
        
        logger.info(f'用户信息更新成功: {user_id}')
        
        return {
            'status': 'success',
            'message': '用户信息更新成功'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'更新用户信息失败: {str(e)}')
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== 邀请码管理 ====================

@https_fn.on_call()
def verify_invitation_code(req: https_fn.CallableRequest):
    """
    验证邀请码
    
    请求参数:
        - code: 邀请码
    
    返回:
        - status: 状态码
        - valid: 是否有效
        - coach_id: 教练ID (如果有效)
    """
    try:
        code = req.data.get('code')
        
        if not code:
            raise https_fn.HttpsError('invalid-argument', '邀请码不能为空')
        
        # 查询邀请码
        db = firestore.client()
        codes_ref = db.collection('invitationCodes')
        query = codes_ref.where('code', '==', code).limit(1).get()
        
        if not query:
            return {
                'status': 'success',
                'valid': False,
                'message': '邀请码无效'
            }
        
        code_doc = query[0]
        code_data = code_doc.to_dict()
        
        # 检查邀请码状态
        if code_data.get('used', False):
            return {
                'status': 'success',
                'valid': False,
                'message': '邀请码已被使用'
            }
        
        # 检查是否过期
        if code_data.get('expiresAt'):
            expires_at = code_data['expiresAt']
            if expires_at < firestore.SERVER_TIMESTAMP:
                return {
                    'status': 'success',
                    'valid': False,
                    'message': '邀请码已过期'
                }
        
        logger.info(f'邀请码验证成功: {code}')
        
        return {
            'status': 'success',
            'valid': True,
            'coach_id': code_data.get('coachId'),
            'message': '邀请码有效'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'验证邀请码失败: {str(e)}')
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def generate_invitation_codes(req: https_fn.CallableRequest):
    """
    生成邀请码（教练专用）
    
    请求参数:
        - count: 生成数量 (默认1，最大10)
    
    返回:
        - status: 状态码
        - codes: 邀请码列表
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        user_id = req.auth.uid
        
        # 验证用户角色
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            raise https_fn.HttpsError('not-found', '用户不存在')
        
        user_data = user_doc.to_dict()
        if user_data.get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以生成邀请码')
        
        # 获取生成数量
        count = req.data.get('count', 1)
        if count < 1 or count > 10:
            raise https_fn.HttpsError('invalid-argument', '生成数量必须在1-10之间')
        
        # 生成邀请码
        import random
        import string
        
        codes = []
        batch = db.batch()
        
        for _ in range(count):
            # 生成8位随机码
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            
            code_ref = db.collection('invitationCodes').document()
            batch.set(code_ref, {
                'code': code,
                'coachId': user_id,
                'used': False,
                'usedBy': None,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'expiresAt': None  # 不设置过期时间
            })
            
            codes.append(code)
        
        # 批量提交
        batch.commit()
        
        logger.info(f'生成邀请码成功: {user_id}, 数量: {count}')
        
        return {
            'status': 'success',
            'codes': codes,
            'message': f'成功生成{count}个邀请码'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'生成邀请码失败: {str(e)}')
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


# ==================== Firestore触发器 ====================

@https_fn.on_document_created(document="users/{userId}")
def on_user_created(event: https_fn.CloudEvent):
    """
    用户创建时的触发器
    
    自动初始化用户相关数据
    """
    try:
        user_id = event.params['userId']
        logger.info(f'新用户创建: {user_id}')
        
        # TODO: 可以在这里添加用户创建后的初始化逻辑
        # 例如：创建默认设置、发送欢迎邮件等
        
    except Exception as e:
        logger.error(f'用户创建触发器失败: {str(e)}')
