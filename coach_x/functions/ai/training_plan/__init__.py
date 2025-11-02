"""
Training Plan Module

训练计划相关的 AI 功能模块
"""

from .handlers import (
    generate_ai_training_plan,
    stream_training_plan,
    edit_plan_conversation,
)

from .prompts import (
    get_system_prompt,
    build_full_plan_prompt,
    build_next_day_prompt,
    build_exercises_prompt,
    build_sets_prompt,
    build_optimize_prompt,
    build_structured_plan_prompt,
    build_single_day_prompt,
    build_edit_conversation_prompt,
)

from .utils import (
    validate_plan_structure,
    fix_plan_structure,
)

__all__ = [
    # Handlers
    'generate_ai_training_plan',
    'stream_training_plan',
    'edit_plan_conversation',
    # Prompts
    'get_system_prompt',
    'build_full_plan_prompt',
    'build_next_day_prompt',
    'build_exercises_prompt',
    'build_sets_prompt',
    'build_optimize_prompt',
    'build_structured_plan_prompt',
    'build_single_day_prompt',
    'build_edit_conversation_prompt',
    # Utils
    'validate_plan_structure',
    'fix_plan_structure',
]
