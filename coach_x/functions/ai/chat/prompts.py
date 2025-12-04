"""
AI Chat Prompts

Prompts for the AI Coach chat feature.
"""

from typing import Dict, Any, List, Optional
import json

def build_chat_system_prompt(
    user_profile: Dict[str, Any],
    exercise_plan: Optional[Dict[str, Any]],
    diet_plan: Optional[Dict[str, Any]],
    user_memory: str,
    language: str = '中文'
) -> str:
    """
    Build the system prompt for AI Coach chat.
    
    Args:
        user_profile: User profile data (name, goal, stats, etc.)
        exercise_plan: Current active exercise plan
        diet_plan: Current active diet plan
        user_memory: User's preferences and history summary from MemoryManager
        language: Output language
        
    Returns:
        System prompt string
    """
    
    # Extract user basic info
    name = user_profile.get('name', '学员')
    gender = user_profile.get('gender', '未知')
    age = user_profile.get('age', '未知')
    height = user_profile.get('height', '未知')
    weight = user_profile.get('weight', '未知')
    goal = user_profile.get('goal', '未知')
    level = user_profile.get('level', '中级')
    
    # Format plans summary
    exercise_plan_summary = "无"
    if exercise_plan:
        exercise_plan_summary = f"""
        - 名称: {exercise_plan.get('name', '未命名')}
        - 目标: {exercise_plan.get('goal', '未知')}
        - 持续时间: {exercise_plan.get('duration_weeks', 0)} 周
        - 每周天数: {exercise_plan.get('days_per_week', 0)} 天
        """
        
    diet_plan_summary = "无"
    if diet_plan:
        diet_plan_summary = f"""
        - 名称: {diet_plan.get('name', '未命名')}
        - 描述: {diet_plan.get('description', '无')}
        - 每日目标热量: {diet_plan.get('target_calories', 0)} kcal
        """

    prompt = f"""
    You are CoachX, a professional, encouraging, and knowledgeable AI fitness coach.
    
    ## Your Role
    - You are helping {name} achieve their fitness goals.
    - You provide expert advice on training, nutrition, and recovery.
    - You are supportive, motivating, but also realistic and safety-conscious.
    - You track the user's progress and adjust advice based on their specific plans.
    
    ## User Profile
    - Name: {name}
    - Gender: {gender}
    - Age: {age}
    - Height: {height} cm
    - Weight: {weight} kg
    - Fitness Goal: {goal}
    - Experience Level: {level}
    
    ## Active Plans
    ### Exercise Plan
    {exercise_plan_summary}
    
    ### Diet Plan
    {diet_plan_summary}
    
    ## User Preferences & History (Memory)
    {user_memory}
    
    ## Response Guidelines
    1.  **Language**: Always respond in {language}.
    2.  **Tone**: Professional, encouraging, concise, and friendly.
    3.  **Content**: 
        - Answer the user's question directly.
        - Reference their specific plan or stats when relevant.
        - If asked about medical issues, advise consulting a doctor.
        - Keep responses structured (use bullet points/bold text where helpful).
    4.  **Formatting**: Use Markdown for formatting.
    
    You have access to the user's full context. Use it to provide personalized advice.
    """
    
    return prompt.strip()

def build_chat_user_prompt(
    message: str,
    context: Optional[Dict[str, Any]] = None
) -> str:
    """
    Build the user prompt.
    
    Args:
        message: User's message
        context: Optional immediate context (e.g. referencing a specific record)
        
    Returns:
        User prompt string
    """
    prompt = message
    
    if context:
        context_str = json.dumps(context, ensure_ascii=False, indent=2)
        prompt += f"\n\n[Context Info]:\n{context_str}"
        
    return prompt

