"""
训练计划 Prompt 工程模板库

为训练计划生成场景提供精心设计的 Prompt 模板
"""

import json

# ==================== 训练风格推断 ====================

def _infer_training_styles(goal: str) -> str:
    """
    根据训练目标推断合适的训练风格

    Args:
        goal: 训练目标 (muscle_gain, fat_loss, strength, etc.)

    Returns:
        训练风格描述字符串
    """
    style_map = {
        'muscle_gain': """- 金字塔递增：重量递增，次数递减（如 12→10→8→6），适合肌肉增长
- 低次数高重量：3-6次，适合力量和肌肉增长
- 递减组：力竭后立即减重继续，增加肌肉刺激
建议：以复合动作为主，重量逐渐递增，充分刺激目标肌群""",

        'fat_loss': """- 超级组：连续做两个动作不休息，提高代谢
- 高次数低重量：12-20次，提高心率和燃脂效果
- 间歇训练：高强度运动和休息交替，最大化燃脂
- 循环训练：多个动作循环进行，保持高心率
建议：减少休息时间，保持训练强度和心率""",

        'strength': """- 低次数高重量：3-6次，适合力量训练
- 金字塔递增：逐渐增加重量，提升最大力量
建议：以大重量复合动作为主，充分休息（90-180秒）""",

        'endurance': """- 高次数低重量：15-20次，提高肌肉耐力
- 循环训练：多个动作循环进行，提升心肺功能
- 间歇训练：提高有氧能力
建议：控制休息时间，保持较高训练量""",

        'athletic': """- 爆发力训练：快速动作，适合运动表现
- 功能性训练：结合多关节动作
- 间歇训练：提高爆发力和恢复能力
建议：动作选择多样化，注重速度和协调性""",

        'tone': """- 高次数低重量：12-20次，塑造肌肉线条
- 超级组：提高训练密度
- 循环训练：全身协调发展
建议：控制休息时间，注重动作质量""",
    }

    return style_map.get(goal, style_map['muscle_gain'])

# ==================== 系统角色定义 ====================

def get_system_prompt(language: str = '中文') -> str:
    """
    获取系统角色提示，支持多语言

    Args:
        language: 输出语言，如'中文'、'English'等

    Returns:
        系统角色提示字符串
    """
    return f"""你是一位专业的健身教练和训练计划设计专家，拥有多年的执教经验。

你的职责是：
1. 根据用户需求设计科学、合理、安全的训练计划
2. 考虑训练频率、强度、动作选择、组数次数等要素
3. 确保计划的可执行性和渐进性
4. 提供清晰的训练指导和注意事项

重要规则：
- 你必须以 JSON 格式返回结果
- 所有文本内容（包括动作名称、训练日名称、备注等）必须使用{language}输出
- 示例：中文输出 "深蹲"、"卧推"、"腿部训练"；英文输出 "Squats"、"Bench Press"、"Leg Day"
- 重量和次数使用数字字符串（如 "60kg", "10"）
- 确保 JSON 格式正确，可被解析
- 不要添加任何 JSON 之外的文字说明
"""

# 保持向后兼容的默认常量
SYSTEM_PROMPT = get_system_prompt('中文')

# ==================== 完整计划生成 ====================

FULL_PLAN_TEMPLATE = """用户需求：{prompt}

请设计一个完整的训练计划，包含多个训练日。

返回 JSON 格式如下：
{{
  "name": "计划名称",
  "description": "计划简介",
  "days": [
    {{
      "day": 1,
      "type": "腿部训练",
      "name": "下肢力量日",
      "exercises": [
        {{
          "name": "深蹲",
          "note": "注意保持背部挺直",
          "type": "strength",
          "sets": [
            {{"reps": "10", "weight": "60kg"}},
            {{"reps": "10", "weight": "60kg"}},
            {{"reps": "8", "weight": "70kg"}},
            {{"reps": "6", "weight": "80kg"}}
          ]
        }}
      ]
    }}
  ]
}}

要求：
1. 根据用户需求确定训练天数（3-7天）
2. 每天选择合适的训练类型（腿部训练、胸部训练、背部训练、肩部训练、手臂训练、休息日 等）
3. 每天3-6个动作
4. 每个动作3-5组
5. 组数和重量要递增或变化，体现训练强度
6. 添加适当的训练注意事项

现在请生成完整的训练计划："""

