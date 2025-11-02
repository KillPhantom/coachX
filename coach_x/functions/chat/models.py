"""
聊天数据模型
"""
from typing import Dict, Any, Optional
from datetime import datetime


class MessageModel:
    """消息模型"""

    def __init__(
        self,
        message_id: str,
        conversation_id: str,
        sender_id: str,
        receiver_id: str,
        message_type: str,  # 'text' | 'image' | 'video' | 'voice'
        content: str,
        media_url: Optional[str] = None,
        media_metadata: Optional[Dict[str, Any]] = None,
        status: str = 'sent',  # 'sending' | 'sent' | 'delivered' | 'read' | 'failed'
        created_at: Optional[int] = None
    ):
        self.id = message_id
        self.conversation_id = conversation_id
        self.sender_id = sender_id
        self.receiver_id = receiver_id
        self.type = message_type
        self.content = content
        self.media_url = media_url
        self.media_metadata = media_metadata or {}
        self.status = status
        self.is_deleted = False
        self.created_at = created_at or int(datetime.now().timestamp() * 1000)
        self.read_at = None

    def to_dict(self):
        """转换为字典"""
        result = {
            'id': self.id,
            'conversationId': self.conversation_id,
            'senderId': self.sender_id,
            'receiverId': self.receiver_id,
            'type': self.type,
            'content': self.content,
            'status': self.status,
            'isDeleted': self.is_deleted,
            'createdAt': self.created_at,
        }
        if self.media_url:
            result['mediaUrl'] = self.media_url
        if self.media_metadata:
            result['mediaMetadata'] = self.media_metadata
        if self.read_at:
            result['readAt'] = self.read_at
        return result


class ConversationModel:
    """对话模型"""

    def __init__(
        self,
        conversation_id: str,
        coach_id: str,
        student_id: str,
        coach_name: str = '',
        student_name: str = '',
        coach_avatar_url: Optional[str] = None,
        student_avatar_url: Optional[str] = None
    ):
        self.id = conversation_id
        self.coach_id = coach_id
        self.student_id = student_id
        self.last_message = None
        self.last_message_time = int(datetime.now().timestamp() * 1000)
        self.coach_unread_count = 0
        self.student_unread_count = 0
        self.coach_last_read_time = 0
        self.student_last_read_time = 0
        self.participant_names = {
            'coachName': coach_name,
            'studentName': student_name
        }
        self.participant_avatars = {
            'coachAvatarUrl': coach_avatar_url or '',
            'studentAvatarUrl': student_avatar_url or ''
        }
        self.is_archived = False
        self.is_pinned = False

    def to_dict(self):
        """转换为字典"""
        result = {
            'id': self.id,
            'coachId': self.coach_id,
            'studentId': self.student_id,
            'lastMessageTime': self.last_message_time,
            'coachUnreadCount': self.coach_unread_count,
            'studentUnreadCount': self.student_unread_count,
            'coachLastReadTime': self.coach_last_read_time,
            'studentLastReadTime': self.student_last_read_time,
            'participantNames': self.participant_names,
            'participantAvatars': self.participant_avatars,
            'isArchived': self.is_archived,
            'isPinned': self.is_pinned,
        }
        if self.last_message:
            result['lastMessage'] = self.last_message
        return result

    @staticmethod
    def generate_conversation_id(coach_id: str, student_id: str) -> str:
        """生成对话ID"""
        return f"coach_{coach_id}_student_{student_id}"
