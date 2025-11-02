"""
AI Tool Use 定义模块

定义 Claude 可以调用的工具（Tool Use），
用于结构化输出训练计划数据
"""

from typing import Dict, Any


def get_single_day_tool() -> Dict[str, Any]:
    """
    获取单天训练计划工具定义
    
    用于 Claude Tool Use，让 AI 按照严格的 JSON Schema
    返回单天的训练计划数据
    
    Returns:
        Tool 定义字典，包含 name, description, input_schema
    """
    return {
        "name": "create_training_day",
        "description": "创建一天的训练计划，包含该天的所有训练动作和组数配置",
        "input_schema": {
            "type": "object",
            "properties": {
                "day": {
                    "type": "integer",
                    "description": "训练日编号（从1开始递增）"
                },
                "name": {
                    "type": "string",
                    "description": "训练日名称，如 'Chest Day', 'Back Day', '胸部训练'"
                },
                "type": {
                    "type": "string",
                    "description": "训练类型，如 'Upper Body', 'Lower Body', 'Full Body'"
                },
                "note": {
                    "type": "string",
                    "description": "训练日备注和要点，如 '重点发展胸大肌'"
                },
                "exercises": {
                    "type": "array",
                    "description": "该训练日的所有动作列表",
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": {
                                "type": "string",
                                "description": "动作名称，使用指定语言命名。中文示例：'深蹲'、'卧推'、'硬拉'；英文示例：'Squats'、'Bench Press'、'Deadlift'"
                            },
                            "note": {
                                "type": "string",
                                "description": "动作备注和技术要点，如 '保持肩胛骨稳定'"
                            },
                            "sets": {
                                "type": "array",
                                "description": "训练组列表，每个动作至少1组",
                                "items": {
                                    "type": "object",
                                    "properties": {
                                        "reps": {
                                            "type": "string",
                                            "description": "次数，如 '10', '8-12', '力竭'"
                                        },
                                        "weight": {
                                            "type": "string",
                                            "description": "重量，如 '80kg', '体重', '60% 1RM'"
                                        }
                                    },
                                    "required": ["reps", "weight"]
                                },
                                "minItems": 1
                            }
                        },
                        "required": ["name", "sets"]
                    },
                    "minItems": 1
                }
            },
            "required": ["day", "name", "exercises"]
        }
    }


def get_full_plan_tool() -> Dict[str, Any]:
    """
    获取完整训练计划工具定义（备用）
    
    注：目前主要使用单天工具，通过流式生成多次调用
    
    Returns:
        Tool 定义字典
    """
    return {
        "name": "create_training_plan",
        "description": "创建完整的训练计划，包含所有训练日",
        "input_schema": {
            "type": "object",
            "properties": {
                "name": {
                    "type": "string",
                    "description": "训练计划名称"
                },
                "description": {
                    "type": "string",
                    "description": "训练计划描述"
                },
                "days": {
                    "type": "array",
                    "description": "所有训练日列表",
                    "items": {
                        "type": "object",
                        "properties": {
                            "day": {"type": "integer"},
                            "name": {"type": "string"},
                            "type": {"type": "string"},
                            "note": {"type": "string"},
                            "exercises": {
                                "type": "array",
                                "items": {
                                    "type": "object",
                                    "properties": {
                                        "name": {
                                            "type": "string",
                                            "description": "动作名称，使用指定语言命名"
                                        },
                                        "note": {"type": "string"},
                                        "sets": {
                                            "type": "array",
                                            "items": {
                                                "type": "object",
                                                "properties": {
                                                    "reps": {"type": "string"},
                                                    "weight": {"type": "string"}
                                                },
                                                "required": ["reps", "weight"]
                                            }
                                        }
                                    },
                                    "required": ["name", "sets"]
                                }
                            }
                        },
                        "required": ["day", "name", "exercises"]
                    }
                }
            },
            "required": ["name", "description", "days"]
        }
    }