# ==================== 推荐下一个训练日 ====================

NEXT_DAY_TEMPLATE = """当前已有的训练日：
{existing_days}

用户目标：{goal}

基于已有的训练日，请推荐下一个合理的训练日。

返回 JSON 格式如下：
{{
  "day": 训练日序号,
  "type": "训练类型",
  "name": "训练名称",
  "exercises": [
    {{
      "name": "动作名称",
      "note": "注意事项",
      "type": "strength",
      "sets": [
        {{"reps": "次数", "weight": "重量"}}
      ]
    }}
  ]
}}

考虑因素：
1. 避免连续训练相同肌群
2. 保持训练的平衡性（推拉平衡、上下肢平衡）
3. 合理安排休息日
4. 动作选择要符合用户目标

现在请推荐下一个训练日："""

# ==================== 推荐动作 ====================

EXERCISES_TEMPLATE = """训练日类型：{day_type}

当前已有的动作：
{existing_exercises}

请推荐3-5个适合该训练日的动作。

返回 JSON 格式如下：
{{
  "exercises": [
    {{
      "name": "动作名称",
      "note": "注意事项",
      "type": "strength",
      "sets": [
        {{"reps": "10", "weight": "60kg"}},
        {{"reps": "10", "weight": "60kg"}},
        {{"reps": "8", "weight": "70kg"}}
      ]
    }}
  ]
}}

要求：
1. 动作要针对该训练日的目标肌群
2. 包含复合动作和孤立动作
3. 避免与已有动作重复
4. 提供合理的组数和重量建议

现在请推荐动作："""

# ==================== 推荐 Sets 配置 ====================

SETS_TEMPLATE = """动作名称：{exercise_name}
用户水平：{user_level}

请为该动作推荐合理的组数和重量配置。

返回 JSON 格式如下：
{{
  "sets": [
    {{"reps": "12", "weight": "50kg"}},
    {{"reps": "10", "weight": "60kg"}},
    {{"reps": "8", "weight": "70kg"}},
    {{"reps": "6", "weight": "80kg"}}
  ],
  "note": "重量建议和注意事项"
}}

要求：
1. 根据用户水平调整重量和次数
2. 通常3-5组
3. 可以采用金字塔递增或递减
4. 提供实用的重量建议

现在请推荐 Sets 配置："""

# ==================== 优化计划 ====================

OPTIMIZE_TEMPLATE = """当前训练计划：
{current_plan}

请分析并优化该训练计划，返回改进建议或优化后的完整计划。

返回 JSON 格式如下：
{{
  "suggestions": [
    "建议1：xxx",
    "建议2：xxx"
  ],
  "optimized_plan": {{
    "name": "优化后的计划名称",
    "description": "改进说明",
    "days": [...]
  }}
}}

分析维度：
1. 训练频率是否合理
2. 肌群分布是否平衡
3. 动作选择是否科学
4. 强度是否适中
5. 是否有过度训练的风险

现在请优化计划："""

# ==================== 结构化参数生成 ====================

STRUCTURED_PLAN_TEMPLATE = """基于以下明确的参数生成训练计划：

【基本信息】
训练目标: {goal}
训练水平: {level}

【训练安排】
训练部位: {muscle_groups}
每周天数: {days_per_week} 天
每次时长: {duration_minutes} 分钟

【训练强度】
训练量级别: {workload}
每天动作数: {exercises_per_day_min}-{exercises_per_day_max} 个
每个动作组数: {sets_per_exercise_min}-{sets_per_exercise_max} 组

【推荐训练风格】（AI 可根据实际情况灵活调整）
{training_styles}

【可用设备】
{equipment}

{additional_notes}

请严格按照以上参数生成训练计划，确保：
1. 训练天数恰好为 {days_per_week} 天
2. 每个训练日包含 {exercises_per_day_min}-{exercises_per_day_max} 个动作
3. 每个动作包含 {sets_per_exercise_min}-{sets_per_exercise_max} 组
4. 动作选择符合目标肌群和可用设备
5. 根据训练目标灵活运用推荐的训练风格，体现在组数、次数和休息时间配置中
6. 总训练量符合 {workload} 级别

返回 JSON 格式如下：
{{
  "name": "计划名称（基于目标和部位生成）",
  "description": "计划简介（说明目标、频率、特点）",
  "days": [
    {{
      "day": 1,
      "name": "训练日名称",
      "type": "训练类型（如：胸部训练）",
      "note": "训练要点",
      "exercises": [
        {{
          "name": "动作名称（如：深蹲、卧推）",
          "note": "动作要点",
          "type": "strength",
          "sets": [
            {{"reps": "次数", "weight": "重量"}}
          ]
        }}
      ]
    }}
  ]
}}

现在请生成训练计划："""

