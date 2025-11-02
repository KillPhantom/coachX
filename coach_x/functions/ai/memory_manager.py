"""
AI Memory 管理器

管理用户的 LLM Profile，包括对话历史和训练偏好
"""

from typing import Dict, Any, Optional
from firebase_admin import firestore
from datetime import datetime

from users.models import UserLLMProfile
from utils.logger import logger


class MemoryManager:
    """用户 AI Memory 管理器"""
    
    @staticmethod
    def get_user_memory(user_id: str) -> UserLLMProfile:
        """
        获取用户 LLM Profile
        
        Args:
            user_id: 用户ID
        
        Returns:
            UserLLMProfile 对象，如果不存在则创建新的
        """
        try:
            db = firestore.client()
            doc_ref = db.collection('users').document(user_id).collection('ai_memory').document('profile')
            doc = doc_ref.get()
            
            if doc.exists:
                data = doc.to_dict()
                logger.info(f'📖 加载用户 LLM Profile - User: {user_id}')
                return UserLLMProfile.from_dict(data)
            else:
                # 不存在则创建默认 profile
                logger.info(f'🆕 创建新的 LLM Profile - User: {user_id}')
                profile = UserLLMProfile(user_id=user_id)
                MemoryManager.save_user_memory(profile)
                return profile
        
        except Exception as e:
            logger.error(f'❌ 获取用户 LLM Profile 失败: {str(e)}', exc_info=True)
            # 返回默认 profile
            return UserLLMProfile(user_id=user_id)
    
    @staticmethod
    def save_user_memory(profile: UserLLMProfile) -> bool:
        """
        保存用户 LLM Profile
        
        Args:
            profile: UserLLMProfile 对象
        
        Returns:
            是否成功
        """
        try:
            db = firestore.client()
            doc_ref = db.collection('users').document(profile.user_id).collection('ai_memory').document('profile')
            
            doc_ref.set(profile.to_dict())
            logger.info(f'💾 保存用户 LLM Profile - User: {profile.user_id}')
            return True
        
        except Exception as e:
            logger.error(f'❌ 保存用户 LLM Profile 失败: {str(e)}', exc_info=True)
            return False
    
    @staticmethod
    def update_conversation_history(
        user_id: str,
        user_message: str,
        ai_response: str,
        context: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        更新对话历史
        
        Args:
            user_id: 用户ID
            user_message: 用户消息
            ai_response: AI 响应
            context: 上下文信息（如 plan_id）
        
        Returns:
            是否成功
        """
        try:
            profile = MemoryManager.get_user_memory(user_id)
            profile.add_conversation(user_message, ai_response, context)
            
            # 尝试从对话中提取偏好
            extracted_prefs = MemoryManager._extract_preferences_from_conversation(
                user_message, ai_response
            )
            if extracted_prefs:
                profile.update_preferences(extracted_prefs)
                logger.info(f'🔍 从对话中提取到偏好: {extracted_prefs}')
            
            return MemoryManager.save_user_memory(profile)
        
        except Exception as e:
            logger.error(f'❌ 更新对话历史失败: {str(e)}', exc_info=True)
            return False
    
    @staticmethod
    def update_preferences(
        user_id: str,
        preferences: Dict[str, Any]
    ) -> bool:
        """
        更新用户偏好
        
        Args:
            user_id: 用户ID
            preferences: 偏好字典
        
        Returns:
            是否成功
        """
        try:
            profile = MemoryManager.get_user_memory(user_id)
            profile.update_preferences(preferences)
            return MemoryManager.save_user_memory(profile)
        
        except Exception as e:
            logger.error(f'❌ 更新用户偏好失败: {str(e)}', exc_info=True)
            return False
    
    @staticmethod
    def build_memory_context(user_id: str) -> str:
        """
        构建给 Claude 的 memory context
        
        Args:
            user_id: 用户ID
        
        Returns:
            格式化的 memory context 字符串
        """
        try:
            profile = MemoryManager.get_user_memory(user_id)
            return profile.build_memory_context()
        
        except Exception as e:
            logger.error(f'❌ 构建 memory context 失败: {str(e)}', exc_info=True)
            return "无特殊偏好记录"
    
    @staticmethod
    def _extract_preferences_from_conversation(
        user_message: str,
        ai_response: str
    ) -> Optional[Dict[str, Any]]:
        """
        从对话中提取用户偏好（简单的关键词匹配）
        
        Args:
            user_message: 用户消息
            ai_response: AI 响应
        
        Returns:
            提取到的偏好字典，如果没有则返回 None
        """
        preferences = {}
        
        # 提取偏好的动作（关键词匹配）
        prefer_keywords = ['喜欢', '偏好', '更倾向', '想要', '想做']
        avoid_keywords = ['不喜欢', '不想', '避免', '不要', '替换']
        
        user_lower = user_message.lower()
        
        # 检测偏好
        for keyword in prefer_keywords:
            if keyword in user_lower:
                # TODO: 更智能的提取逻辑（可以后续使用 NLP）
                logger.debug(f'检测到偏好关键词: {keyword}')
                break
        
        # 检测避免
        for keyword in avoid_keywords:
            if keyword in user_lower:
                logger.debug(f'检测到避免关键词: {keyword}')
                break
        
        # 如果没有提取到任何偏好，返回 None
        return preferences if preferences else None
    
    @staticmethod
    def clear_conversation_history(user_id: str) -> bool:
        """
        清空对话历史
        
        Args:
            user_id: 用户ID
        
        Returns:
            是否成功
        """
        try:
            profile = MemoryManager.get_user_memory(user_id)
            profile.conversation_history = []
            profile.updated_at = int(datetime.now().timestamp() * 1000)
            return MemoryManager.save_user_memory(profile)
        
        except Exception as e:
            logger.error(f'❌ 清空对话历史失败: {str(e)}', exc_info=True)
            return False

