"""
Plans 数据模型
"""

from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field


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

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TrainingSet':
        return cls(
            reps=data.get('reps', ''),
            weight=data.get('weight', ''),
            completed=data.get('completed', False)
        )


@dataclass
class Exercise:
    """运动动作"""
    name: str
    note: str = ''
    type: str = 'strength'
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

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Exercise':
        sets_data = data.get('sets', [])
        sets = [TrainingSet.from_dict(s) for s in sets_data]
        
        return cls(
            name=data.get('name', ''),
            note=data.get('note', ''),
            type=data.get('type', 'strength'),
            sets=sets,
            completed=data.get('completed', False),
            detail_guide=data.get('detailGuide'),
            demo_videos=data.get('demoVideos', [])
        )


@dataclass
class TrainingDay:
    """训练日"""
    day: int
    type: str
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

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TrainingDay':
        exercises_data = data.get('exercises', [])
        exercises = [Exercise.from_dict(e) for e in exercises_data]
        
        return cls(
            day=data.get('day', 1),
            type=data.get('type', ''),
            name=data.get('name', ''),
            exercises=exercises,
            completed=data.get('completed', False)
        )


@dataclass
class ExercisePlan:
    """训练计划"""
    id: Optional[str] = None
    name: str = ''
    description: str = ''
    days: List[TrainingDay] = field(default_factory=list)
    owner_id: str = ''
    student_ids: List[str] = field(default_factory=list)
    created_at: int = 0
    updated_at: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'days': [d.to_dict() for d in self.days],
            'ownerId': self.owner_id,
            'studentIds': self.student_ids,
            'createdAt': self.created_at,
            'updatedAt': self.updated_at,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ExercisePlan':
        days_data = data.get('days', [])
        days = [TrainingDay.from_dict(d) for d in days_data]

        return cls(
            id=data.get('id'),
            name=data.get('name', ''),
            description=data.get('description', ''),
            days=days,
            owner_id=data.get('ownerId', ''),
            student_ids=data.get('studentIds', []),
            created_at=data.get('createdAt', 0),
            updated_at=data.get('updatedAt', 0)
        )


# ==================== Diet Plan Models ====================


@dataclass
class Macros:
    """营养数据"""
    protein: float = 0.0
    carbs: float = 0.0
    fat: float = 0.0
    calories: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            'protein': self.protein,
            'carbs': self.carbs,
            'fat': self.fat,
            'calories': self.calories,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Macros':
        return cls(
            protein=float(data.get('protein', 0)),
            carbs=float(data.get('carbs', 0)),
            fat=float(data.get('fat', 0)),
            calories=float(data.get('calories', 0))
        )

    def __add__(self, other: 'Macros') -> 'Macros':
        """支持营养数据相加"""
        return Macros(
            protein=self.protein + other.protein,
            carbs=self.carbs + other.carbs,
            fat=self.fat + other.fat,
            calories=self.calories + other.calories
        )


@dataclass
class FoodItem:
    """食物条目"""
    food: str
    amount: str
    protein: float = 0.0
    carbs: float = 0.0
    fat: float = 0.0
    calories: float = 0.0
    is_custom_input: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            'food': self.food,
            'amount': self.amount,
            'protein': self.protein,
            'carbs': self.carbs,
            'fat': self.fat,
            'calories': self.calories,
            'isCustomInput': self.is_custom_input,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'FoodItem':
        return cls(
            food=data.get('food', ''),
            amount=data.get('amount', ''),
            protein=float(data.get('protein', 0)),
            carbs=float(data.get('carbs', 0)),
            fat=float(data.get('fat', 0)),
            calories=float(data.get('calories', 0)),
            is_custom_input=data.get('isCustomInput', False)
        )

    def get_macros(self) -> Macros:
        """获取该食物的营养数据"""
        return Macros(
            protein=self.protein,
            carbs=self.carbs,
            fat=self.fat,
            calories=self.calories
        )


@dataclass
class Meal:
    """餐次"""
    name: str
    note: str = ''
    items: List[FoodItem] = field(default_factory=list)
    completed: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'note': self.note,
            'items': [item.to_dict() for item in self.items],
            'completed': self.completed,
            'macros': self.calculate_macros().to_dict(),
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Meal':
        items_data = data.get('items', [])
        items = [FoodItem.from_dict(item) for item in items_data]

        return cls(
            name=data.get('name', ''),
            note=data.get('note', ''),
            items=items,
            completed=data.get('completed', False)
        )

    def calculate_macros(self) -> Macros:
        """计算该餐次的总营养数据"""
        total = Macros()
        for item in self.items:
            total = total + item.get_macros()
        return total


@dataclass
class DietDay:
    """饮食日"""
    day: int
    name: str
    meals: List[Meal] = field(default_factory=list)
    completed: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            'day': self.day,
            'name': self.name,
            'meals': [meal.to_dict() for meal in self.meals],
            'completed': self.completed,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'DietDay':
        meals_data = data.get('meals', [])
        meals = [Meal.from_dict(meal) for meal in meals_data]

        return cls(
            day=data.get('day', 1),
            name=data.get('name', ''),
            meals=meals,
            completed=data.get('completed', False)
        )

    def calculate_macros(self) -> Macros:
        """计算该天的总营养数据"""
        total = Macros()
        for meal in self.meals:
            total = total + meal.calculate_macros()
        return total


@dataclass
class DietPlan:
    """饮食计划"""
    id: Optional[str] = None
    name: str = ''
    description: str = ''
    days: List[DietDay] = field(default_factory=list)
    owner_id: str = ''
    student_ids: List[str] = field(default_factory=list)
    created_at: int = 0
    updated_at: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'days': [d.to_dict() for d in self.days],
            'ownerId': self.owner_id,
            'studentIds': self.student_ids,
            'createdAt': self.created_at,
            'updatedAt': self.updated_at,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'DietPlan':
        days_data = data.get('days', [])
        days = [DietDay.from_dict(d) for d in days_data]

        return cls(
            id=data.get('id'),
            name=data.get('name', ''),
            description=data.get('description', ''),
            days=days,
            owner_id=data.get('ownerId', ''),
            student_ids=data.get('studentIds', []),
            created_at=data.get('createdAt', 0),
            updated_at=data.get('updatedAt', 0)
        )


