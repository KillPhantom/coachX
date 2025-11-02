"""
用户数据模型
"""
from typing import List, Dict, Any, Optional
from datetime import datetime


class UserModel:
    """用户模型"""
    
    def __init__(self, user_id: str, email: str, name: str = '', role: str = 'student'):
        self.id = user_id
        self.email = email
        self.name = name
        self.role = role
        self.isVerified = False
    
    def to_dict(self):
        """转换为字典"""
        return {
            'email': self.email,
            'name': self.name,
            'role': self.role,
            'isVerified': self.isVerified
        }


class UserLLMProfile:
    """
    用户 LLM Profile 模型
    
    存储用户与 AI 对话的偏好和历史，用于提供个性化的 AI 体验
    """
    
    def __init__(
        self,
        user_id: str,
        training_preferences: Optional[Dict[str, Any]] = None,
        conversation_history: Optional[List[Dict[str, Any]]] = None,
        language_preference: str = '中文',
        updated_at: Optional[int] = None
    ):
        self.user_id = user_id
        self.training_preferences = training_preferences or {
            'preferred_exercises': [],
            'avoided_exercises': [],
            'intensity_preference': 'moderate',
            'equipment_preference': [],
            'training_style': [],
            'common_goals': []
        }
        self.conversation_history = conversation_history or []
        self.language_preference = language_preference
        self.updated_at = updated_at or int(datetime.now().timestamp() * 1000)
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            'user_id': self.user_id,
            'training_preferences': self.training_preferences,
            'conversation_history': self.conversation_history,
            'language_preference': self.language_preference,
            'updated_at': self.updated_at
        }
    
    @staticmethod
    def from_dict(data: Dict[str, Any]) -> 'UserLLMProfile':
        """从字典创建"""
        return UserLLMProfile(
            user_id=data.get('user_id', ''),
            training_preferences=data.get('training_preferences'),
            conversation_history=data.get('conversation_history'),
            language_preference=data.get('language_preference', '中文'),
            updated_at=data.get('updated_at')
        )
    
    def add_conversation(
        self,
        user_message: str,
        ai_response: str,
        context: Optional[Dict[str, Any]] = None
    ):
        """
        添加对话记录
        
        Args:
            user_message: 用户消息
            ai_response: AI 响应
            context: 上下文信息（如 plan_id）
        """
        conversation_entry = {
            'timestamp': int(datetime.now().timestamp() * 1000),
            'user_message': user_message,
            'ai_response': ai_response,
            'context': context or {}
        }
        
        self.conversation_history.append(conversation_entry)
        
        # 只保留最近 20 条对话
        if len(self.conversation_history) > 20:
            self.conversation_history = self.conversation_history[-20:]
        
        self.updated_at = int(datetime.now().timestamp() * 1000)
    
    def update_preferences(self, preferences: Dict[str, Any]):
        """
        更新训练偏好
        
        Args:
            preferences: 偏好字典
        """
        for key, value in preferences.items():
            if key in self.training_preferences:
                self.training_preferences[key] = value
        
        self.updated_at = int(datetime.now().timestamp() * 1000)
    
    def get_recent_conversations(self, limit: int = 5) -> List[Dict[str, Any]]:
        """
        获取最近的对话记录
        
        Args:
            limit: 数量限制
        
        Returns:
            最近的对话列表
        """
        return self.conversation_history[-limit:] if self.conversation_history else []
    
    def build_memory_context(self) -> str:
        """
        构建给 Claude 的 memory context
        
        Returns:
            格式化的 memory context 字符串
        """
        context_parts = []
        
        # 1. 训练偏好
        prefs = self.training_preferences
        if prefs.get('preferred_exercises'):
            context_parts.append(f"用户偏好的动作：{', '.join(prefs['preferred_exercises'])}")
        
        if prefs.get('avoided_exercises'):
            context_parts.append(f"用户避免的动作：{', '.join(prefs['avoided_exercises'])}")
        
        if prefs.get('intensity_preference'):
            context_parts.append(f"强度偏好：{prefs['intensity_preference']}")
        
        if prefs.get('equipment_preference'):
            context_parts.append(f"设备偏好：{', '.join(prefs['equipment_preference'])}")
        
        if prefs.get('training_style'):
            context_parts.append(f"训练风格：{', '.join(prefs['training_style'])}")
        
        if prefs.get('common_goals'):
            context_parts.append(f"常见目标：{', '.join(prefs['common_goals'])}")
        
        # 2. 最近对话摘要（只包含用户的请求模式）
        recent = self.get_recent_conversations(limit=3)
        if recent:
            context_parts.append("\n最近的对话模式：")
            for conv in recent:
                user_msg = conv.get('user_message', '')[:100]  # 截取前100字符
                context_parts.append(f"  - {user_msg}")
        
        return "\n".join(context_parts) if context_parts else "无特殊偏好记录"