def get_plan_edit_tool() -> Dict[str, Any]:
    """
    获取计划编辑工具定义
    
    用于 AI 对话式编辑，返回修改建议和完整的修改后计划
    
    Returns:
        Tool 定义字典
    """
    return {
        "name": "edit_plan",
        "description": "编辑训练计划，返回修改分析、建议和完整的修改后计划",
        "input_schema": {
            "type": "object",
            "properties": {
                "analysis": {
                    "type": "string",
                    "description": "分析用户的修改意图，说明理解到用户想要修改什么"
                },
                "changes": {
                    "type": "array",
                    "description": "修改列表，每个修改包含类型、目标、描述和前后对比",
                    "items": {
                        "type": "object",
                        "properties": {
                            "type": {
                                "type": "string",
                                "enum": [
                                    "modify_exercise",          # 修改动作（名称、备注、训练组）
                                    "add_exercise",             # 添加动作
                                    "remove_exercise",          # 删除动作
                                    "modify_exercise_sets",     # 修改动作的训练组（exercise-level）
                                    "add_day",                  # 添加训练日
                                    "remove_day",               # 删除训练日
                                    "modify_day_name",          # 修改训练日名称
                                    "reorder",                  # 调整顺序
                                    "adjust_intensity",         # 调整强度
                                    "other"                     # 其他修改
                                ],
                                "description": "修改类型"
                            },
                            "target": {
                                "type": "string",
                                "description": "修改目标的标识，如 'day_1_exercise_2', 'day_3', 'all_weights'"
                            },
                            "description": {
                                "type": "string",
                                "description": "修改的具体描述，说明做了什么改动"
                            },
                            "reason": {
                                "type": "string",
                                "description": "修改的理由，基于训练科学或用户偏好的解释"
                            },
                            "before": {
                                "description": "修改前的内容。类型取决于修改类型：modify_exercise 和 modify_exercise_sets 使用对象或数组，add_day/add_exercise 通常使用字符串描述当前状态，其他使用字符串",
                                "oneOf": [
                                    {
                                        "type": "string",
                                        "description": "简要描述或关键参数（用于大多数修改类型，如 '5天训练计划'、'卧推' 等）"
                                    },
                                    {
                                        "type": "array",
                                        "description": "修改前的训练组列表（用于 modify_exercise_sets 类型）",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "reps": {
                                                    "type": "string",
                                                    "description": "次数"
                                                },
                                                "weight": {
                                                    "type": "string",
                                                    "description": "重量"
                                                }
                                            },
                                            "required": ["reps", "weight"]
                                        }
                                    },
                                    {
                                        "type": "object",
                                        "description": "完整的 exercise 对象（用于 modify_exercise 类型）",
                                        "properties": {
                                            "name": {
                                                "type": "string",
                                                "description": "动作名称"
                                            },
                                            "note": {
                                                "type": "string",
                                                "description": "动作备注"
                                            },
                                            "sets": {
                                                "type": "array",
                                                "description": "训练组列表",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "reps": {
                                                            "type": "string",
                                                            "description": "次数"
                                                        },
                                                        "weight": {
                                                            "type": "string",
                                                            "description": "重量"
                                                        }
                                                    },
                                                    "required": ["reps", "weight"]
                                                }
                                            }
                                        },
                                        "required": ["name", "sets"]
                                    }
                                ]
                            },
                            "after": {
                                "description": "修改后的内容。类型取决于修改类型：modify_exercise 和 modify_exercise_sets 使用对象或数组，add_day/add_exercise 使用对象，其他使用字符串",
                                "oneOf": [
                                    {
                                        "type": "string",
                                        "description": "简要描述或关键参数（用于 modify_exercise, modify_day_name 等简单修改类型）"
                                    },
                                    {
                                        "type": "array",
                                        "description": "修改后的训练组列表（用于 modify_exercise_sets 类型）",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "reps": {
                                                    "type": "string",
                                                    "description": "次数"
                                                },
                                                "weight": {
                                                    "type": "string",
                                                    "description": "重量"
                                                }
                                            },
                                            "required": ["reps", "weight"]
                                        }
                                    },
                                    {
                                        "type": "object",
                                        "description": "完整的结构化数据（用于 add_day, add_exercise 和 modify_exercise 类型）。add_day 需包含 name, type, note, exercises；add_exercise 和 modify_exercise 需包含 name, note, sets"
                                    }
                                ]
                            },
                            "day_index": {
                                "type": "integer",
                                "description": "训练日索引（从0开始），例如：Day 1 对应 0，Day 2 对应 1"
                            },
                            "exercise_index": {
                                "type": "integer",
                                "description": "动作索引（从0开始），仅在修改动作级别时提供"
                            }
                        },
                        "required": ["type", "description", "reason", "day_index"]
                    },
                    "minItems": 1
                },
                "summary": {
                    "type": "string",
                    "description": "修改总结，简要说明所有修改内容（可选）"
                }
            },
            "required": ["analysis", "changes"]
        }
    }


