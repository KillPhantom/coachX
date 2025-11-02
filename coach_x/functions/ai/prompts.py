"""
Prompt 工程模板库（统一导出入口）

本文件已重构为模块化结构，实际实现位于子目录。
"""

# 训练计划prompts
from .training_plan.prompts import (
    get_system_prompt,
    build_full_plan_prompt,
    build_structured_plan_prompt,
    build_next_day_prompt,
    build_exercises_prompt,
    build_sets_prompt,
    build_optimize_prompt,
    build_single_day_prompt,
    build_edit_conversation_prompt,
)

# 饮食计划prompts
from .diet_plan.prompts import (
    build_edit_diet_plan_prompt,
)

# 图片导入prompts
from .image_import.prompts import (
    build_vision_import_prompt,
)

# 向后兼容导出
__all__ = [
    # Training Plan
    'get_system_prompt',
    'build_full_plan_prompt',
    'build_structured_plan_prompt',
    'build_next_day_prompt',
    'build_exercises_prompt',
    'build_sets_prompt',
    'build_optimize_prompt',
    'build_single_day_prompt',
    'build_edit_conversation_prompt',

    # Diet Plan
    'build_edit_diet_plan_prompt',

    # Image Import
    'build_vision_import_prompt',
]

# 保持向后兼容
SYSTEM_PROMPT = get_system_prompt('中文')
