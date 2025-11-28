"""
AI 流式生成模块

实现训练计划的渐进式流式生成
每次生成一天，通过 Tool Use 保证数据格式
"""

from typing import Dict, Any, Generator, Optional, List
import json

from .claude_client import get_claude_client
from .tools import get_single_day_tool, get_plan_edit_tool, get_diet_plan_edit_tool
from .training_plan.prompts import build_single_day_prompt, get_system_prompt, build_edit_conversation_prompt
from .diet_plan.prompts import build_edit_diet_plan_prompt
from .memory_manager import MemoryManager
from utils.logger import logger



def stream_generate_training_plan(params: Dict[str, Any]) -> Generator[Dict[str, Any], None, None]:
    """
    流式生成训练计划

    逐天生成训练计划，每生成一天就立即 yield 返回

    Args:
        params: 训练计划参数，包含:
            - goal: 训练目标
            - level: 训练水平
            - muscle_groups: 目标肌群列表
            - days_per_week: 每周训练天数
            - duration_minutes: 每次训练时长
            - workload: 训练量
            - exercises_per_day_min: 每天最少动作数
            - exercises_per_day_max: 每天最多动作数
            - sets_per_exercise_min: 每个动作最少组数
            - sets_per_exercise_max: 每个动作最多组数
            - training_styles: 训练风格列表
            - equipment: 可用设备列表
            - notes: 补充说明（可选）
            - exercise_templates: 动作库模板列表（可选）
    
    Yields:
        dict: 流式事件
            - type: 'thinking' | 'day_start' | 'day_complete' | 'complete' | 'error'
            - day: 当前天数
            - content: 思考内容
            - data: 训练日数据（day_complete 时）
            - message: 完成消息（complete 时）
            - error: 错误信息（error 时）
    """
    try:
        days_count = params.get('days_per_week', 3)
        language = params.get('language', '中文')
        logger.info(f'🔄 [Stream] 开始流式生成 {days_count} 天训练计划')
        logger.info(f'🌐 [Stream] 语言设置: {language}')
        logger.info(f'📋 [Stream] 参数详情: {json.dumps(params, ensure_ascii=False, indent=2)}')
        
        # 获取 Claude 客户端
        claude_client = get_claude_client()
        logger.info('✅ [Stream] Claude 客户端初始化成功')
        
        # 获取单天工具定义
        tool = get_single_day_tool()
        logger.info(f'✅ [Stream] Tool 定义获取成功: {tool.get("function", {}).get("name")}')
        
        # 用于存储已生成的训练日（供后续天数参考）
        previous_days = []
        
        # 逐天生成
        for day_num in range(1, days_count + 1):
            try:
                logger.info(f'📝 [Stream Day {day_num}] ===== 开始生成第 {day_num}/{days_count} 天 =====')
                
                # 发送思考事件
                yield {
                    'type': 'thinking',
                    'day': day_num,
                    'content': f'正在规划第 {day_num} 天训练...'
                }
                
                # 构建当天的 Prompt
                system_prompt = get_system_prompt(language)
                user_prompt = build_single_day_prompt(
                    day=day_num,
                    params=params,
                    previous_days=previous_days,
                    exercise_templates=params.get('exercise_templates')
                )
                
                logger.info(f'📝 [Stream Day {day_num}] System Prompt 长度: {len(system_prompt)} 字符')
                logger.info(f'📝 [Stream Day {day_num}] User Prompt 长度: {len(user_prompt)} 字符')
                logger.debug(f'📝 [Stream Day {day_num}] User Prompt 前200字符: {user_prompt[:200]}...')
                
                # 发送开始事件
                yield {
                    'type': 'day_start',
                    'day': day_num
                }
                
                # 调用流式 API
                logger.info(f'🔄 [Stream Day {day_num}] 开始调用 Claude Streaming API')
                tool_input = None
                event_count = 0
                
                for event in claude_client.call_claude_streaming(
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    tools=[tool]
                ):
                    event_count += 1
                    event_type = event.get('type')
                    logger.debug(f'📨 [Stream Day {day_num}] Event #{event_count}: type={event_type}')
                    
                    if event_type == 'tool_start':
                        tool_name = event.get('tool_name', 'unknown')
                        logger.info(f'🔧 [Stream Day {day_num}] Tool 调用开始: {tool_name}')
                    
                    elif event_type == 'tool_delta':
                        # 可选：传递部分 JSON（目前不需要）
                        logger.debug(f'📨 [Stream Day {day_num}] Tool delta 事件')
                        pass
                    
                    elif event_type == 'tool_complete':
                        tool_input = event.get('tool_input')
                        logger.info(f'✅ [Stream Day {day_num}] Tool 调用完成')
                        logger.info(f'📦 [Stream Day {day_num}] Tool Input 类型: {type(tool_input)}')
                        
                        # 详细记录 tool_input 的内容
                        if isinstance(tool_input, dict):
                            logger.info(f'📦 [Stream Day {day_num}] Tool Input Keys: {list(tool_input.keys())}')
                            logger.debug(f'📦 [Stream Day {day_num}] Tool Input 完整内容: {json.dumps(tool_input, ensure_ascii=False, indent=2)}')
                        else:
                            logger.error(f'❌ [Stream Day {day_num}] Tool Input 不是字典类型！实际类型: {type(tool_input)}, 值: {tool_input}')
                            raise TypeError(f'Tool Input 应该是字典类型，但得到了 {type(tool_input)}')
                        
                        break
                    
                    elif event_type == 'error':
                        error_msg = event.get('error', '未知错误')
                        logger.error(f'❌ [Stream Day {day_num}] Claude API 返回错误: {error_msg}')
                        raise Exception(error_msg)
                
                logger.info(f'📊 [Stream Day {day_num}] 共收到 {event_count} 个事件')
                
                # 验证 tool_input
                if not tool_input:
                    logger.error(f'❌ [Stream Day {day_num}] 未获取到 tool_input')
                    yield {
                        'type': 'error',
                        'day': day_num,
                        'error': f'第 {day_num} 天生成失败: 未获取到数据'
                    }
                    return
                
                # 验证必要字段
                day_name = tool_input.get('name')  # Tool 返回的是 'name' 不是 'day_name'
                exercises = tool_input.get('exercises')
                
                logger.info(f'🔍 [Stream Day {day_num}] name: {day_name}')
                logger.info(f'🔍 [Stream Day {day_num}] exercises 数量: {len(exercises) if exercises else 0}')
                
                if not day_name:
                    logger.error(f'❌ [Stream Day {day_num}] 缺少 name 字段')
                    yield {
                        'type': 'error',
                        'day': day_num,
                        'error': f'第 {day_num} 天数据不完整: 缺少训练名称'
                    }
                    return
                
                if not exercises or not isinstance(exercises, list):
                    logger.error(f'❌ [Stream Day {day_num}] exercises 字段无效: {type(exercises)}')
                    yield {
                        'type': 'error',
                        'day': day_num,
                        'error': f'第 {day_num} 天数据不完整: 动作列表无效'
                    }
                    return
                
                # 逐个 yield 动作事件（动作级别流式生成）
                logger.info(f'📝 [Stream Day {day_num}] 开始逐个发送 {len(exercises)} 个动作')
                
                for idx, exercise in enumerate(exercises):
                    exercise_name = exercise.get('name', '未知动作')
                    
                    # 发送动作开始事件
                    yield {
                        'type': 'exercise_start',
                        'day': day_num,
                        'exercise_index': idx + 1,
                        'exercise_name': exercise_name,
                        'total_exercises': len(exercises)
                    }
                    logger.debug(f'🏋️ [Stream Day {day_num}] 动作 {idx + 1}/{len(exercises)}: {exercise_name}')
                    
                    # 发送动作完成事件
                    yield {
                        'type': 'exercise_complete',
                        'day': day_num,
                        'exercise_index': idx + 1,
                        'data': exercise  # 单个动作数据
                    }
                    logger.debug(f'✅ [Stream Day {day_num}] 动作 {idx + 1} 完成: {exercise_name}')
                
                logger.info(f'✅ [Stream Day {day_num}] 所有 {len(exercises)} 个动作已发送')
                
                # 构建训练日数据
                day_data = {
                    'day': day_num,
                    'name': day_name,  # 使用 Tool 返回的 name
                    'duration': tool_input.get('duration_minutes', params.get('duration_minutes', 60)),
                    'exercises': exercises,
                    'notes': [tool_input.get('note', '')] if tool_input.get('note') else []  # note 转为 notes 数组
                }
                
                logger.info(f'✅ [Stream Day {day_num}] 训练日数据构建完成: {day_name}, {len(exercises)} 个动作')
                
                # 保存到已完成列表
                previous_days.append(day_data)
                
                # 发送训练日完成事件
                yield {
                    'type': 'day_complete',
                    'day': day_num,
                    'data': day_data
                }
                
                logger.info(f'🎉 [Stream Day {day_num}] ===== 第 {day_num} 天生成完成 =====')
            
            except Exception as e:
                logger.error(f'❌ [Stream Day {day_num}] 生成异常', exc_info=True)
                yield {
                    'type': 'error',
                    'day': day_num,
                    'error': f'第 {day_num} 天生成失败: {str(e)}'
                }
                return
        
        # 全部完成
        logger.info(f'🎉 [Stream] 训练计划生成完成，共 {len(previous_days)} 天')
        yield {
            'type': 'complete',
            'message': f'训练计划生成完成，共 {len(previous_days)} 天'
        }
    
    except Exception as e:
        logger.error('❌ [Stream] 流式生成异常', exc_info=True)
        yield {
            'type': 'error',
            'error': f'生成失败: {str(e)}'
        }


