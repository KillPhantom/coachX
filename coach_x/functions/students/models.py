"""
学生管理相关数据模型
"""

class StudentPlanInfo:
    """学生计划信息"""
    
    def __init__(self, plan_id: str = None, plan_name: str = None, plan_type: str = None):
        self.id = plan_id
        self.name = plan_name
        self.type = plan_type  # 'exercise', 'diet', 'supplement'
    
    def to_dict(self):
        """转换为字典"""
        if not self.id:
            return None
        return {
            'id': self.id,
            'name': self.name,
            'type': self.type
        }


class StudentListItem:
    """学生列表项模型"""
    
    def __init__(
        self,
        student_id: str,
        name: str,
        email: str,
        avatar_url: str = None,
        coach_id: str = None,
        exercise_plan: StudentPlanInfo = None,
        diet_plan: StudentPlanInfo = None,
        supplement_plan: StudentPlanInfo = None,
        created_at = None
    ):
        self.id = student_id
        self.name = name
        self.email = email
        self.avatarUrl = avatar_url
        self.coachId = coach_id
        self.exercisePlan = exercise_plan
        self.dietPlan = diet_plan
        self.supplementPlan = supplement_plan
        self.createdAt = created_at
    
    def to_dict(self):
        """转换为字典"""
        result = {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'coachId': self.coachId,
        }
        
        # 添加可选字段
        if self.avatarUrl:
            result['avatarUrl'] = self.avatarUrl
        
        if self.exercisePlan:
            result['exercisePlan'] = self.exercisePlan.to_dict()
        
        if self.dietPlan:
            result['dietPlan'] = self.dietPlan.to_dict()
        
        if self.supplementPlan:
            result['supplementPlan'] = self.supplementPlan.to_dict()
        
        if self.createdAt:
            result['createdAt'] = self.createdAt
        
        return result