# ==================== 流式单天生成 Prompt ====================

SINGLE_DAY_PROMPT_TEMPLATE = """你是一位专业的私人健身教练，现在需要为客户设计第 {day} 天的训练计划。

**训练计划总体参数：**
- 训练目标: {goal}
- 训练水平: {level}
- 总训练天数: {total_days} 天
- 单次训练时长: {duration} 分钟
- 目标肌群: {muscle_groups}
- 训练强度: {workload}
- 推荐训练风格（可灵活调整）: {styles}
- 可用设备: {equipment}

**每天训练要求：**
- 动作数量: {exercises_min}-{exercises_max} 个
- 每个动作组数: {sets_min}-{sets_max} 组

{notes_section}

**今日训练重点：**
{day_focus}

**已完成的训练日：**
{previous_days_summary}

{exercise_library_section}

**请按照以下要求设计今天的训练计划：**

1. **训练主题**：为今天选择一个合适的训练主题（如"胸+肱三头肌", "腿部力量", "核心稳定"等）

2. **动作选择**：
   - 选择 {exercises_min}-{exercises_max} 个动作
   {exercise_selection_rule}
   - 确保动作多样性，避免与之前重复
   - 考虑训练目标和可用设备
   - 兼顾主动肌群和协同肌群

3. **组数和次数**：
   - 每个动作设计 {sets_min}-{sets_max} 组
   - 根据训练目标设置合适的次数范围（力量8-12次，增肌10-15次，耐力15-20次）
   - 设置合理的休息时间（力量90-180秒，增肌60-90秒，耐力30-60秒）

4. **训练时长**：确保总训练时长控制在约 {duration} 分钟内

5. **注意事项**：提供2-3条今天训练的重点提示

**请使用 create_training_day 工具返回结构化的训练计划。**
"""

# ==================== Prompt 构建函数 ====================


def build_full_plan_prompt(user_prompt: str, language: str = '中文') -> tuple:
    """构建完整计划生成的 Prompt"""
    system = get_system_prompt(language)
    user = FULL_PLAN_TEMPLATE.format(prompt=user_prompt)
    return system, user


def build_next_day_prompt(existing_days: list, goal: str, language: str = '中文') -> tuple:
    """构建推荐下一天的 Prompt"""
    # 格式化已有训练日
    days_str = ""
    for day in existing_days:
        days_str += f"Day {day.get('day', '?')}: {day.get('type', '未知')} - {day.get('name', '')}\n"
        exercises = day.get('exercises', [])
        for ex in exercises:
            days_str += f"  - {ex.get('name', '?')}\n"

    system = get_system_prompt(language)
    user = NEXT_DAY_TEMPLATE.format(
        existing_days=days_str if days_str else "（无）",
        goal=goal
    )
    return system, user


def build_exercises_prompt(day_type: str, existing_exercises: list, language: str = '中文') -> tuple:
    """构建推荐动作的 Prompt"""
    # 格式化已有动作
    exercises_str = ""
    for ex in existing_exercises:
        exercises_str += f"- {ex.get('name', '?')}\n"

    system = get_system_prompt(language)
    user = EXERCISES_TEMPLATE.format(
        day_type=day_type,
        existing_exercises=exercises_str if exercises_str else "（无）"
    )
    return system, user


def build_sets_prompt(exercise_name: str, user_level: str = "中级", language: str = '中文') -> tuple:
    """构建推荐 Sets 的 Prompt"""
    system = get_system_prompt(language)
    user = SETS_TEMPLATE.format(
        exercise_name=exercise_name,
        user_level=user_level
    )
    return system, user


