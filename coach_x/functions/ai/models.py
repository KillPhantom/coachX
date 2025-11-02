"""
AI 数据模型

定义 AI 请求和响应的数据结构
"""

from typing import Optional, Dict, Any, List
from dataclasses import dataclass, field


@dataclass
class AIGenerationRequest:
    """AI 生成请求"""
    prompt: str
    type: str  # 'full_plan', 'next_day', 'exercises', 'sets', 'optimize'
    context: Optional[Dict[str, Any]] = None
    student_id: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        result = {
            'prompt': self.prompt,
            'type': self.type,
        }
        if self.context:
            result['context'] = self.context
        if self.student_id:
            result['student_id'] = self.student_id
        return result


@dataclass
class TrainingSet:
    """训练组"""
    reps: str
    weight: str
    completed: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            'reps': self.reps,
            'weight': self.weight,
            'completed': self.completed,
        }


@dataclass
class Exercise:
    """运动动作"""
    name: str
    note: str = ''
    type: str = 'strength'  # 'strength' or 'cardio'
    sets: List[TrainingSet] = field(default_factory=list)
    completed: bool = False
    detail_guide: Optional[str] = None
    demo_videos: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'note': self.note,
            'type': self.type,
            'sets': [s.to_dict() for s in self.sets],
            'completed': self.completed,
            'detailGuide': self.detail_guide,
            'demoVideos': self.demo_videos,
        }


@dataclass
class TrainingDay:
    """训练日"""
    day: int
    type: str  # 'Leg Day', 'Chest Day', etc.
    name: str
    exercises: List[Exercise] = field(default_factory=list)
    completed: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            'day': self.day,
            'type': self.type,
            'name': self.name,
            'exercises': [e.to_dict() for e in self.exercises],
            'completed': self.completed,
        }


@dataclass
class TrainingPlanData:
    """训练计划数据"""
    name: str
    description: str
    days: List[TrainingDay] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'description': self.description,
            'days': [d.to_dict() for d in self.days],
        }


@dataclass
class AIGenerationResponse:
    """AI 生成响应"""
    status: str  # 'success', 'error', 'generating'
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        result = {'status': self.status}
        if self.data:
            result['data'] = self.data
        if self.error:
            result['error'] = self.error
        return result