def stream_edit_plan_conversation(
    user_id: str,
    user_message: str,
    current_plan: Dict[str, Any],
    plan_id: str
) -> Generator[Dict[str, Any], None, None]:
    """
    流式处理编辑对话
    
    Args:
        user_id: 用户ID
        user_message: 用户的修改请求
        current_plan: 当前完整计划数据
        plan_id: 计划ID
    
    Yields:
        dict: 流式事件
            - type: 'thinking' | 'analysis' | 'suggestion' | 'complete' | 'error'
            - content: 内容（thinking 和 analysis 时）
            - data: 数据（suggestion ）
            - error: 错误信息（error 时）
    """
    try:
        logger.info(f'🔄 [Edit] 开始处理编辑对话 - User: {user_id}, Plan: {plan_id}')
        logger.info(f'用户请求: {user_message[:100]}...')


        # 1. 获取用户 memory
        logger.info('📖 加载用户 Memory')
        user_memory_context = MemoryManager.build_memory_context(user_id)

        # 2. 加载教练的动作库
        try:
            coach_id = _get_coach_id_from_plan(plan_id)
            exercise_templates = _fetch_coach_exercise_templates(coach_id)
            logger.info(f'📚 加载动作库: {len(exercise_templates)} 个模板')
        except Exception as e:
            logger.warning(f'⚠️ 加载动作库失败: {e}')
            exercise_templates = []
            coach_id = None
        profile = MemoryManager.get_user_memory(user_id)
        conversation_history = profile.get_recent_conversations(limit=3)
        language = profile.language_preference
        
        logger.info(f'🌐 语言设置: {language}')
        logger.info(f'💭 对话历史: {len(conversation_history)} 条')
        
        # 发送思考事件
        yield {
            'type': 'thinking',
            'content': '正在分析您的修改请求...'
        }
        
        # 2. 构建 Prompt
        logger.info('📝 构建编辑对话 Prompt')
        system_prompt, user_prompt = build_edit_conversation_prompt(
            user_message=user_message,
            current_plan=current_plan,
            user_memory=user_memory_context,
            conversation_history=conversation_history,
            exercise_templates=exercise_templates,
            language=language
        )
        
        logger.info(f'System Prompt 长度: {len(system_prompt)} 字符')
        logger.info(f'User Prompt 长度: {len(user_prompt)} 字符')
        
        # 3. 调用 Claude Streaming API
        logger.info('🔄 开始调用 Claude Streaming API')
        claude_client = get_claude_client()

        # 始终提供edit_plan工具，让Claude根据用户意图自主决定是否使用
        tool = get_plan_edit_tool()
        tools = [tool]
        logger.info('🔧 提供edit_plan工具，由Claude智能判断是否使用')

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
            logger.debug(f'📨 [Edit Event #{event_count}] type={event_type}')

            # 文本内容（思考过程）
            if event_type == 'text_delta':
                text_delta = event.get('text', '')
                text_content += text_delta
                logger.debug(f'📝 [Edit] text_delta长度: {len(text_delta)}, 累积长度: {len(text_content)}')

                # 流式发送思考内容
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
                    'content': '正在生成修改建议...'
                }
            
            # Tool 增量数据（部分 JSON）
            elif event_type == 'tool_delta':
                # 我们不逐字符发送，等待完整 JSON
                pass
            
            # 文本内容完成（备份机制）
            elif event_type == 'text_complete':
                complete_text = event.get('text', '')
                logger.info(f'📝 [Edit] text_complete - 长度: {len(complete_text)}')
                # 如果text_content为空（没有收到delta），使用完整文本
                if not text_content and complete_text:
                    text_content = complete_text
                    logger.info('📝 使用 text_complete 作为备份')

            # Tool 调用完成
            elif event_type == 'tool_complete':
                tool_input = event.get('tool_input', {})
                logger.info('✅ Tool 调用完成')
                logger.debug(f'Tool 输出: {json.dumps(tool_input, ensure_ascii=False, indent=2)[:500]}...')

                # 提取修改建议
                analysis = tool_input.get('analysis', '')
                changes = tool_input.get('changes', [])

                # 诊断日志
                logger.info(f'📊 Tool 输出字段检查:')
                logger.info(f'  - analysis: {"✅" if analysis else "❌"} ({len(analysis)} 字符)')
                logger.info(f'  - changes: {"✅" if changes else "❌"} ({len(changes)} 项)')

                # 详细记录每个 change
                if changes:
                    logger.info(f'\n📋 详细 Changes 列表 ({len(changes)} 项):')
                    logger.info('=' * 80)
                    for idx, change in enumerate(changes, 1):
                        logger.info(f'\n🔸 Change #{idx}:')
                        logger.info(f'  ├─ Type: {change.get("type", "未指定")}')
                        logger.info(f'  ├─ Target: {change.get("target", "未指定")}')
                        logger.info(f'  ├─ Description: {change.get("description", "未指定")}')
                        logger.info(f'  ├─ Reason: {change.get("reason", "未指定")}')
                        logger.info(f'  ├─ Before: {change.get("before", "未指定")}')
                        logger.info(f'  ├─ After: {change.get("after", "未指定")}')
                        logger.info(f'  ├─ Day Index: {change.get("day_index", "未指定")}')
                        logger.info(f'  ├─ Exercise Index: {change.get("exercise_index", "未提供")}')
                        logger.info(f'  └─ Set Index: {change.get("set_index", "未提供")}')
                    logger.info('=' * 80)

                    # 统计分析
                    change_types = {}
                    for change in changes:
                        change_type = change.get('type', 'unknown')
                        change_types[change_type] = change_types.get(change_type, 0) + 1

                    logger.info(f'\n📊 Changes 类型统计:')
                    for change_type, count in change_types.items():
                        logger.info(f'  - {change_type}: {count} 项')
                else:
                    logger.warning('⚠️ Changes 数组为空！AI 未提供任何修改建议')

                # 发送分析结果
                yield {
                    'type': 'analysis',
                    'content': analysis
                }

                # 为每个 change 添加唯一 ID 并验证必需字段
                changes_with_id = []
                validation_errors = []

                for idx, change in enumerate(changes):
                    change_with_id = change.copy()

                    # 确保有 id 字段
                    if 'id' not in change_with_id:
                        change_with_id['id'] = f'change_{idx}'

                    # 验证必需字段
                    required_fields = ['type', 'description', 'reason', 'day_index']
                    missing_fields = [field for field in required_fields if field not in change_with_id]

                    if missing_fields:
                        error_msg = f'⚠️ Change #{idx} 缺少必需字段: {", ".join(missing_fields)}'
                        logger.warning(error_msg)
                        validation_errors.append(error_msg)

                    # 确保 day_index 存在（兼容旧版本）
                    if 'day_index' not in change_with_id and 'dayIndex' not in change_with_id:
                        logger.warning(f'⚠️ Change #{idx} 缺少 day_index，设置为 0')
                        change_with_id['day_index'] = 0

                    # 验证 after 字段（关键字段）
                    if 'after' not in change_with_id or not change_with_id['after']:
                        logger.warning(f'⚠️ Change #{idx} 缺少 after 字段，前端可能无法应用此修改')
                        validation_errors.append(f'Change #{idx} 缺少 after 字段')

                    # 注入 exerciseTemplateId（如果是add_exercise或modify_exercise类型）
                    if coach_id and exercise_templates:
                        change_type = change_with_id.get('type', '')

                        if change_type in ['add_exercise', 'modify_exercise']:
                            exercise_name = _extract_exercise_name_from_change(change_with_id)

                            if exercise_name:
                                try:
                                    template_id = _match_or_create_template(
                                        coach_id,
                                        exercise_name,
                                        exercise_templates
                                    )
                                    _inject_exercise_template_id(change_with_id, template_id)

                                    logger.info(f'✅ 注入模板ID: {exercise_name} -> {template_id}')
                                except Exception as e:
                                    logger.error(f'❌ 注入模板ID失败: {exercise_name}', exc_info=True)

                    changes_with_id.append(change_with_id)

                # 汇总验证结果
                if validation_errors:
                    logger.warning(f'⚠️ 发现 {len(validation_errors)} 个验证错误:')
                    for error in validation_errors:
                        logger.warning(f'  - {error}')
                else:
                    logger.info('✅ 所有 changes 验证通过')

                # 发送修改建议
                yield {
                    'type': 'suggestion',
                    'data': {
                        'changes': changes_with_id,
                    }
                }


        # 检查是否为纯文本响应（没有tool调用）
        logger.info(f'🔍 检查纯文本响应 - tool_input: {tool_input is not None}, text_content长度: {len(text_content)}')
        if not tool_input and text_content:
            logger.info('📝 检测到纯文本响应（总结模式）')
            # 发送纯文本分析结果
            yield {
                'type': 'analysis',
                'content': text_content
            }
        elif not tool_input:
            logger.warning('⚠️ 无tool_input但text_content为空')

        # 4. 保存对话历史
        logger.info('💾 保存对话历史到 Memory')
        ai_response_summary = tool_input.get('summary', '') if tool_input else text_content[:200]
        MemoryManager.update_conversation_history(
            user_id=user_id,
            user_message=user_message,
            ai_response=ai_response_summary,
            context={'plan_id': plan_id, 'type': 'edit'}
        )
        
        # 5. 完成
        logger.info('🎉 [Edit] 编辑对话处理完成')
        yield {
            'type': 'complete',
            'message': '修改建议已生成'
        }

    except Exception as e:
        logger.error(f'❌ [Edit] 编辑对话处理失败: {str(e)}', exc_info=True)
        yield {
            'type': 'error',
            'error': f'处理失败: {str(e)}'
        }


