"""
训练计划工具函数

提供训练计划数据结构验证和修复功能
"""

from typing import Dict, Any


def validate_plan_structure(plan: Dict[str, Any]) -> bool:
    """
    验证计划数据结构

    Args:
        plan: 计划数据

    Returns:
        是否有效
    """
    try:
        # 检查必需字段
        if "name" not in plan or "days" not in plan:
            return False

        # 检查 days 是否为列表
        if not isinstance(plan["days"], list):
            return False

        # 检查每个 day 的结构
        for day in plan["days"]:
            if not isinstance(day, dict):
                return False
            if "day" not in day or "type" not in day or "exercises" not in day:
                return False
            if not isinstance(day["exercises"], list):
                return False

            # 检查每个 exercise 的结构
            for exercise in day["exercises"]:
                if not isinstance(exercise, dict):
                    return False
                if "name" not in exercise or "sets" not in exercise:
                    return False
                if not isinstance(exercise["sets"], list):
                    return False

        return True

    except Exception:
        return False


def fix_plan_structure(plan: Dict[str, Any]) -> Dict[str, Any]:
    """
    尝试修复计划数据结构

    Args:
        plan: 原始计划数据

    Returns:
        修复后的计划数据
    """
    fixed_plan = {
        "name": plan.get("name", "训练计划"),
        "description": plan.get("description", ""),
        "days": [],
    }

    days = plan.get("days", [])
    if not isinstance(days, list):
        days = []

    for i, day in enumerate(days):
        if not isinstance(day, dict):
            continue

        fixed_day = {
            "day": day.get("day", i + 1),
            "type": day.get("type", "Training Day"),
            "name": day.get("name", f"Day {i + 1}"),
            "exercises": [],
            "completed": False,
        }

        exercises = day.get("exercises", [])
        if isinstance(exercises, list):
            for exercise in exercises:
                if not isinstance(exercise, dict):
                    continue

                fixed_exercise = {
                    "name": exercise.get("name", "未命名动作"),
                    "note": exercise.get("note", ""),
                    "type": exercise.get("type", "strength"),
                    "sets": [],
                    "completed": False,
                }

                sets = exercise.get("sets", [])
                if isinstance(sets, list):
                    for s in sets:
                        if isinstance(s, dict):
                            fixed_exercise["sets"].append(
                                {
                                    "reps": str(s.get("reps", "")),
                                    "weight": str(s.get("weight", "")),
                                    "completed": False,
                                }
                            )

                # 确保至少有一个 set
                if not fixed_exercise["sets"]:
                    fixed_exercise["sets"] = [
                        {"reps": "10", "weight": "0kg", "completed": False}
                    ]

                fixed_day["exercises"].append(fixed_exercise)

        fixed_plan["days"].append(fixed_day)

    return fixed_plan
