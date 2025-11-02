# AI引导创建补剂计划 - 实施文档

**创建日期**: 2025-01-02
**最后更新**: 2025-01-02
**功能**: AI对话式创建补剂计划（基于训练和饮食计划）
**状态**: 🚧 进行中 (81%完成)

---

## 📋 功能概述

实现使用Claude AI通过对话方式生成补剂计划的功能。用户通过两步选择流程（训练计划 → 饮食计划）或单步选择，让AI基于现有计划推荐补剂方案。

### 核心特性

- ✅ **对话式交互**：所有选择和交互在chat对话内完成
- ✅ **两步选择流程**：先选训练计划，再选饮食计划
- ✅ **单步选择支持**：仅根据训练计划或仅根据饮食计划推荐
- ✅ **基于现有计划**：使用`_get_plan()`和`_get_diet_plan()`获取完整数据
- ✅ **流式生成**：SSE实时推送AI思考过程
- ✅ **默认生成一天**：everyday same（所有天复用同一方案）

---

## 🏗️ 架构设计

### 技术栈

**后端:**
- Python Cloud Functions (Firebase 2nd gen)
- Claude API with Streaming
- Firestore (获取现有plans)

**前端:**
- Flutter + Cupertino UI (70% height modal sheet)
- Riverpod 2.x (状态管理)
- SSE流式处理

---

## 🎨 用户体验流程

```
用户点击 ✨ Sparkle按钮（非编辑模式）
    ↓
70% Sheet弹出，显示AI欢迎消息
    ↓
快捷选项显示：
  • [图标] 根据训练和饮食计划推荐 ← 两步选择
  • [图标] 仅根据训练计划推荐      ← 单步选择
  • [图标] 仅根据饮食计划推荐      ← 单步选择
  • [图标] 基础套餐                ← 无需选择
    ↓
【场景1：两步选择】
用户点击"根据训练和饮食计划推荐"
    ↓
[User] "根据训练和饮食计划推荐"
    ↓
[AI] "好的！首先请选择训练计划："
┌─────────────────────────────┐
│ 📋 增肌训练计划 A           │ ← 可点击卡片
│ 5天 · 创建于2025-01-15      │
└─────────────────────────────┘
┌─────────────────────────────┐
│ 📋 减脂训练计划 B           │
│ 4天 · 创建于2025-01-10      │
└─────────────────────────────┘
    ↓ 用户点击
[User] "我选择「增肌训练计划A」"
    ↓
[AI] "很好！接下来请选择饮食计划："
┌─────────────────────────────┐
│ 🍽️ 增肌饮食计划 A           │
│ 7天 · 创建于2025-01-15      │
└─────────────────────────────┘
    ↓ 用户点击
[User] "我选择「增肌饮食计划A」"
    ↓
[AI] "正在分析您的训练强度和营养摄入..."
    ↓
[AI] "我为您推荐以下补剂方案："
┌─────────────────────────────┐
│ 📦 建议的补剂方案（1天）    │
│ ── 早餐前 ──                │
│ • 肌酸 5g                   │
│ ── 训练后 ──                │
│ • 蛋白粉 30g                │
│ • BCAA 10g                  │
│ ── 睡前 ──                  │
│ • 酪蛋白 25g                │
│                             │
│ [预览] [拒绝] [应用]        │
└─────────────────────────────┘
    ↓ 用户点击[应用]
Sheet关闭，补剂计划页面显示生成的计划（所有天复用同一方案）
```

---

## 📂 文件清单

### 后端新增/修改文件（5个）

#### 1. `functions/ai/tools.py` ✏️ 修改

**新增函数**: `get_supplement_day_tool()`

```python
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
```

---

#### 2. `functions/ai/supplement_plan/prompts.py` ✨ 新建文件

**功能**: 构建补剂推荐的system prompt和user prompt

```python
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
```

---

#### 3. `functions/ai/streaming.py` ✏️ 修改