def build_optimize_prompt(current_plan: dict, language: str = '中文') -> tuple:
    """构建优化计划的 Prompt"""
    plan_str = json.dumps(current_plan, ensure_ascii=False, indent=2)

    system = get_system_prompt(language)
    user = OPTIMIZE_TEMPLATE.format(current_plan=plan_str)
    return system, user


def build_structured_plan_prompt(params: dict) -> tuple:
    """
    构建结构化参数生成的 Prompt

    Args:
        params: 包含所有参数的字典
            - goal: str (训练目标)
            - level: str (训练水平)
            - muscle_groups: list (肌肉群列表)
            - days_per_week: int
            - duration_minutes: int
            - workload: str (训练量级别)
            - exercises_per_day_min: int
            - exercises_per_day_max: int
            - sets_per_exercise_min: int
            - sets_per_exercise_max: int
            - training_styles: list
            - equipment: list
            - notes: str (可选)
            - language: str (输出语言，可选，默认'中文')

    Returns:
        (system_prompt, user_prompt)
    """
    # 提取语言参数
    language = params.get('language', '中文')

    # 格式化肌肉群
    muscle_groups_str = ', '.join(params.get('muscle_groups', []))

    # 根据目标推断训练风格
    goal = params.get('goal', 'muscle_gain')
    training_styles_str = _infer_training_styles(goal)

    # 格式化设备
    equipment = params.get('equipment', [])
    if equipment:
        equipment_str = '\n'.join([f'- {eq}' for eq in equipment])
    else:
        equipment_str = '- 全部设备'

    # 格式化补充说明
    notes = params.get('notes', '')
    if notes:
        additional_notes = f"【特殊要求】\n{notes}"
    else:
        additional_notes = ""

    system = get_system_prompt(language)
    user = STRUCTURED_PLAN_TEMPLATE.format(
        goal=params.get('goal', '增肌'),
        level=params.get('level', '中级'),
        muscle_groups=muscle_groups_str,
        days_per_week=params.get('days_per_week', 3),
        duration_minutes=params.get('duration_minutes', 60),
        workload=params.get('workload', '中等'),
        exercises_per_day_min=params.get('exercises_per_day_min', 4),
        exercises_per_day_max=params.get('exercises_per_day_max', 6),
        sets_per_exercise_min=params.get('sets_per_exercise_min', 3),
        sets_per_exercise_max=params.get('sets_per_exercise_max', 5),
        training_styles=training_styles_str,
        equipment=equipment_str,
        additional_notes=additional_notes
    )

    return system, user


def build_single_day_prompt(
    day: int,
    params: dict,
    previous_days: list = None,
    exercise_templates: list = None
) -> str:
    """
    构建单天训练计划的 Prompt

    Args:
        day: 当前是第几天
        params: 训练参数字典
        previous_days: 已完成的训练日列表（可选）
        exercise_templates: 动作库模板列表（可选）

    Returns:
        完整的单天生成 Prompt
    """
    # 目标肌群
    muscle_groups_text = "、".join(params.get('muscle_groups', []))

    # 根据目标推断训练风格
    goal = params.get('goal', 'muscle_gain')
    styles_text = _infer_training_styles(goal)

    # 可用设备
    equipment_text = "、".join(params.get('equipment', [])) if params.get('equipment') else "不限"

    # 补充说明
    notes = params.get('notes', '')
    notes_section = f"\n**补充说明：**\n{notes}\n" if notes else ""

    # 今日训练重点（根据天数和总天数自动分配）
    total_days = params.get('days_per_week', 3)
    day_focus = _generate_day_focus(day, total_days, params)

    # 已完成训练日总结
    previous_days_summary = _summarize_previous_days(previous_days) if previous_days else "无（这是第一天）"

    # 动作库列表（如果提供）
    exercise_library_section, exercise_selection_rule = _format_exercise_library(exercise_templates)

    return SINGLE_DAY_PROMPT_TEMPLATE.format(
        day=day,
        goal=params.get('goal', ''),
        level=params.get('level', ''),
        total_days=total_days,
        duration=params.get('duration_minutes', 60),
        muscle_groups=muscle_groups_text,
        workload=params.get('workload', ''),
        styles=styles_text,
        equipment=equipment_text,
        exercises_min=params.get('exercises_per_day_min', 4),
        exercises_max=params.get('exercises_per_day_max', 6),
        sets_min=params.get('sets_per_exercise_min', 3),
        sets_max=params.get('sets_per_exercise_max', 5),
        notes_section=notes_section,
        day_focus=day_focus,
        previous_days_summary=previous_days_summary,
        exercise_library_section=exercise_library_section,
        exercise_selection_rule=exercise_selection_rule,
    )


