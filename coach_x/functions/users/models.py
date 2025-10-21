"""
用户数据模型
"""

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