**新增函数**: `stream_generate_supplement_plan_conversation()`

```python
def stream_generate_supplement_plan_conversation(
    user_id: str,
    user_message: str,
    training_plan: Optional[Dict[str, Any]],
    diet_plan: Optional[Dict[str, Any]],
    conversation_history: List[Dict[str, str]]
) -> Generator[Dict[str, Any], None, None]:
    """
    流式处理补剂计划生成对话

    Args:
        user_id: 用户ID
        user_message: 用户的请求消息
        training_plan: 训练计划数据（可选）
        diet_plan: 饮食计划数据（可选）
        conversation_history: 对话历史

    Yields:
        dict: 流式事件
            - type: 'thinking' | 'analysis' | 'suggestion' | 'complete' | 'error'
            - content: 内容（thinking 和 analysis 时）
            - data: 数据（suggestion 时，包含 SupplementDay）
            - error: 错误信息（error 时）
    """
    try:
        logger.info(f'🔄 [Supplement] 开始处理补剂计划对话 - User: {user_id}')
        logger.info(f'用户请求: {user_message[:100]}...')

        # 1. 获取用户 memory（可选，用于记住用户偏好）
        logger.info('📖 加载用户 Memory')
        from .memory_manager import MemoryManager
        profile = MemoryManager.get_user_memory(user_id)
        language = profile.language_preference

        logger.info(f'🌐 语言设置: {language}')

        # 发送思考事件
        yield {
            'type': 'thinking',
            'content': '正在分析您的需求...'
        }

        # 2. 构建 Prompt
        logger.info('📝 构建补剂计划生成 Prompt')
        from .supplement_plan.prompts import build_supplement_creation_prompt

        system_prompt, user_prompt = build_supplement_creation_prompt(
            user_message=user_message,
            training_plan=training_plan,
            diet_plan=diet_plan,
            conversation_history=conversation_history,
            language=language
        )

        logger.info(f'System Prompt 长度: {len(system_prompt)} 字符')
        logger.info(f'User Prompt 长度: {len(user_prompt)} 字符')

        # 3. 调用 Claude Streaming API
        logger.info('🔄 开始调用 Claude Streaming API')
        from .claude_client import get_claude_client
        from .tools import get_supplement_day_tool

        claude_client = get_claude_client()
        tool = get_supplement_day_tool()
        tools = [tool]

        tool_input = None
        text_content = ""
        event_count = 0

        for event in claude_client.call_claude_streaming(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            tools=tools
        ):
            event_count += 1
            event_type = event.get('type')
            logger.debug(f'📨 [Supplement Event #{event_count}] type={event_type}')

            # 文本内容（思考过程）
            if event_type == 'text_delta':
                text_delta = event.get('text', '')
                text_content += text_delta
                logger.debug(f'📝 text_delta长度: {len(text_delta)}')

                if text_delta:
                    yield {
                        'type': 'thinking',
                        'content': text_delta
                    }

            # Tool 调用开始
            elif event_type == 'tool_start':
                tool_name = event.get('tool_name')
                logger.info(f'🔧 Tool 调用开始: {tool_name}')

                yield {
                    'type': 'analysis',
                    'content': '正在生成补剂方案...'
                }

            # Tool 调用完成
            elif event_type == 'tool_complete':
                tool_input = event.get('tool_input', {})
                logger.info('✅ Tool 调用完成')
                logger.debug(f'Tool 输出: {json.dumps(tool_input, ensure_ascii=False, indent=2)[:500]}...')

                # 提取补剂方案数据
                analysis = tool_input.get('analysis', '')
                day_name = tool_input.get('day_name', '标准补剂日')
                timings = tool_input.get('timings', [])
                summary = tool_input.get('summary', '')

                logger.info(f'📊 Tool 输出字段检查:')
                logger.info(f'  - analysis: {"✅" if analysis else "❌"} ({len(analysis)} 字符)')
                logger.info(f'  - day_name: {day_name}')
                logger.info(f'  - timings: {"✅" if timings else "❌"} ({len(timings)} 个时间段)')
                logger.info(f'  - summary: {"✅" if summary else "❌"} ({len(summary)} 字符)')

                # 发送分析结果
                if analysis:
                    yield {
                        'type': 'analysis',
                        'content': analysis
                    }

                # 构建 SupplementDay 数据
                supplement_day_data = {
                    'day': 1,
                    'name': day_name,
                    'timings': timings,
                    'completed': False
                }

                # 发送补剂方案建议
                yield {
                    'type': 'suggestion',
                    'data': {
                        'supplement_day': supplement_day_data,
                        'summary': summary
                    }
                }

            elif event_type == 'error':
                error_msg = event.get('error', '未知错误')
                logger.error(f'❌ Claude API 返回错误: {error_msg}')
                raise Exception(error_msg)

        logger.info(f'📊 共收到 {event_count} 个事件')

        # 检查是否为纯文本响应
        if not tool_input and text_content:
            logger.info('📝 检测到纯文本响应')
            yield {
                'type': 'analysis',
                'content': text_content
            }

        # 保存对话历史
        logger.info('💾 保存对话历史到 Memory')
        ai_response_summary = tool_input.get('summary', '') if tool_input else text_content[:200]
        MemoryManager.update_conversation_history(
            user_id=user_id,
            user_message=user_message,
            ai_response=ai_response_summary,
            context={'type': 'supplement_creation'}
        )

        # 完成
        logger.info('🎉 补剂计划对话处理完成')
        yield {
            'type': 'complete',
            'message': '补剂方案已生成'
        }

    except Exception as e:
        logger.error(f'❌ 补剂计划对话处理失败: {str(e)}', exc_info=True)
        yield {
            'type': 'error',
            'error': f'处理失败: {str(e)}'
        }
```

