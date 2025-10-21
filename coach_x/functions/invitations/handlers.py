"""
邀请码相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger, db_helper
from .models import InvitationCodeModel
import random
import string


@https_fn.on_call()
def verify_invitation_code(req: https_fn.CallableRequest):
    """
    验证邀请码
    
    请求参数:
        - code: 邀请码
    
    返回:
        - status: 状态码
        - valid: 是否有效
        - coachId: 教练ID (如果有效)
    """
    try:
        code = req.data.get('code')
        
        if not code:
            raise https_fn.HttpsError('invalid-argument', '邀请码不能为空')
        
        # 查询邀请码
        codes = db_helper.query_documents(
            'invitationCodes',
            filters=[('code', '==', code)],
            limit=1
        )
        
        if not codes:
            return {
                'status': 'success',
                'valid': False,
                'message': '邀请码无效'
            }
        
        code_doc = codes[0]
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
            now = firestore.SERVER_TIMESTAMP
            if expires_at < now:
                return {
                    'status': 'success',
                    'valid': False,
                    'message': '邀请码已过期'
                }
        
        logger.info(f'邀请码验证成功: {code}')
        
        return {
            'status': 'success',
            'valid': True,
            'coachId': code_data.get('coachId'),
            'codeId': code_doc.id,  # 返回文档ID用于后续标记使用
            'message': '邀请码有效'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'验证邀请码失败', e)
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
        user_doc = db_helper.get_document('users', user_id)
        
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
        codes = []
        db = firestore.client()
        batch = db.batch()
        
        for _ in range(count):
            # 生成8位随机码
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            
            # 创建邀请码模型
            code_model = InvitationCodeModel(code=code, coach_id=user_id)
            
            code_ref = db.collection('invitationCodes').document()
            code_dict = code_model.to_dict()
            code_dict['createdAt'] = firestore.SERVER_TIMESTAMP
            batch.set(code_ref, code_dict)
            
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
        logger.error(f'生成邀请码失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def mark_invitation_code_used(req: https_fn.CallableRequest):
    """
    标记邀请码已使用
    
    请求参数:
        - codeId: 邀请码文档ID
        - studentId: 学生ID
    
    返回:
        - status: 状态码
        - message: 消息
    """
    try:
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        code_id = req.data.get('codeId')
        student_id = req.data.get('studentId', req.auth.uid)
        
        if not code_id:
            raise https_fn.HttpsError('invalid-argument', '邀请码ID不能为空')
        
        # 更新邀请码状态
        db_helper.update_document('invitationCodes', code_id, {
            'used': True,
            'usedBy': student_id
        })
        
        logger.info(f'邀请码标记为已使用: {code_id} by {student_id}')
        
        return {
            'status': 'success',
            'message': '邀请码已标记为使用'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'标记邀请码失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')

