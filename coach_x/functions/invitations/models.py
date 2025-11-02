"""
邀请码数据模型
"""

class InvitationCodeModel:
    """邀请码模型"""
    
    def __init__(self, code: str, coach_id: str, total_days: int = 180, note: str = ''):
        self.code = code
        self.coachId = coach_id
        self.totalDays = total_days  # 签约总时长（天）
        self.note = note  # 备注
        self.used = False
        self.usedBy = None
        self.expiresAt = None
    
    def to_dict(self):
        """转换为字典"""
        result = {
            'code': self.code,
            'coachId': self.coachId,
            'totalDays': self.totalDays,
            'used': self.used,
            'usedBy': self.usedBy,
            'expiresAt': self.expiresAt
        }
        
        # 添加note（如果有）
        if self.note:
            result['note'] = self.note
        
        return result

