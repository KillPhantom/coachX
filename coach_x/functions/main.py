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
    update_user_info
)

# ==================== 导入邀请码模块 ====================
from invitations.handlers import (
    verify_invitation_code,
    generate_invitation_codes,
    mark_invitation_code_used
)

# ==================== 导出所有函数 ====================
__all__ = [
    # 用户管理
    'create_user_document',
    'fetch_user_info',
    'update_user_info',
    
    # 邀请码
    'verify_invitation_code',
    'generate_invitation_codes',
    'mark_invitation_code_used',
]