def stream_edit_diet_plan_conversation(
    user_id: str,
    user_message: str,
    current_plan: Dict[str, Any],
    plan_id: str
) -> Generator[Dict[str, Any], None, None]:
    """
    流式处理饮食计划编辑对话

    Args:
        user_id: 用户ID
        user_message: 用户的修改请求
        current_plan: 当前完整计划数据
        plan_id: 计划ID

    Yields:
        dict: 流式事件
            - type: 'thinking' | 'analysis' | 'suggestion' | 'complete' | 'error'
            - content: 内容（thinking 和 analysis 时）
            - data: 数据（suggestion 时）
            - error: 错误信息（error 时）
    """
    try:
        logger.info(f'🔄 [Edit Diet] 开始处理饮食计划编辑对话 - User: {user_id}, Plan: {plan_id}')
        logger.info(f'用户请求: {user_message[:100]}...')

        # 1. 获取用户 memory
        logger.info('📖 加载用户 Memory')
        user_memory_context = MemoryManager.build_memory_context(user_id)
        profile = MemoryManager.get_user_memory(user_id)
        conversation_history = profile.get_recent_conversations(limit=3)
        language = profile.language_preference

        logger.info(f'🌐 语言设置: {language}')
        logger.info(f'💭 对话历史: {len(conversation_history)} 条')

        # 发送思考事件
        yield {
            'type': 'thinking',
            'content': '正在分析您的修改请求...'
        }

        # 2. 构建 Prompt
        logger.info('📝 构建编辑对话 Prompt')
        system_prompt, user_prompt = build_edit_diet_plan_prompt(
            user_message=user_message,
            current_plan=current_plan,
            user_memory=user_memory_context,
            conversation_history=conversation_history,
            language=language
        )

        logger.info(f'System Prompt 长度: {len(system_prompt)} 字符')
        logger.info(f'User Prompt 长度: {len(user_prompt)} 字符')

        # 3. 调用 Claude Streaming API
        logger.info('🔄 开始调用 Claude Streaming API')
        claude_client = get_claude_client()
        tool = get_diet_plan_edit_tool()
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
            logger.debug(f'📨 [Edit Diet Event #{event_count}] type={event_type}')

            # 文本内容（思考过程）
            if event_type == 'text_delta':
                text_delta = event.get('text', '')
                text_content += text_delta
                logger.debug(f'📝 [Edit Diet] text_delta长度: {len(text_delta)}, 累积长度: {len(text_content)}')

                if text_delta:
                    yield {
                        'type': 'thinking',
                        'content': text_delta
                    }

            # Tool 调用开始
            elif event_type == 'tool_start':
                tool_name = event.get('tool_name')
                logger.info(f'🔧 [Edit Diet] Tool 调用开始: {tool_name}')

                yield {
                    'type': 'analysis',
                    'content': '正在生成修改建议...'
                }

            # Tool 增量数据（部分 JSON）
            elif event_type == 'tool_delta':
                # 我们不逐字符发送，等待完整 JSON
                pass

            # 文本内容完成（备份机制）
            elif event_type == 'text_complete':
                complete_text = event.get('text', '')
                logger.info(f'📝 [Edit Diet] text_complete - 长度: {len(complete_text)}')
                # 如果text_content为空（没有收到delta），使用完整文本
                if not text_content and complete_text:
                    text_content = complete_text
                    logger.info('📝 使用 text_complete 作为备份')

            # Tool 调用完成
            elif event_type == 'tool_complete':
                tool_input = event.get('tool_input', {})
                logger.info(f'✅ [Edit Diet] Tool 调用完成')
                logger.debug(f'Tool 输出: {json.dumps(tool_input, ensure_ascii=False, indent=2)[:500]}...')

                # 提取修改建议
                analysis = tool_input.get('analysis', '')
                changes = tool_input.get('changes', [])
                summary = tool_input.get('summary', '')

                # 诊断日志
                logger.info(f'📊 Tool 输出字段检查:')
                logger.info(f'  - analysis: {"✅" if analysis else "❌"} ({len(analysis)} 字符)')
                logger.info(f'  - changes: {"✅" if changes else "❌"} ({len(changes)} 项)')

                # 详细记录每个 change
                if changes:
                    logger.info(f'\n📋 详细 Changes 列表 ({len(changes)} 项):')
                    logger.info('=' * 80)
                    for idx, change in enumerate(changes, 1):
                        logger.info(f'\n🔸 Change #{idx}:')
                        logger.info(f'  ├─ Type: {change.get("type", "未指定")}')
                        logger.info(f'  ├─ Target: {change.get("target", "未指定")}')
                        logger.info(f'  ├─ Description: {change.get("description", "未指定")}')
                        logger.info(f'  ├─ Reason: {change.get("reason", "未指定")}')
                        logger.info(f'  ├─ Before: {change.get("before", "未指定")}')
                        logger.info(f'  ├─ After: {change.get("after", "未指定")}')
                        logger.info(f'  ├─ Day Index: {change.get("day_index", "未指定")}')
                        logger.info(f'  ├─ Meal Index: {change.get("meal_index", "未提供")}')
                        logger.info(f'  └─ Food Item Index: {change.get("food_item_index", "未提供")}')
                    logger.info('=' * 80)

                    # 统计分析
                    change_types = {}
                    for change in changes:
                        change_type = change.get('type', 'unknown')
                        change_types[change_type] = change_types.get(change_type, 0) + 1

                    logger.info(f'\n📊 Changes 类型统计:')
                    for change_type, count in change_types.items():
                        logger.info(f'  - {change_type}: {count} 项')
                else:
                    logger.warning('⚠️ Changes 数组为空！AI 未提供任何修改建议')

                # 发送分析结果
                yield {
                    'type': 'analysis',
                    'content': analysis
                }

                # 为每个 change 添加唯一 ID 并验证必需字段
                changes_with_id = []
                validation_errors = []

                for idx, change in enumerate(changes):
                    change_with_id = change.copy()

                    # 确保有 id 字段
                    if 'id' not in change_with_id:
                        change_with_id['id'] = f'change_{idx}'

                    # 验证必需字段
                    required_fields = ['type', 'target', 'description', 'reason', 'day_index', 'id']
                    missing_fields = [field for field in required_fields if field not in change_with_id]

                    if missing_fields:
                        error_msg = f'⚠️ Change #{idx} 缺少必需字段: {", ".join(missing_fields)}'
                        logger.warning(error_msg)
                        validation_errors.append(error_msg)

                    # 确保 day_index 存在（兼容旧版本）
                    if 'day_index' not in change_with_id and 'dayIndex' not in change_with_id:
                        logger.warning(f'⚠️ Change #{idx} 缺少 day_index，设置为 0')
                        change_with_id['day_index'] = 0

                    # 验证 after 字段（关键字段）
                    if 'after' not in change_with_id or not change_with_id['after']:
                        logger.warning(f'⚠️ Change #{idx} 缺少 after 字段，前端可能无法应用此修改')
                        validation_errors.append(f'Change #{idx} 缺少 after 字段')

                    changes_with_id.append(change_with_id)

                # 汇总验证结果
                if validation_errors:
                    logger.warning(f'⚠️ 发现 {len(validation_errors)} 个验证错误:')
                    for error in validation_errors:
                        logger.warning(f'  - {error}')
                else:
                    logger.info('✅ 所有 changes 验证通过')

                # 发送修改建议
                yield {
                    'type': 'suggestion',
                    'data': {
                        'analysis': analysis,
                        'changes': changes_with_id,
                        'summary': summary,
                    }
                }

            elif event_type == 'error':
                error_msg = event.get('error', '未知错误')
                logger.error(f'❌ [Edit Diet] Claude API 返回错误: {error_msg}')
                raise Exception(error_msg)

        # 事件循环结束，记录总数
        logger.info(f'📊 [Edit Diet] 共收到 {event_count} 个事件')

        # 检查是否为纯文本响应（没有tool调用）
        logger.info(f'🔍 检查纯文本响应 - tool_input: {tool_input is not None}, text_content长度: {len(text_content)}')
        if not tool_input and text_content:
            logger.info('📝 检测到纯文本响应（总结模式）')
            # 发送纯文本分析结果
            yield {
                'type': 'analysis',
                'content': text_content
            }
        elif not tool_input:
            logger.warning('⚠️ 无tool_input但text_content为空')

        # 保存对话历史到 Memory
        logger.info('💾 保存对话历史到 Memory')
        ai_response_summary = tool_input.get('summary', '') if tool_input else text_content[:200]
        MemoryManager.update_conversation_history(
            user_id=user_id,
            user_message=user_message,
            ai_response=ai_response_summary,
            context={'plan_id': plan_id, 'type': 'edit_diet'}
        )

        # 完成
        logger.info('🎉 [Edit Diet] 编辑对话处理完成')
        yield {
            'type': 'complete',
            'message': '修改建议已生成'
        }

    except Exception as e:
        logger.error(f'❌ [Edit Diet] 编辑对话异常', exc_info=True)
        yield {
            'type': 'error',
            'error': f'编辑失败: {str(e)}'
        }


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