---

#### 4. `functions/ai/handlers.py` ✏️ 修改

**新增函数**: `generate_supplement_plan_conversation`

在文件末尾添加：

```python
@https_fn.on_request(cors=cors)
def generate_supplement_plan_conversation(req: https_fn.Request):
    """
    补剂计划对话生成（SSE流式）

    HTTP POST /generate_supplement_plan_conversation

    请求体:
    {
      "user_id": str,
      "user_message": str,
      "training_plan_id": str (可选),
      "diet_plan_id": str (可选),
      "conversation_history": List[dict] (可选)
    }

    响应: Server-Sent Events
    data: {"type": "thinking", "content": "..."}
    data: {"type": "analysis", "content": "..."}
    data: {"type": "suggestion", "data": {...}}
    data: {"type": "complete"}
    """
    try:
        # 解析请求数据
        data = req.get_json()
        user_id = data.get('user_id')
        user_message = data.get('user_message')
        training_plan_id = data.get('training_plan_id')
        diet_plan_id = data.get('diet_plan_id')
        conversation_history = data.get('conversation_history', [])

        if not user_id or not user_message:
            return Response(
                f'data: {json.dumps({"type": "error", "error": "缺少必需参数"})}\n\n',
                mimetype='text/event-stream'
            )

        logger.info(f'💊 补剂计划对话 - User: {user_id}, Message: {user_message[:50]}...')

        # 获取训练计划和饮食计划
        training_plan = None
        diet_plan = None

        db = firestore.client()

        # 获取训练计划（使用 _get_plan）
        if training_plan_id:
            try:
                plan_ref = db.collection('exercisePlans').document(training_plan_id)
                plan_doc = plan_ref.get()
                if plan_doc.exists:
                    training_plan = plan_doc.to_dict()
                    # 验证权限
                    if training_plan.get('ownerId') != user_id:
                        logger.warning(f'⚠️ 用户 {user_id} 无权访问训练计划 {training_plan_id}')
                        training_plan = None
                    else:
                        logger.info(f'✅ 获取训练计划成功: {training_plan.get("name")}')
            except Exception as e:
                logger.error(f'❌ 获取训练计划失败: {str(e)}')

        # 获取饮食计划（使用 _get_diet_plan）
        if diet_plan_id:
            try:
                plan_ref = db.collection('dietPlans').document(diet_plan_id)
                plan_doc = plan_ref.get()
                if plan_doc.exists:
                    diet_plan = plan_doc.to_dict()
                    # 验证权限
                    if diet_plan.get('ownerId') != user_id:
                        logger.warning(f'⚠️ 用户 {user_id} 无权访问饮食计划 {diet_plan_id}')
                        diet_plan = None
                    else:
                        logger.info(f'✅ 获取饮食计划成功: {diet_plan.get("name")}')
            except Exception as e:
                logger.error(f'❌ 获取饮食计划失败: {str(e)}')

        # 如果没有提供ID，尝试获取最新的plans（可选）
        if not training_plan:
            logger.info('📋 未提供训练计划ID，尝试获取最新训练计划')
            from plans.handlers import _get_coach_plans
            plans = _get_coach_plans(db, user_id, 'exercisePlans')
            if plans:
                training_plan = plans[0]
                logger.info(f'✅ 使用最新训练计划: {training_plan.get("name")}')

        if not diet_plan:
            logger.info('🍽️ 未提供饮食计划ID，尝试获取最新饮食计划')
            from plans.handlers import _get_coach_plans
            plans = _get_coach_plans(db, user_id, 'dietPlans')
            if plans:
                diet_plan = plans[0]
                logger.info(f'✅ 使用最新饮食计划: {diet_plan.get("name")}')

        # 调用流式生成
        from .streaming import stream_generate_supplement_plan_conversation

        def generate():
            for event in stream_generate_supplement_plan_conversation(
                user_id=user_id,
                user_message=user_message,
                training_plan=training_plan,
                diet_plan=diet_plan,
                conversation_history=conversation_history
            ):
                yield f'data: {json.dumps(event, ensure_ascii=False)}\n\n'

        return Response(
            generate(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'X-Accel-Buffering': 'no'
            }
        )

    except Exception as e:
        logger.error(f'❌ 补剂计划对话失败: {str(e)}', exc_info=True)
        return Response(
            f'data: {json.dumps({"type": "error", "error": str(e)})}\n\n',
            mimetype='text/event-stream'
        )
```