def _generate_day_focus(day: int, total_days: int, params: dict) -> str:
    """
    根据天数和参数生成今日训练重点

    Args:
        day: 当前天数
        total_days: 总天数
        params: 训练参数

    Returns:
        今日训练重点描述
    """
    muscle_groups = params.get('muscle_groups', [])

    # 根据总天数和当前天数分配重点
    if total_days <= 3:
        # 3天计划：上肢、下肢、全身
        if day == 1:
            return "上半身推拉动作，重点训练胸背肩"
        elif day == 2:
            return "下半身力量，重点训练腿臀"
        else:
            return "全身综合训练或薄弱部位强化"

    elif total_days <= 5:
        # 5天计划：胸、背、腿、肩臂、核心
        focus_map = {
            1: "胸部和肱三头肌",
            2: "背部和肱二头肌",
            3: "腿部和臀部",
            4: "肩部和手臂",
            5: "核心和全身耐力",
        }
        return f"重点训练：{focus_map.get(day, '综合训练')}"

    else:
        # 6+天计划：更精细的分化
        day_mod = ((day - 1) % 6) + 1
        focus_map = {
            1: "胸部（上胸、中胸、下胸）",
            2: "背部（上背、中背、下背）",
            3: "腿部前侧（股四头肌）",
            4: "肩部（前束、中束、后束）",
            5: "手臂（肱二头肌、肱三头肌）",
            6: "腿部后侧和臀部",
        }
        return f"重点训练：{focus_map.get(day_mod, '综合训练')}"


def _summarize_previous_days(previous_days: list) -> str:
    """
    总结已完成的训练日

    Args:
        previous_days: 已完成的训练日数据列表

    Returns:
        训练日总结文本
    """
    if not previous_days:
        return "无（这是第一天）"

    summary_lines = []
    for day_data in previous_days:
        day_num = day_data.get('day', '?')
        day_name = day_data.get('name', '未命名')
        exercises = day_data.get('exercises', [])
        exercise_names = [ex.get('name', '未知') for ex in exercises[:3]]  # 只列出前3个

        if len(exercises) > 3:
            exercise_text = f"{', '.join(exercise_names)}等{len(exercises)}个动作"
        else:
            exercise_text = ', '.join(exercise_names)

        summary_lines.append(f"- 第{day_num}天：{day_name}（{exercise_text}）")

    return '\n'.join(summary_lines)


def _format_exercise_library(exercise_templates: list) -> tuple:
    """
    格式化动作库列表

    Args:
        exercise_templates: 动作模板列表，每个模板包含 id, name 和 tags

    Returns:
        (exercise_library_section, exercise_selection_rule) 元组
    """
    if not exercise_templates or len(exercise_templates) == 0:
        return ("", "- 可以自由选择适合的动作")

    # 格式化动作库列表
    exercise_lines = []
    for template in exercise_templates:
        name = template.get('name', '未知动作')
        template_id = template.get('id', '')
        tags = template.get('tags', [])
        tags_text = f"（{', '.join(tags)}）" if tags else ""
        # 包含 ID
        exercise_lines.append(f"   - {name} [ID: {template_id}]{tags_text}")

    exercise_list_text = '\n'.join(exercise_lines)

    library_section = f"""
**可用动作库（共 {len(exercise_templates)} 个动作）：**
{exercise_list_text}
"""

    # 更新选择规则
    selection_rule = "- **重要：必须从上述动作库中选择动作，并在返回数据的 exerciseTemplateId 字段中填入对应的 ID**"

    return (library_section, selection_rule)