# ==================== ExerciseTemplate 集成辅助函数 ====================

def _get_coach_id_from_plan(plan_id: str) -> str:
    """从plan_id获取教练ID"""
    from firebase_admin import firestore
    db = firestore.client()

    # 查询 exercisePlans 集合
    plan_ref = db.collection('exercisePlans').document(plan_id)
    plan_doc = plan_ref.get()

    if not plan_doc.exists:
        raise ValueError(f'Plan not found: {plan_id}')

    coach_id = plan_doc.to_dict().get('ownerId')
    if not coach_id:
        raise ValueError(f'Plan {plan_id} missing ownerId')

    return coach_id


def _fetch_coach_exercise_templates(coach_id: str) -> list:
    """获取教练的动作库"""
    from firebase_admin import firestore
    db = firestore.client()

    templates_ref = db.collection('exerciseTemplates').where('ownerId', '==', coach_id)
    templates_docs = templates_ref.stream()

    templates = []
    for doc in templates_docs:
        data = doc.to_dict()
        templates.append({
            'id': doc.id,
            'name': data.get('name', ''),
            'tags': data.get('tags', [])
        })

    return templates


def _match_or_create_template(coach_id: str, exercise_name: str, existing_templates: list) -> str:
    """匹配动作库或快捷创建新模板"""
    from firebase_admin import firestore

    # 1. 精确匹配
    for template in existing_templates:
        if template['name'] == exercise_name:
            logger.info(f'✅ 匹配到动作模板: {exercise_name} -> {template["id"]}')
            return template['id']

    # 2. 模糊匹配（忽略大小写、前后空格）
    normalized_name = exercise_name.strip().lower()
    for template in existing_templates:
        if template['name'].strip().lower() == normalized_name:
            logger.info(f'✅ 模糊匹配到动作模板: {exercise_name} -> {template["id"]}')
            return template['id']

    # 3. 快捷创建新模板
    logger.info(f'⚠️ 动作「{exercise_name}」不在库中，创建新模板')

    db = firestore.client()
    new_template_ref = db.collection('exerciseTemplates').document()

    new_template_ref.set({
        'name': exercise_name,
        'tags': [],  # 默认空标签
        'ownerId': coach_id,
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })

    logger.info(f'✅ 创建新模板: {exercise_name} -> {new_template_ref.id}')
    return new_template_ref.id


def _extract_exercise_name_from_change(change: dict) -> str:
    """从change对象提取动作名称"""
    after = change.get('after')

    # 如果after是对象
    if isinstance(after, dict):
        return after.get('name', '')

    # 如果after是字符串（不应该，但防御性处理）
    if isinstance(after, str):
        return after

    return ''


def _inject_exercise_template_id(change: dict, template_id: str):
    """注入exerciseTemplateId到change的after字段"""
    after = change.get('after')

    if isinstance(after, dict):
        after['exerciseTemplateId'] = template_id
    else:
        # 如果after不是dict，包装成dict
        change['after'] = {
            'name': str(after),
            'exerciseTemplateId': template_id
        }

