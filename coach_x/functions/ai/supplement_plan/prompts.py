"""
补剂计划生成 Prompt 模块

构建 Claude API 使用的 system prompt 和 user prompt
"""

from typing import Dict, Any, Optional, List, Tuple


def get_system_prompt(language: str = '中文') -> str:
    """
    获取补剂推荐专家的 system prompt

    Args:
        language: 输出语言

    Returns:
        System prompt 字符串
    """
    return f"""你是一位专业的运动营养师和补剂推荐专家。

你的任务是根据用户的训练计划、饮食计划和个人需求，推荐科学合理的补剂方案。

## 关键原则

1. **基于实际需求**：分析训练强度和营养缺口，推荐必要的补剂
2. **剂量科学**：遵循运动营养学研究的推荐剂量
3. **服用时机**：优化补剂吸收效果的时间安排
4. **成本考虑**：优先推荐性价比高的基础补剂
5. **安全第一**：避免推荐有争议或风险的补剂

## 补剂类别优先级

1. **基础类**（科学证据充分）
   - 蛋白粉（Whey Protein）：训练后肌肉修复
   - 肌酸（Creatine）：增强力量和肌肉增长
   - 维生素D：骨骼健康、免疫力
   - Omega-3：抗炎、心血管健康

2. **训练类**（针对高强度训练）
   - BCAA：减少肌肉分解
   - 谷氨酰胺：加速恢复
   - 咖啡因：提升训练表现
   - 氮泵（Pre-workout）：增加能量和专注力

3. **健康类**（营养补充）
   - 多种维生素（Multivitamin）
   - ZMA（锌+镁）：睡眠质量
   - 益生菌：肠道健康

4. **可选类**（根据目标和预算）
   - 增肌粉（Mass Gainer）：增加热量摄入
   - CLA：辅助减脂
   - HMB：减少肌肉分解

## 服用时机建议

- **早餐前/空腹**：肌酸、维生素D
- **训练前**：氮泵、咖啡因
- **训练后**：蛋白粉、BCAA、肌酸
- **睡前**：酪蛋白（Casein）、ZMA
- **随餐**：多种维生素、Omega-3

## 输出要求

1. 先分析用户的训练强度、频率和营养摄入情况
2. 识别潜在的营养缺口
3. 推荐补剂方案（按时间段组织）
4. 说明每种补剂的作用和推荐理由
5. **使用 {language} 进行对话和生成**

请调用 create_supplement_day 工具返回结构化的补剂方案。
"""


def build_supplement_creation_prompt(
    user_message: str,
    training_plan: Optional[Dict[str, Any]],
    diet_plan: Optional[Dict[str, Any]],
    conversation_history: List[Dict[str, str]],
    language: str = '中文'
) -> Tuple[str, str]:
    """
    构建补剂方案创建 prompt

    Args:
        user_message: 用户的请求消息
        training_plan: 训练计划数据（可选）
        diet_plan: 饮食计划数据（可选）
        conversation_history: 对话历史
        language: 输出语言

    Returns:
        (system_prompt, user_prompt) 元组
    """
    system_prompt = get_system_prompt(language)

    # 构建上下文部分
    context_sections = []

    # 训练计划上下文
    if training_plan:
        training_summary = _summarize_training_plan(training_plan)
        context_sections.append(f"""
## 用户的训练计划

**计划名称**: {training_plan.get('name', '未命名')}
**训练频率**: 每周 {len(training_plan.get('days', []))} 天
**训练强度**: {training_summary['intensity']}
**主要训练类型**: {training_summary['training_types']}
**总训练量**: {training_summary['total_volume']}

训练日详情:
{training_summary['days_detail']}
""")

    # 饮食计划上下文
    if diet_plan:
        diet_summary = _summarize_diet_plan(diet_plan)
        context_sections.append(f"""
## 用户的饮食计划

**计划名称**: {diet_plan.get('name', '未命名')}
**营养目标**: {diet_summary['goal']}
**每日热量**: {diet_summary['avg_calories']} kcal（估算）
**蛋白质摄入**: {diet_summary['avg_protein']} g/天（估算）
**碳水化合物**: {diet_summary['avg_carbs']} g/天（估算）
**脂肪**: {diet_summary['avg_fat']} g/天（估算）

饮食特点:
{diet_summary['characteristics']}
""")

    # 如果没有计划，提供通用上下文
    if not training_plan and not diet_plan:
        context_sections.append("""
## 用户情况

用户未提供训练计划或饮食计划。请基于用户的描述和通用健身建议推荐补剂方案。
""")

    context = "\n".join(context_sections)

    # 构建 user prompt
    user_prompt = f"""{context}

## 用户请求

{user_message}

## 任务

请根据以上信息，生成一天的补剂方案（everyday same）。方案应包含：

1. **分析**：用户的训练强度、营养摄入情况和潜在需求
2. **推荐补剂列表**：按服用时间段组织（如：早餐前、训练后、睡前）
3. **剂量说明**：每种补剂的科学推荐剂量
4. **推荐理由**：为什么推荐这些补剂

请调用 create_supplement_day 工具返回结构化数据。
"""

    return system_prompt, user_prompt