def _format_exercise_library_for_edit(exercise_templates: list) -> str:
    """
    格式化动作库列表用于编辑对话

    Args:
        exercise_templates: 动作模板列表，包含 id, name, tags

    Returns:
        格式化的动作库文本
    """
    if not exercise_templates:
        return ""

    lines = ["**教练的动作库（可选择）**："]
    for template in exercise_templates:
        name = template.get('name', '')
        tags = template.get('tags', [])
        tags_text = f"（{', '.join(tags)}）" if tags else ""
        lines.append(f"   - {name}{tags_text}")

    lines.append("\n**说明**：修改/新增动作时，优先从上述库中选择。如需使用新动作，直接提供名称，系统会自动创建模板。")

    return '\n'.join(lines)


# ==================== 编辑对话 Prompts ====================

def build_edit_conversation_prompt(
    user_message: str,
    current_plan: dict,
    user_memory: str,
    conversation_history: list,
    exercise_templates: list = None,
    language: str = '中文'
) -> tuple[str, str]:
    """
    构建编辑对话的 Prompt

    Args:
        user_message: 用户的修改请求
        current_plan: 当前完整计划数据
        user_memory: 用户的 memory context
        conversation_history: 最近的对话历史
        exercise_templates: 动作库模板列表（可选）
        language: 输出语言

    Returns:
        (system_prompt, user_prompt) 元组
    """

    # 统一的System Prompt，让Claude自主判断用户意图
    system_prompt = f"""你是一位专业的健身教练和训练计划顾问。

**你的核心能力**：
1. 理解用户的各种需求和问题
2. 提供专业的健身建议和训练指导
3. 当用户需要时，生成详细的训练计划修改建议

**用户背景信息**：
{user_memory}

---

## 🎯 关键规则：根据用户意图智能选择回复方式

### **场景A：用户想要【修改/调整/编辑】训练计划**

**识别标志**（包括但不限于）：
- 明确的修改动词：修改、改成、调整、增加、删除、替换、换成
- 具体的操作指令：降低重量、提高强度、添加动作、移除某天
- 示例：
  * "降低所有重量10%"
  * "增加一天腿部训练"
  * "把深蹲换成腿举"

**执行动作**：使用 'edit_plan' 工具返回结构化修改建议

**工具输出要求**：
- analysis: 简要分析用户的修改意图（1-2句话）
- changes: 详细修改列表（每个change包含type, description, reason, before, after, day_index等）
- summary: 修改总结（可选）

---

### **场景B：用户只是【提问/咨询/探讨】**

**识别标志**（包括但不限于）：
- 疑问词开头：为什么、如何、什么、哪个、是否
- 请求解释：解释一下、说明、告诉我
- 寻求建议：有什么建议、应该怎么做、如何改进
- 评估请求：这个计划怎么样、强度如何、合理吗
- 示例：
  * "为什么选择深蹲作为第一个动作？"
  * "这个计划的强度适合我吗？"
  * "有更好的动作建议吗？"
  * "如何提高训练效果？"

**执行动作**：直接以文本形式回复，**不使用工具**

**回复要求**：
- 语气：专业、友好、耐心
- 长度：100-200字
- 结构：条理清晰，分点说明
- 内容：结合用户背景和训练偏好
- **⚠️ 重要**：直接给出答案，不要输出判断过程（如"这是场景B"、"我将以文本形式回复"等元信息）

---

### **场景C：模糊意图或边界情况** ⚠️ 缓解机制1

**识别标志**：
- 既包含询问又暗示可能修改，如："有没有更好的动作？"
- 建议类问题："应该增加一些核心训练吗？"
- 评估后可能修改："这个计划强度会不会太大？"

**执行策略**：
1. **优先文本回复**（不使用工具）
2. 在回复中**明确询问**用户是否需要应用修改
3. **⚠️ 重要**：直接给出分析和建议，不要输出判断过程
4. 示例回复格式：
   ```
   [专业分析和建议]

   如果您希望我为您应用这些改动，请告诉我"请修改计划"或具体说明您想要的调整。
   ```

---

### **场景D：Claude自身判断失误** ⚠️ 缓解机制2

**如果Claude误判为修改请求但用户只想聊天**：
- 用户会看到修改确认卡片（前端UI）
- 用户可以点击"拒绝"按钮，继续对话
- **无实际风险**，因为前端有确认机制保护

**如果Claude误判为聊天但用户想修改**：
- Claude在文本回复中引导用户
- 用户可以再次明确表达修改意图
- 示例："如果您需要我应用这个修改，请明确告诉我'修改计划'。"

---

## 📌 关键判断原则（总结）

1. **明确的动作指令** → edit_plan 工具
2. **纯粹的问题咨询** → 文本回复
3. **模糊的边界情况** → 文本回复 + 询问引导
4. **不确定时的默认** → 文本回复（安全选择）

**⚠️ 输出规范**：
- 使用 edit_plan 工具时：判断逻辑放在 analysis 字段中（用户会看到）
- 文本回复时：**直接输出答案内容**，不要暴露判断过程（如"根据分析这是场景B"、"我将使用文本回复"等元信息）
- 所有输出必须使用 **{language}** 语言
"""

    # User Prompt
    # 1. 构建对话历史部分
    history_text = ""
    if conversation_history:
        history_text = "**最近的对话：**\n"
        for conv in conversation_history[-3:]:  # 只包含最近3条
            user_msg = conv.get('user_message', '')
            ai_msg = conv.get('ai_response', '')[:100]  # AI响应截断
            history_text += f"- 用户：{user_msg}\n- AI：{ai_msg}...\n\n"

    # 2. 构建当前计划摘要
    plan_name = current_plan.get('name', '未命名计划')
    plan_days = current_plan.get('days', [])
    plan_summary = f"**当前计划：{plan_name}**\n共 {len(plan_days)} 个训练日\n\n"

    for day in plan_days:
        day_num = day.get('day', '?')
        day_name = day.get('name', '未命名')
        exercises = day.get('exercises', [])
        exercise_list = ', '.join([ex.get('name', '未知') for ex in exercises[:5]])
        if len(exercises) > 5:
            exercise_list += f" 等{len(exercises)}个动作"

        plan_summary += f"第{day_num}天：{day_name}\n  动作：{exercise_list}\n\n"

    # 3. 动作库列表（如果提供）
    exercise_library_text = ""
    if exercise_templates:
        exercise_library_text = f"\n\n{_format_exercise_library_for_edit(exercise_templates)}\n"

    # 4. 统一的 User Prompt
    user_prompt = f"""{history_text}

{plan_summary}

{exercise_library_text}

**用户的消息：**
{user_message}

---

**请按照以下步骤处理：**

1. **分析用户意图**：
   - 用户是想修改计划，还是只是提问/咨询？
   - 参考System Prompt中的场景A/B/C分类

2. **选择合适的回复方式**：
   - 修改计划 → 使用 edit_plan 工具（包含analysis, changes, summary）
   - 提问咨询 → 直接文本回复（专业、友好、200-300字）
   - 模糊意图 → 文本回复 + 询问是否需要应用修改

3. **如果使用 edit_plan 工具**：

   **changes 数组要求（必须详尽）**：
   - 每个需要修改的地方都要生成一个 change 对象
   - 必填字段：type, description, reason, day_index
   - before/after 字段：
     * modify_exercise 类型：before和after必须使用完整的exercise对象（包含name, note, sets）
     * modify_exercise_sets 类型：使用数组格式
     * add_day/add_exercise 类型：after使用完整JSON对象
     * 其他类型：使用字符串描述

   **示例 - 修改动作（名称、训练组）**：
   ```json
   {{
     "type": "modify_exercise",
     "day_index": 0,
     "exercise_index": 4,
     "description": "将绳索下压替换为双杠臂屈伸，并调整训练参数",
     "before": {{
       "name": "绳索下压",
       "sets": [{{"reps": "12", "weight": "60kg"}}, {{"reps": "12", "weight": "65kg"}}, {{"reps": "10", "weight": "70kg"}}]
     }},
     "after": {{
       "name": "双杠臂屈伸",
       "sets": [{{"reps": "10", "weight": "体重"}}, {{"reps": "10", "weight": "体重"}}, {{"reps": "8", "weight": "体重+5kg"}}]
     }},
     "reason": "双杠臂屈伸能够更全面地激活肱三头肌三个头，且允许更大的动作幅度"
   }}
   ```

现在开始处理用户的消息。
"""

    return system_prompt, user_prompt
