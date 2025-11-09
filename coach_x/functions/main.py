# CoachX Cloud Functions (Python) - 模块化架构
# 
# Firebase Functions for CoachX AI教练学生管理平台
# 
# 架构说明：
# - main.py: 入口文件，导入并暴露所有Cloud Functions
# - users/: 用户管理模块
# - invitations/: 邀请码管理模块
# - utils/: 通用工具模块

from firebase_admin import initialize_app

# 初始化Firebase Admin
initialize_app()

# ==================== 导入用户模块 ====================
from users.handlers import (
    create_user_document,
    fetch_user_info,
    update_user_info,
    update_active_plan
)

# ==================== 导入邀请码模块 ====================
from invitations.handlers import (
    verify_invitation_code,
    generate_invitation_codes,
    fetch_invitation_codes,
    mark_invitation_code_used
)

# ==================== 导入学生管理模块 ====================
from students.handlers import (
    fetch_students,
    delete_student,
    fetch_latest_training
)
from students.training_handlers import (
    fetch_today_training,
    upsert_today_training
)

# ==================== 导入 AI 生成模块 ====================
from ai.handlers import (
    generate_ai_training_plan,
    import_plan_from_image,
    import_supplement_plan_from_image,
    stream_training_plan,
    edit_plan_conversation,
    get_food_macros,
    generate_diet_plan_with_skill,
    edit_diet_plan_conversation,
    generate_supplement_plan_conversation
)

# ==================== 导入 AI 食物营养分析模块 ====================
from ai.food_nutrition import (
    analyze_food_nutrition
)

# ==================== 导入计划管理模块 ====================
from plans.handlers import (
    exercise_plan,
    diet_plan,
    supplement_plan,
    fetch_available_plans,
    get_student_assigned_plans,
    get_student_all_plans,
    assign_plan
)

# ==================== 导入聊天模块 ====================
from chat.handlers import (
    send_message,
    fetch_messages,
    mark_messages_as_read,
    get_or_create_conversation
)

# ==================== 导入身体测量模块 ====================
from body_stats.handlers import (
    save_body_measurement,
    fetch_body_measurements,
    update_body_measurement,
    delete_body_measurement
)

# ==================== 导出所有函数 ====================
__all__ = [
    # 用户管理
    'create_user_document',
    'fetch_user_info',
    'update_user_info',
    'update_active_plan',

    # 邀请码
    'verify_invitation_code',
    'generate_invitation_codes',
    'fetch_invitation_codes',
    'mark_invitation_code_used',

    # 学生管理
    'fetch_students',
    'delete_student',
    'fetch_latest_training',
    'fetch_today_training',
    'upsert_today_training',

    # AI 生成
    'generate_ai_training_plan',
    'import_plan_from_image',
    'import_supplement_plan_from_image',
    'stream_training_plan',
    'edit_plan_conversation',
    'get_food_macros',
    'generate_diet_plan_with_skill',
    'edit_diet_plan_conversation',
    'generate_supplement_plan_conversation',
    'analyze_food_nutrition',

    # 计划管理
    'exercise_plan',
    'diet_plan',
    'supplement_plan',
    'fetch_available_plans',
    'get_student_assigned_plans',
    'get_student_all_plans',
    'assign_plan',

    # 聊天消息
    'send_message',
    'fetch_messages',
    'mark_messages_as_read',
    'get_or_create_conversation',

    # 身体测量
    'save_body_measurement',
    'fetch_body_measurements',
    'update_body_measurement',
    'delete_body_measurement',
]
