"""
邀请码数据模型
"""

class InvitationCodeModel:
    """邀请码模型"""
    
    def __init__(self, code: str, coach_id: str):
        self.code = code
        self.coachId = coach_id
        self.used = False
        self.usedBy = None
        self.expiresAt = None
    
    def to_dict(self):
        """转换为字典"""
        return {
            'code': self.code,
            'coachId': self.coachId,
            'used': self.used,
            'usedBy': self.usedBy,
            'expiresAt': self.expiresAt
        }

