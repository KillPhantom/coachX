"""
参数验证工具模块
"""

def validate_required(value, field_name: str):
    """验证必填字段"""
    if value is None or (isinstance(value, str) and not value.strip()):
        raise ValueError(f'{field_name}不能为空')
    return value

def validate_email(email: str):
    """验证邮箱格式"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(pattern, email):
        raise ValueError('邮箱格式不正确')
    return email

def validate_role(role: str):
    """验证用户角色"""
    valid_roles = ['student', 'coach']
    if role not in valid_roles:
        raise ValueError(f'角色必须是{valid_roles}之一')
    return role

def validate_gender(gender: str):
    """验证性别"""
    valid_genders = ['male', 'female']
    if gender not in valid_genders:
        raise ValueError(f'性别必须是{valid_genders}之一')
    return gender