def _summarize_training_plan(plan: Dict[str, Any]) -> Dict[str, Any]:
    """
    总结训练计划的关键信息

    Args:
        plan: 训练计划数据

    Returns:
        训练计划摘要字典
    """
    days = plan.get('days', [])

    # 计算总训练量
    total_exercises = sum(len(day.get('exercises', [])) for day in days)
    total_sets = sum(
        len(exercise.get('sets', []))
        for day in days
        for exercise in day.get('exercises', [])
    )

    # 分析训练强度（基于组数）
    avg_sets_per_day = total_sets / len(days) if days else 0
    if avg_sets_per_day > 20:
        intensity = '高强度'
    elif avg_sets_per_day > 12:
        intensity = '中等强度'
    else:
        intensity = '低强度'

    # 识别训练类型
    training_types = set()
    for day in days:
        day_type = day.get('type', '')
        if day_type:
            training_types.add(day_type)
        else:
            # 根据动作名称推测
            day_name = day.get('name', '').lower()
            if 'chest' in day_name or '胸' in day_name:
                training_types.add('Chest')
            elif 'back' in day_name or '背' in day_name:
                training_types.add('Back')
            elif 'leg' in day_name or '腿' in day_name:
                training_types.add('Legs')

    # 构建训练日详情
    days_detail_lines = []
    for i, day in enumerate(days[:3], 1):  # 只显示前3天
        day_name = day.get('name', f'Day {i}')
        exercises_count = len(day.get('exercises', []))
        days_detail_lines.append(f"- Day {i} ({day_name}): {exercises_count} 个动作")

    if len(days) > 3:
        days_detail_lines.append(f"- ... 共 {len(days)} 天")

    return {
        'intensity': intensity,
        'training_types': ', '.join(training_types) if training_types else '力量训练',
        'total_volume': f'{total_exercises} 个动作，{total_sets} 组',
        'days_detail': '\n'.join(days_detail_lines)
    }


def _summarize_diet_plan(plan: Dict[str, Any]) -> Dict[str, Any]:
    """
    总结饮食计划的关键信息

    Args:
        plan: 饮食计划数据

    Returns:
        饮食计划摘要字典
    """
    days = plan.get('days', [])

    # 估算平均营养摄入（基于第一天）
    if days:
        first_day = days[0]
        meals = first_day.get('meals', [])

        # 简单估算（实际需要累加所有food items的macros）
        total_protein = 0
        total_carbs = 0
        total_fat = 0
        total_calories = 0

        for meal in meals:
            items = meal.get('items', [])
            for item in items:
                macros = item.get('macros', {})
                total_protein += macros.get('protein', 0)
                total_carbs += macros.get('carbs', 0)
                total_fat += macros.get('fat', 0)
                total_calories += macros.get('calories', 0)

        avg_protein = int(total_protein)
        avg_carbs = int(total_carbs)
        avg_fat = int(total_fat)
        avg_calories = int(total_calories)
    else:
        avg_protein = 0
        avg_carbs = 0
        avg_fat = 0
        avg_calories = 0

    # 判断营养目标
    if avg_calories > 2800:
        goal = '增肌'
    elif avg_calories < 2000:
        goal = '减脂'
    else:
        goal = '维持'

    # 分析饮食特点
    characteristics = []
    if avg_protein > 150:
        characteristics.append('- 高蛋白饮食')
    if avg_carbs > 300:
        characteristics.append('- 高碳水饮食')
    elif avg_carbs < 150:
        characteristics.append('- 低碳水饮食')

    if not characteristics:
        characteristics.append('- 均衡饮食')

    return {
        'goal': goal,
        'avg_calories': avg_calories if avg_calories > 0 else '未知',
        'avg_protein': avg_protein if avg_protein > 0 else '未知',
        'avg_carbs': avg_carbs if avg_carbs > 0 else '未知',
        'avg_fat': avg_fat if avg_fat > 0 else '未知',
        'characteristics': '\n'.join(characteristics)
    }