---

#### 5. `functions/main.py` ✏️ 修改

**修改内容**: 导出新函数

在 `__all__` 列表中添加：

```python
from ai.handlers import (
    # ... 现有导出
    generate_supplement_plan_conversation,  # ✨ 新增
)

__all__ = [
    # ... 现有导出
    'generate_supplement_plan_conversation',  # ✨ 新增
]
```

---

### 前端新增/修改文件（11个）

#### 6. `lib/features/coach/plans/data/models/llm_chat_message.dart` ✏️ 修改

**修改内容**: 添加交互式选项支持

```dart
// ✨ 在文件开头添加 InteractiveOption 类
class InteractiveOption {
  final String id;           // plan_id
  final String label;        // "增肌训练计划 A"
  final String? subtitle;    // "5天 · 创建于2025-01-15"
  final String type;         // 'training_plan' | 'diet_plan'
  final Map<String, dynamic>? metadata;

  const InteractiveOption({
    required this.id,
    required this.label,
    this.subtitle,
    required this.type,
    this.metadata,
  });

  factory InteractiveOption.fromJson(Map<String, dynamic> json) {
    return InteractiveOption(
      id: json['id'] as String,
      label: json['label'] as String,
      subtitle: json['subtitle'] as String?,
      type: json['type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'subtitle': subtitle,
      'type': type,
      'metadata': metadata,
    };
  }
}

// ✨ 修改 LLMChatMessage 类，添加新字段
class LLMChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final PlanEditSuggestion? suggestion;

  // ✨ 新增字段
  final List<InteractiveOption>? options;
  final String? interactionType;  // 'plan_selection' | null

  const LLMChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.suggestion,
    this.options,          // ✨ 新增
    this.interactionType,  // ✨ 新增
  });

  // ✨ 更新 fromJson
  factory LLMChatMessage.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>?;
    final options = optionsJson?.map((o) =>
      InteractiveOption.fromJson(o as Map<String, dynamic>)
    ).toList();

    return LLMChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestion: json['suggestion'] != null
          ? PlanEditSuggestion.fromJson(json['suggestion'] as Map<String, dynamic>)
          : null,
      options: options,
      interactionType: json['interactionType'] as String?,
    );
  }

  // ✨ 更新 toJson
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'suggestion': suggestion?.toJson(),
      'options': options?.map((o) => o.toJson()).toList(),
      'interactionType': interactionType,
    };
  }

  // ✨ 更新 copyWith
  LLMChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    PlanEditSuggestion? suggestion,
    List<InteractiveOption>? options,
    String? interactionType,
  }) {
    return LLMChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      suggestion: suggestion ?? this.suggestion,
      options: options ?? this.options,
      interactionType: interactionType ?? this.interactionType,
    );
  }
}
```

