"""
Chat Cloud Functions 处理器
"""

from firebase_functions import https_fn
from firebase_admin import firestore
from typing import Dict, Any
import time

from utils.param_parser import parse_int_param
from .models import MessageModel, ConversationModel


@https_fn.on_call()
def send_message(req: https_fn.CallableRequest):
    """
    发送消息

    请求参数:
        - conversationId: str
        - senderId: str
        - receiverId: str
        - type: str ('text' | 'image' | 'video' | 'voice')
        - content: str
        - mediaUrl: str (optional)
        - mediaMetadata: dict (optional)
    """
    try:
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        data = req.data
        user_id = req.auth.uid

        # 验证参数
        required_fields = ['conversationId', 'receiverId', 'type', 'content']
        for field in required_fields:
            if field not in data:
                raise https_fn.HttpsError('invalid-argument', f'缺少必需参数: {field}')

        # 创建消息
        db = firestore.client()
        message_ref = db.collection('messages').document()

        message = MessageModel(
            message_id=message_ref.id,
            conversation_id=data['conversationId'],
            sender_id=user_id,
            receiver_id=data['receiverId'],
            message_type=data['type'],
            content=data['content'],
            media_url=data.get('mediaUrl'),
            media_metadata=data.get('mediaMetadata')
        )

        # 保存消息
        message_ref.set(message.to_dict())

        # 更新conversation
        conv_ref = db.collection('conversations').document(data['conversationId'])
        conv_doc = conv_ref.get()

        if conv_doc.exists:
            conv_data = conv_doc.to_dict()

            # 更新lastMessage
            last_message = {
                'id': message.id,
                'content': message.content,
                'type': message.type,
                'senderId': message.sender_id,
                'timestamp': message.created_at
            }
            if message.media_url:
                last_message['mediaUrl'] = message.media_url

            # 增加接收者的未读数
            updates = {
                'lastMessage': last_message,
                'lastMessageTime': message.created_at,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }

            # 判断是教练发送还是学生发送
            if user_id == conv_data.get('coachId'):
                updates['studentUnreadCount'] = firestore.Increment(1)
            else:
                updates['coachUnreadCount'] = firestore.Increment(1)

            conv_ref.update(updates)

        return {
            'status': 'success',
            'data': {
                'messageId': message.id,
                'createdAt': message.created_at,
                'status': message.status
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        raise https_fn.HttpsError('internal', f'发送消息失败: {str(e)}')


@https_fn.on_call()
def fetch_messages(req: https_fn.CallableRequest):
    """
    获取对话消息历史

    请求参数:
        - conversationId: str
        - limit: int (optional, default 50)
        - beforeTimestamp: int (optional)
    """
    try:
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        data = req.data
        conversation_id = data.get('conversationId')

        if not conversation_id:
            raise https_fn.HttpsError('invalid-argument', '缺少conversationId')

        db = firestore.client()
        query = db.collection('messages').where('conversationId', '==', conversation_id)

        # 添加时间过滤（用于加载更多）
        if 'beforeTimestamp' in data:
            before_ts = parse_int_param(data['beforeTimestamp'])
            if before_ts is not None:
                query = query.where('createdAt', '<', before_ts)

        # 排序和限制（处理 Protobuf 包装）
        limit = parse_int_param(data.get('limit'), 50)
        query = query.order_by('createdAt', direction=firestore.Query.DESCENDING).limit(limit)

        messages = []
        docs = query.stream()

        for doc in docs:
            message_data = doc.to_dict()
            message_data['id'] = doc.id
            messages.append(message_data)

        return {
            'status': 'success',
            'data': {
                'messages': messages,
                'hasMore': len(messages) == limit
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        raise https_fn.HttpsError('internal', f'获取消息失败: {str(e)}')


@https_fn.on_call()
def mark_messages_as_read(req: https_fn.CallableRequest):
    """
    标记消息为已读

    请求参数:
        - conversationId: str
        - lastReadTimestamp: int
    """
    try:
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        data = req.data
        user_id = req.auth.uid
        conversation_id = data.get('conversationId')
        last_read_timestamp = data.get('lastReadTimestamp', int(time.time() * 1000))

        if not conversation_id:
            raise https_fn.HttpsError('invalid-argument', '缺少conversationId')

        db = firestore.client()
        conv_ref = db.collection('conversations').document(conversation_id)
        conv_doc = conv_ref.get()

        if not conv_doc.exists:
            raise https_fn.HttpsError('not-found', '对话不存在')

        conv_data = conv_doc.to_dict()

        # 确定当前用户是教练还是学生
        is_coach = user_id == conv_data.get('coachId')

        # 更新conversation
        updates = {
            'updatedAt': firestore.SERVER_TIMESTAMP
        }

        if is_coach:
            updates['coachUnreadCount'] = 0
            updates['coachLastReadTime'] = last_read_timestamp
        else:
            updates['studentUnreadCount'] = 0
            updates['studentLastReadTime'] = last_read_timestamp

        conv_ref.update(updates)

        # 批量更新消息状态为read
        messages_query = db.collection('messages').where(
            'conversationId', '==', conversation_id
        ).where(
            'receiverId', '==', user_id
        ).where(
            'createdAt', '<=', last_read_timestamp
        ).where(
            'status', '!=', 'read'
        )

        batch = db.batch()
        count = 0

        for doc in messages_query.stream():
            batch.update(doc.reference, {
                'status': 'read',
                'readAt': last_read_timestamp
            })
            count += 1

            # Firestore batch最多500个操作
            if count >= 500:
                batch.commit()
                batch = db.batch()
                count = 0

        if count > 0:
            batch.commit()

        return {
            'status': 'success',
            'data': {
                'unreadCount': 0
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        raise https_fn.HttpsError('internal', f'标记已读失败: {str(e)}')


@https_fn.on_call()
def get_or_create_conversation(req: https_fn.CallableRequest):
    """
    获取或创建对话

    请求参数:
        - coachId: str
        - studentId: str
    """
    try:
        if not req.auth:
            raise https_fn.HttpsError('unauthenticated', '用户未登录')

        data = req.data
        coach_id = data.get('coachId')
        student_id = data.get('studentId')

        if not coach_id or not student_id:
            raise https_fn.HttpsError('invalid-argument', '缺少coachId或studentId')

        db = firestore.client()
        conversation_id = ConversationModel.generate_conversation_id(coach_id, student_id)
        conv_ref = db.collection('conversations').document(conversation_id)
        conv_doc = conv_ref.get()

        existed = conv_doc.exists

        if not existed:
            # 获取教练和学生的基本信息
            coach_doc = db.collection('users').document(coach_id).get()
            student_doc = db.collection('users').document(student_id).get()

            coach_data = coach_doc.to_dict() if coach_doc.exists else {}
            student_data = student_doc.to_dict() if student_doc.exists else {}

            # 创建新对话
            conversation = ConversationModel(
                conversation_id=conversation_id,
                coach_id=coach_id,
                student_id=student_id,
                coach_name=coach_data.get('name', ''),
                student_name=student_data.get('name', ''),
                coach_avatar_url=coach_data.get('avatarUrl'),
                student_avatar_url=student_data.get('avatarUrl')
            )

            conv_data = conversation.to_dict()
            conv_data['createdAt'] = firestore.SERVER_TIMESTAMP
            conv_data['updatedAt'] = firestore.SERVER_TIMESTAMP

            conv_ref.set(conv_data)

        return {
            'status': 'success',
            'data': {
                'conversationId': conversation_id,
                'existed': existed
            }
        }

    except https_fn.HttpsError:
        raise
    except Exception as e:
        raise https_fn.HttpsError('internal', f'创建对话失败: {str(e)}')
