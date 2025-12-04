"""
AI Chat Streaming

Handles the streaming logic for AI Coach chat.
"""

from typing import Dict, Any, Generator, List, Optional
import json

from ..claude_client import get_claude_client
from ..memory_manager import MemoryManager
from .prompts import build_chat_system_prompt, build_chat_user_prompt
from utils.logger import logger

def stream_chat_with_ai(
    user_id: str,
    user_message: str,
    user_profile: Dict[str, Any],
    exercise_plan: Optional[Dict[str, Any]],
    diet_plan: Optional[Dict[str, Any]],
    conversation_history: List[Dict[str, str]],
    extra_context: Optional[Dict[str, Any]] = None
) -> Generator[Dict[str, Any], None, None]:
    """
    Stream chat response from AI Coach.
    
    Args:
        user_id: User ID
        user_message: User's current message
        user_profile: User profile data
        exercise_plan: Active exercise plan
        diet_plan: Active diet plan
        conversation_history: List of recent messages [{'role': 'user'|'assistant', 'content': '...'}]
        extra_context: Optional extra data to inject (e.g. weight history)
        
    Yields:
        Streaming events (text_delta, error, complete)
    """
    try:
        logger.info(f'🔄 [Chat] Start chat stream for user: {user_id}')
        
        # 1. Get User Memory Context
        user_memory_context = MemoryManager.build_memory_context(user_id)
        
        # 2. Extract language preference (default to Chinese)
        # Try to find it in profile or memory, fallback to Chinese
        language = user_profile.get('language', '中文')
        
        # 3. Build Prompts
        system_prompt = build_chat_system_prompt(
            user_profile=user_profile,
            exercise_plan=exercise_plan,
            diet_plan=diet_plan,
            user_memory=user_memory_context,
            language=language
        )
        
        # Format history into the prompt (since our client is single-turn)
        history_str = ""
        if conversation_history:
            history_str = "\n\n[Recent Conversation History]:\n"
            for msg in conversation_history:
                role = msg.get('role', 'user')
                content = msg.get('content', '')
                if role == 'user':
                    history_str += f"User: {content}\n"
                else:
                    history_str += f"Coach: {content}\n"
        
        # Add history to user prompt context
        full_user_prompt = f"{history_str}\n\n[User's Current Message]:\n{user_message}"
        
        user_prompt_final = build_chat_user_prompt(full_user_prompt, context=extra_context)
        
        logger.info(f'📝 System Prompt Length: {len(system_prompt)}')
        logger.info(f'📝 User Prompt Length: {len(user_prompt_final)}')
        
        # 4. Call Claude Streaming
        claude_client = get_claude_client()
        
        text_content = ""
        event_count = 0
        
        # We use a tool-less call for general chat, 
        # unless we want to give it tools to look up things (future improvement)
        for event in claude_client.call_claude_streaming(
            system_prompt=system_prompt,
            user_prompt=user_prompt_final,
            tools=None 
        ):
            event_count += 1
            event_type = event.get('type')
            
            if event_type == 'text_delta':
                text_delta = event.get('text', '')
                text_content += text_delta
                
                if text_delta:
                    yield {
                        'type': 'text_delta',
                        'content': text_delta
                    }
                    
            elif event_type == 'text_complete':
                # Just logging, we use accumulated text_content
                pass
                
            elif event_type == 'error':
                error_msg = event.get('error', 'Unknown error')
                logger.error(f'❌ [Chat] Claude Error: {error_msg}')
                yield {
                    'type': 'error',
                    'error': error_msg
                }
                return

        # 5. Save to Memory
        if text_content:
            logger.info('💾 Saving conversation to memory')
            MemoryManager.update_conversation_history(
                user_id=user_id,
                user_message=user_message,
                ai_response=text_content,
                context={'type': 'chat'}
            )
            
        yield {
            'type': 'complete',
            'message': 'Response complete'
        }
        
    except Exception as e:
        logger.error(f'❌ [Chat] Stream error: {str(e)}', exc_info=True)
        yield {
            'type': 'error',
            'error': f'Chat failed: {str(e)}'
        }