---

#### 7. `lib/features/coach/plans/data/models/supplement_stream_event.dart` ✨ 新建文件

```dart
/// 补剂计划流式生成事件
class SupplementStreamEvent {
  final String type;  // 'thinking' | 'analysis' | 'suggestion' | 'complete' | 'error'
  final String? content;
  final Map<String, dynamic>? data;
  final String? error;

  const SupplementStreamEvent({
    required this.type,
    this.content,
    this.data,
    this.error,
  });

  factory SupplementStreamEvent.fromJson(Map<String, dynamic> json) {
    return SupplementStreamEvent(
      type: json['type'] as String,
      content: json['content'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  bool get isThinking => type == 'thinking';
  bool get isAnalysis => type == 'analysis';
  bool get isSuggestion => type == 'suggestion';
  bool get isComplete => type == 'complete';
  bool get isError => type == 'error';

  @override
  String toString() {
    return 'SupplementStreamEvent(type: $type, hasContent: ${content != null}, hasData: ${data != null})';
  }
}
```

---

#### 8. `lib/features/coach/plans/data/models/supplement_creation_state.dart` ✨ 新建文件

```dart
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';

/// 补剂计划创建状态
class SupplementCreationState {
  final List<LLMChatMessage> messages;
  final bool isAIResponding;
  final SupplementDay? pendingSuggestion;
  final String? errorMessage;
  final bool canSendMessage;

  // 多步选择状态
  final SelectionStep? currentSelectionStep;
  final String? selectedTrainingPlanId;
  final String? selectedDietPlanId;
  final String? selectedTrainingPlanName;
  final String? selectedDietPlanName;

  const SupplementCreationState({
    this.messages = const [],
    this.isAIResponding = false,
    this.pendingSuggestion,
    this.errorMessage,
    this.canSendMessage = true,
    this.currentSelectionStep,
    this.selectedTrainingPlanId,
    this.selectedDietPlanId,
    this.selectedTrainingPlanName,
    this.selectedDietPlanName,
  });

  SupplementCreationState copyWith({
    List<LLMChatMessage>? messages,
    bool? isAIResponding,
    SupplementDay? pendingSuggestion,
    String? errorMessage,
    bool? canSendMessage,
    SelectionStep? currentSelectionStep,
    String? selectedTrainingPlanId,
    String? selectedDietPlanId,
    String? selectedTrainingPlanName,
    String? selectedDietPlanName,
  }) {
    return SupplementCreationState(
      messages: messages ?? this.messages,
      isAIResponding: isAIResponding ?? this.isAIResponding,
      pendingSuggestion: pendingSuggestion ?? this.pendingSuggestion,
      errorMessage: errorMessage ?? this.errorMessage,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      currentSelectionStep: currentSelectionStep ?? this.currentSelectionStep,
      selectedTrainingPlanId: selectedTrainingPlanId ?? this.selectedTrainingPlanId,
      selectedDietPlanId: selectedDietPlanId ?? this.selectedDietPlanId,
      selectedTrainingPlanName: selectedTrainingPlanName ?? this.selectedTrainingPlanName,
      selectedDietPlanName: selectedDietPlanName ?? this.selectedDietPlanName,
    );
  }
}

/// 选择步骤枚举
enum SelectionStep {
  training,  // 正在选择训练计划
  diet,      // 正在选择饮食计划
}
```

