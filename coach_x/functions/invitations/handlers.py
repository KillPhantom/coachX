"""
邀请码相关Cloud Functions处理器
"""
from firebase_functions import https_fn
from firebase_admin import firestore
from utils import logger, db_helper
from utils.param_parser import parse_int_param
from .models import InvitationCodeModel
import random
import string

# 测试模式开关 - 设为True返回假数据，方便前端测试
USE_FAKE_DATA = False


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
        - total_days: 签约总时长（天数，默认180天）
        - note: 备注 (可选)
    
    返回:
        - status: 状态码
        - codes: 邀请码列表
        - code_ids: 邀请码ID列表
    """
    try:
        # ========== 测试模式：返回模拟生成的邀请码 ==========
        if USE_FAKE_DATA:
            count = req.data.get('count', 1)
            total_days = req.data.get('total_days', 180)
            note = req.data.get('note', '').strip()
            
            codes = []
            code_ids = []
            for i in range(count):
                # 生成随机码
                code = '-'.join([
                    ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
                    for _ in range(3)
                ])
                codes.append(code)
                code_ids.append(f'fake_code_id_{i+1}')
            
            logger.info(f'[测试模式] 模拟生成{count}个邀请码，天数: {total_days}，备注: {note}')
            
            return {
                'status': 'success',
                'codes': codes,
                'code_ids': code_ids,
                'message': f'成功生成{count}个邀请码'
            }
        # ========== 生产模式：真实数据库操作 ==========
        
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
        
        # 获取参数（处理 Protobuf 包装）
        count = parse_int_param(req.data.get('count'), 1)
        total_days = parse_int_param(req.data.get('total_days'), 180)
        note = req.data.get('note', '').strip()
        
        # 参数验证
        if count < 1 or count > 10:
            raise https_fn.HttpsError('invalid-argument', '生成数量必须在1-10之间')
        if total_days < 1 or total_days > 365:
            raise https_fn.HttpsError('invalid-argument', '签约天数必须在1-365之间')
        
        # 生成邀请码
        codes = []
        code_ids = []
        db = firestore.client()
        batch = db.batch()
        
        import datetime
        # 邀请码30天内有效（使用UTC时间）
        expires_at = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=30)
        
        for _ in range(count):
            # 生成12位随机码（格式: XXXX-XXXX-XXXX）
            code = '-'.join([
                ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
                for _ in range(3)
            ])
            
            # 创建邀请码模型
            code_model = InvitationCodeModel(
                code=code,
                coach_id=user_id,
                total_days=total_days,
                note=note
            )
            code_model.expiresAt = expires_at
            
            code_ref = db.collection('invitationCodes').document()
            code_dict = code_model.to_dict()
            code_dict['createdAt'] = firestore.SERVER_TIMESTAMP
            batch.set(code_ref, code_dict)
            
            codes.append(code)
            code_ids.append(code_ref.id)
        
        # 批量提交
        batch.commit()
        
        logger.info(f'生成邀请码成功: {user_id}, 数量: {count}, 天数: {total_days}')
        
        return {
            'status': 'success',
            'codes': codes,
            'code_ids': code_ids,
            'message': f'成功生成{count}个邀请码'
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'生成邀请码失败', e)
        raise https_fn.HttpsError('internal', f'服务器错误: {str(e)}')


@https_fn.on_call()
def fetch_invitation_codes(req: https_fn.CallableRequest):
    """
    获取教练的邀请码列表
    
    返回:
        - status: 状态码
        - data:
            - codes: 邀请码列表
    """
    try:
        # ========== 测试模式：返回假数据 ==========
        if USE_FAKE_DATA:
            logger.info('[测试模式] 返回假邀请码列表')
            fake_codes = _generate_fake_invitation_codes()
            return {
                'status': 'success',
                'data': {
                    'codes': fake_codes
                }
            }
        # ========== 生产模式：真实数据库查询 ==========
        
        # 检查认证
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')
        
        coach_id = req.auth.uid
        
        # 验证教练身份
        user_doc = db_helper.get_document('users', coach_id)
        if not user_doc.exists or user_doc.to_dict().get('role') != 'coach':
            raise https_fn.HttpsError('permission-denied', '只有教练可以查看邀请码')
        
        # 查询邀请码（直接使用Firestore API以支持排序）
        db = firestore.client()
        codes = db.collection('invitationCodes') \
            .where('coachId', '==', coach_id) \
            .order_by('createdAt', direction=firestore.Query.DESCENDING) \
            .get()
        
        import datetime
        codes_data = []
        for code_doc in codes:
            code_data = code_doc.to_dict()
            
            # 计算剩余天数
            expires_at = code_data.get('expiresAt')
            expires_in_days = 0
            if expires_at:
                # 将Firestore Timestamp转换为datetime对象
                if hasattr(expires_at, 'timestamp'):
                    # Firestore Timestamp对象 -> datetime (UTC)
                    expires_dt = datetime.datetime.fromtimestamp(
                        expires_at.timestamp(), 
                        tz=datetime.timezone.utc
                    )
                else:
                    # 已经是datetime对象，确保是UTC时区
                    expires_dt = expires_at
                    if expires_dt.tzinfo is None:
                        expires_dt = expires_dt.replace(tzinfo=datetime.timezone.utc)
                
                # 计算剩余天数（使用UTC时间）
                now = datetime.datetime.now(datetime.timezone.utc)
                delta = expires_dt - now
                expires_in_days = max(0, delta.days)
            
            codes_data.append({
                'id': code_doc.id,
                'code': code_data.get('code', ''),
                'coachId': code_data.get('coachId', ''),
                'totalDays': code_data.get('totalDays', 180),
                'note': code_data.get('note', ''),
                'used': code_data.get('used', False),
                'usedBy': code_data.get('usedBy'),
                'createdAt': code_data.get('createdAt'),
                'expiresAt': code_data.get('expiresAt'),
                'expiresInDays': expires_in_days
            })
        
        logger.info(f'查询邀请码成功: coach_id={coach_id}, count={len(codes_data)}')
        
        return {
            'status': 'success',
            'data': {
                'codes': codes_data
            }
        }
    
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logger.error(f'查询邀请码失败', e)
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
        # ========== 测试模式：直接返回成功 ==========
        if USE_FAKE_DATA:
            code_id = req.data.get('codeId')
            student_id = req.data.get('studentId', req.auth.uid if req.auth else 'fake_student')
            logger.info(f'[测试模式] 模拟标记邀请码: {code_id} by {student_id}')
            return {
                'status': 'success',
                'message': '邀请码已标记为使用'
            }
        # ========== 生产模式：真实数据库操作 ==========
        
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


def _generate_fake_invitation_codes():
    """生成假邀请码数据用于测试"""
    import datetime
    import random
    
    codes = []
    statuses = [
        {'used': False, 'expires_in_days': 25, 'note': '新学员专用'},
        {'used': False, 'expires_in_days': 15, 'note': '春季促销'},
        {'used': True, 'expires_in_days': 0, 'note': '已使用'},
        {'used': False, 'expires_in_days': 28, 'note': ''},
        {'used': False, 'expires_in_days': 5, 'note': '即将过期'},
        {'used': False, 'expires_in_days': 30, 'note': '180天套餐'},
        {'used': True, 'expires_in_days': 0, 'note': '已被张三使用'},
        {'used': False, 'expires_in_days': 20, 'note': '90天套餐'},
    ]
    
    for i, status in enumerate(statuses):
        code_str = '-'.join([
            ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
            for _ in range(3)
        ])
        
        # 使用UTC时间
        created_at = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=random.randint(1, 10))
        expires_at = created_at + datetime.timedelta(days=30)
        
        code = {
            'id': f'code_{i+1}',
            'code': code_str,
            'coachId': 'coach_test_001',
            'totalDays': 180 if 'note' in status and '180' in status['note'] else 90,
            'note': status['note'],
            'used': status['used'],
            'usedBy': f'student_{i}' if status['used'] else None,
            'createdAt': created_at.isoformat(),
            'expiresAt': expires_at.isoformat(),
            'expiresInDays': status['expires_in_days']
        }
        codes.append(code)
    
    return codes