def get_diet_plan_edit_tool() -> Dict[str, Any]:
    """
    获取饮食计划编辑工具定义

    用于 Claude Tool Use，让 AI 按照严格的 JSON Schema
    返回饮食计划的修改建议

    Returns:
        Tool 定义字典，包含 name, description, input_schema
    """
    return {
        "name": "edit_diet_plan",
        "description": "编辑饮食计划，返回结构化的修改建议",
        "input_schema": {
            "type": "object",
            "properties": {
                "analysis": {
                    "type": "string",
                    "description": "对用户请求的分析和理解"
                },
                "changes": {
                    "type": "array",
                    "description": "具体的修改列表",
                    "items": {
                        "type": "object",
                        "properties": {
                            "type": {
                                "type": "string",
                                "enum": [
                                    "modify_meal",
                                    "add_meal",
                                    "remove_meal",
                                    "modify_food_item",
                                    "add_food_item",
                                    "remove_food_item",
                                    "adjust_macros",
                                    "add_day",
                                    "remove_day",
                                    "modify_day_name",
                                    "reorder",
                                    "other"
                                ],
                                "description": "修改类型"
                            },
                            "target": {
                                "type": "string",
                                "description": "修改目标的描述，例如：'第1天的早餐'、'鸡胸肉'"
                            },
                            "description": {
                                "type": "string",
                                "description": "修改的详细描述"
                            },
                            "reason": {
                                "type": "string",
                                "description": "进行此修改的原因"
                            },
                            "before": {
                                "description": "修改前的值（可以是字符串、数字、对象或数组）"
                            },
                            "after": {
                                "description": "修改后的值（可以是字符串、数字、对象或数组）"
                            },
                            "day_index": {
                                "type": "integer",
                                "description": "饮食日索引（从0开始），例如：Day 1 对应 0"
                            },
                            "meal_index": {
                                "type": "integer",
                                "description": "餐次索引（从0开始），仅在修改餐次级别时提供"
                            },
                            "food_item_index": {
                                "type": "integer",
                                "description": "食物条目索引（从0开始），仅在修改食物条目级别时提供"
                            },
                            "id": {
                                "type": "string",
                                "description": "修改的唯一标识符"
                            }
                        },
                        "required": ["type", "target", "description", "reason", "day_index", "id"]
                    },
                    "minItems": 1
                },
                "summary": {
                    "type": "string",
                    "description": "修改总结，简要说明所有修改内容（可选）"
                }
            },
            "required": ["analysis", "changes"]
        }
    }


def get_supplement_day_tool() -> Dict[str, Any]:
    """
    获取补剂日工具定义

    用于 Claude Tool Use，返回单天的补剂方案

    Returns:
        Tool 定义字典
    """
    return {
        "name": "create_supplement_day",
        "description": "创建一天的补剂方案（everyday same），包含各个时间段的补剂配置",
        "input_schema": {
            "type": "object",
            "properties": {
                "analysis": {
                    "type": "string",
                    "description": "对用户需求和训练/饮食计划的分析"
                },
                "day_name": {
                    "type": "string",
                    "description": "补剂日名称，如 '标准补剂日', 'Standard Supplement Day'"
                },
                "timings": {
                    "type": "array",
                    "description": "补剂时间段列表",
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": {
                                "type": "string",
                                "description": "时间段名称，如 '早餐前', '训练后', '睡前'"
                            },
                            "note": {
                                "type": "string",
                                "description": "时间段备注，如 '空腹服用效果更佳'"
                            },
                            "supplements": {
                                "type": "array",
                                "description": "该时间段的补剂列表",
                                "items": {
                                    "type": "object",
                                    "properties": {
                                        "name": {
                                            "type": "string",
                                            "description": "补剂名称，如 '蛋白粉', '肌酸', 'BCAA'"
                                        },
                                        "amount": {
                                            "type": "string",
                                            "description": "用量，如 '30g', '5g', '10g'"
                                        }
                                    },
                                    "required": ["name", "amount"]
                                },
                                "minItems": 1
                            }
                        },
                        "required": ["name", "supplements"]
                    },
                    "minItems": 1
                },
                "summary": {
                    "type": "string",
                    "description": "补剂方案总结，说明推荐理由"
                }
            },
            "required": ["analysis", "day_name", "timings"]
        }
    }