---

## 📊 实施检查清单

### 阶段1：后端基础设施 ✅ 5/5 - 已完成

- [x] 1. 在`functions/ai/tools.py`中添加`get_supplement_day_tool()`
- [x] 2. 创建`functions/ai/supplement_plan/prompts.py`
- [x] 3. 在`functions/ai/streaming.py`中添加`stream_generate_supplement_plan_conversation()`
- [x] 4. 在`functions/ai/handlers.py`中添加`generate_supplement_plan_conversation`
- [x] 5. 在`functions/main.py`中导出新函数

### 阶段2：前端数据层 ✅ 5/5 - 已完成

- [x] 6. 扩展`lib/features/coach/plans/data/models/llm_chat_message.dart`
- [x] 7. 创建`lib/features/coach/plans/data/models/supplement_stream_event.dart`
- [x] 8. 创建`lib/features/coach/plans/data/models/supplement_creation_state.dart`
- [x] 9. 在`lib/core/services/ai_service.dart`中添加`generateSupplementPlanConversation()`
- [x] 10. 在`create_supplement_plan_notifier.dart`中添加`applyAIGeneratedDay()`

### 阶段3：前端状态管理 ✅ 2/2 - 已完成

- [x] 11. 创建`supplement_conversation_notifier.dart`
- [x] 12. 创建`supplement_conversation_providers.dart`

### 阶段4：前端UI组件 ⏳ 0/4 - 待完成

- [ ] 13. 修改`chat_message_bubble.dart`（添加交互式选项支持）
- [ ] 14. 创建`ai_supplement_creation_panel.dart`
- [ ] 15. 创建`supplement_suggestion_card.dart`
- [ ] 16. 修改`create_supplement_plan_page.dart`（添加Sparkle按钮）

### 阶段5：集成测试 ⏳ 0/2 - 待完成

- [ ] 17. 本地测试：Firebase emulator
- [ ] 18. 端到端测试：完整流程

---

**当前进度**: 17/21 任务完成 (81%)

---

## 🎯 下一步

### 剩余任务（在新conversation完成）

**阶段4：前端UI组件** (预计2-3小时)
1. 修改 `chat_message_bubble.dart` - 添加InteractiveOption渲染逻辑
2. 创建 `ai_supplement_creation_panel.dart` - 实现70% modal sheet
3. 创建 `supplement_suggestion_card.dart` - 实现补剂建议卡片
4. 修改 `create_supplement_plan_page.dart` - 添加Sparkle按钮

**阶段5：集成测试** (预计1-2小时)
1. 启动 Firebase Emulator 进行本地测试
2. 完整流程端到端测试
3. Bug修复和优化

### 部署清单

```bash
# 1. 部署后端
cd functions
firebase deploy --only functions

# 2. Flutter代码生成（如需要）
flutter pub run build_runner build --delete-conflicting-outputs

# 3. 运行应用测试
flutter run

# 4. 代码分析
flutter analyze
```

---

**最后更新**: 2025-01-02
**文档版本**: 1.1
**执行进度**: 81% (17/21任务)
