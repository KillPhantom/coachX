"""
Claude API 客户端

封装对 Anthropic Claude API 的调用

## 🔐 API Key 管理

本模块使用 **Firebase Functions Secrets** 管理 Anthropic API Key：

- **生产环境**: Secret 通过 `@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])` 
  自动注入为环境变量
- **本地开发**: 使用 `.env` 文件或直接导出环境变量

详细配置说明请参考: `functions/SECRETS_SETUP.md`

## 📚 相关文档

- SECRETS_SETUP.md: Firebase Secrets 完整配置指南
- handlers.py: 使用示例（在装饰器中声明 secrets）
"""

import os
import json
from typing import Optional, Dict, Any
import httpx
from anthropic import Anthropic, APIError
from utils.logger import logger

SAVE_DEBUG_RESPONSE = False

class ClaudeClient:
    """Claude API 客户端"""
    
    def __init__(self):
        """
        初始化客户端
        
        API Key 获取方式：
        - 生产环境：从 Firebase Secrets 自动注入的环境变量获取
        - 本地开发：从 .env 文件或手动导出的环境变量获取
        """
        # 获取 API Key（生产环境由 Firebase Secrets 注入）
        api_key = os.environ.get('ANTHROPIC_API_KEY')
        if not api_key:
            raise ValueError(
                '未配置 ANTHROPIC_API_KEY。\n'
                '\n'
                '生产环境设置方法：\n'
                '  firebase functions:secrets:set ANTHROPIC_API_KEY\n'
                '\n'
                '本地开发设置方法：\n'
                '  1. 创建 functions/.env 文件\n'
                '  2. 添加: ANTHROPIC_API_KEY=your-api-key-here\n'
                '  3. 启动: export $(cat .env | xargs) && firebase emulators:start\n'
                '\n'
                '详细配置指南请参考: functions/SECRETS_SETUP.md'
            )

        # 配置超时（流式响应需要较长的读取超时）
        # connect: 连接超时 30 秒
        # read: 读取超时 10 分钟（匹配 Cloud Function timeout_sec=540）
        # write: 写入超时 30 秒
        # pool: 连接池超时 30 秒
        timeout = httpx.Timeout(
            connect=30.0,
            read=600.0,
            write=30.0,
            pool=30.0
        )

        self.client = Anthropic(
            api_key=api_key,
            timeout=timeout,
            max_retries=3,  # 自动重试 3 次（默认 2 次）
        )
        
        # 其他配置参数（可通过环境变量覆盖默认值）
        self.model = os.environ.get('ANTHROPIC_MODEL', 'claude-sonnet-4-20250514')
        self.max_tokens = int(os.environ.get('ANTHROPIC_MAX_TOKENS', '16384'))
        self.temperature = float(os.environ.get('ANTHROPIC_TEMPERATURE', '0.7'))
    
    def call_claude(
        self,
        system_prompt: str,
        user_prompt: str,
        response_format: str = 'json'
    ) -> Dict[str, Any]:
        """
        调用 Claude API
        
        Args:
            system_prompt: 系统提示词
            user_prompt: 用户提示词
            response_format: 响应格式 ('json' 或 'text')
        
        Returns:
            Dict containing the response
        
        Raises:
            Exception: API 调用失败
        """
        try:
            logger.info(f'🤖 调用 Claude API - Model: {self.model}')
            logger.debug(f'User Prompt (前100字): {user_prompt[:100]}...')
            
            # 构建消息
            messages = [
                {
                    'role': 'user',
                    'content': user_prompt
                }
            ]
            
            # 调用 API
            response = self.client.messages.create(
                model=self.model,
                max_tokens=self.max_tokens,
                temperature=self.temperature,
                system=system_prompt,
                messages=messages
            )
            
            # 提取响应文本
            if response.content and len(response.content) > 0:
                content = response.content[0].text
                logger.info(f'✅ Claude API 调用成功')
                logger.debug(f'Response (前200字): {content[:200]}...')
                
                # 如果需要JSON格式，尝试解析
                if response_format == 'json':
                    try:
                        # 清理可能的 markdown 代码块标记
                        content = content.strip()
                        if content.startswith('```json'):
                            content = content[7:]
                        if content.startswith('```'):
                            content = content[3:]
                        if content.endswith('```'):
                            content = content[:-3]
                        content = content.strip()
                        
                        parsed_json = json.loads(content)
                        return {
                            'success': True,
                            'data': parsed_json,
                            'raw_text': content
                        }
                    except json.JSONDecodeError as e:
                        logger.warning(f'⚠️ JSON 解析失败: {e}')
                        return {
                            'success': False,
                            'error': f'JSON 解析失败: {str(e)}',
                            'raw_text': content
                        }
                else:
                    return {
                        'success': True,
                        'data': content
                    }
            else:
                logger.error('❌ Claude 响应为空')
                return {
                    'success': False,
                    'error': 'Claude 响应为空'
                }
        
        except APIError as e:
            logger.error(f'❌ Claude API 错误: {e}')
            # 检查是否是限流错误
            error_message = str(e)
            if 'rate_limit' in error_message.lower() or 'too many requests' in error_message.lower():
                return {
                    'success': False,
                    'error': 'API 调用频率超限，请稍后再试'
                }
            else:
                return {
                    'success': False,
                    'error': f'AI 服务错误: {error_message}'
                }
        
        except Exception as e:
            logger.error(f'❌ 未知错误: {e}', exc_info=True)
            error_message = str(e)
            # 检查是否是连接错误
            if 'connect' in error_message.lower() or 'network' in error_message.lower():
                return {
                    'success': False,
                    'error': '无法连接到 AI 服务，请检查网络'
                }
            return {
                'success': False,
                'error': f'系统错误: {error_message}'
            }
    
    def call_claude_vision(
        self,
        system_prompt: str,
        user_prompt: str,
        image_url: str,
        response_format: str = 'json'
    ) -> Dict[str, Any]:
        """
        调用 Claude Vision API 分析图片
        
        Args:
            system_prompt: 系统提示词
            user_prompt: 用户提示词
            image_url: 图片 URL（Firebase Storage 公开链接）
            response_format: 响应格式 ('json' 或 'text')
        
        Returns:
            Dict containing the response
        
        Raises:
            Exception: API 调用失败
        """
        try:
            logger.info(f'🤖 调用 Claude Vision API - Model: {self.model}')
            logger.info(f'图片 URL: {image_url[:100]}...')
            logger.debug(f'User Prompt (前100字): {user_prompt[:100]}...')
            
            # 构建消息（包含图片）
            messages = [
                {
                    'role': 'user',
                    'content': [
                        {
                            'type': 'image',
                            'source': {
                                'type': 'url',
                                'url': image_url,
                            },
                        },
                        {
                            'type': 'text',
                            'text': user_prompt
                        }
                    ]
                }
            ]
            
            # 调用 API
            response = self.client.messages.create(
                model=self.model,
                max_tokens=self.max_tokens,
                temperature=self.temperature,
                system=system_prompt,
                messages=messages
            )
            
            # 提取响应文本
            if response.content and len(response.content) > 0:
                content = response.content[0].text
                logger.info(f'✅ Claude Vision API 调用成功')
                logger.info(f'Response: {content}')
                
                # 如果需要JSON格式，尝试解析
                if response_format == 'json':
                    try:
                        # 清理可能的 markdown 代码块标记
                        content = content.strip()
                        if content.startswith('```json'):
                            content = content[7:]
                        if content.startswith('```'):
                            content = content[3:]
                        if content.endswith('```'):
                            content = content[:-3]
                        content = content.strip()
                        
                        parsed_json = json.loads(content)
                        return {
                            'success': True,
                            'data': parsed_json,
                            'raw_text': content
                        }
                    except json.JSONDecodeError as e:
                        logger.warning(f'⚠️ JSON 解析失败: {e}')
                        return {
                            'success': False,
                            'error': f'JSON 解析失败: {str(e)}',
                            'raw_text': content
                        }
                else:
                    return {
                        'success': True,
                        'data': content
                    }
            else:
                logger.error('❌ Claude Vision 响应为空')
                return {
                    'success': False,
                    'error': 'Claude Vision 响应为空'
                }
        
        except APIError as e:
            logger.error(f'❌ Claude Vision API 错误: {e}')
            error_message = str(e)
            if 'rate_limit' in error_message.lower() or 'too many requests' in error_message.lower():
                return {
                    'success': False,
                    'error': 'API 调用频率超限，请稍后再试'
                }
            else:
                return {
                    'success': False,
                    'error': f'AI 服务错误: {error_message}'
                }
        
        except Exception as e:
            logger.error(f'❌ 未知错误: {e}', exc_info=True)
            error_message = str(e)
            if 'connect' in error_message.lower() or 'network' in error_message.lower():
                return {
                    'success': False,
                    'error': '无法连接到 AI 服务，请检查网络'
                }
            return {
                'success': False,
                'error': f'系统错误: {error_message}'
            }
    
    def call_claude_streaming(
        self,
        system_prompt: str,
        user_prompt: str,
        tools: list = None,
    ):
        """
        使用 Tool Use + Streaming 调用 Claude

        返回一个生成器，实时 yield 流式事件

        Args:
            system_prompt: 系统提示词
            user_prompt: 用户提示词
            tools: Tool Use 工具定义列表（可选，None表示纯文本响应）

        Yields:
            dict: 流式事件
                - type: 'text_delta' | 'tool_start' | 'tool_delta' | 'tool_complete' | 'error'
                - text: 文本增量（text_delta时）
                - tool_name: 工具名称
                - tool_input: 工具输入数据（完整）
                - partial_json: 部分 JSON 字符串（可选）
                - error: 错误信息（如果有）
        """
        try:
            logger.info(f'🔄 开始流式调用 Claude - Model: {self.model}')
            logger.debug(f'System Prompt (前100字): {system_prompt[:100]}...')
            logger.debug(f'User Prompt (前100字): {user_prompt[:100]}...')
            if tools:
                logger.info(f'Tools: {[t["name"] for t in tools]}')
            else:
                logger.info('Tools: None (纯文本模式)')

            # 构建API参数
            api_params = {
                'model': self.model,
                'max_tokens': self.max_tokens,
                'temperature': self.temperature,
                'system': system_prompt,
                'messages': [
                    {
                        'role': 'user',
                        'content': user_prompt
                    }
                ]
            }

            # 只在有tools时添加tools参数
            if tools:
                api_params['tools'] = tools

            # 使用 stream 模式调用
            with self.client.messages.stream(**api_params) as stream:
                # 监听流式事件
                for event in stream:
                    # 内容块开始
                    if event.type == 'content_block_start':
                        if hasattr(event, 'content_block'):
                            # 工具调用开始
                            if event.content_block.type == 'tool_use':
                                tool_name = event.content_block.name
                                logger.info(f'🔧 开始调用工具: {tool_name}')
                                yield {
                                    'type': 'tool_start',
                                    'tool_name': tool_name
                                }
                            # 文本内容开始
                            elif event.content_block.type == 'text':
                                logger.info(f'📝 开始文本内容')

                    # 内容增量
                    elif event.type == 'content_block_delta':
                        if hasattr(event, 'delta'):
                            # 工具调用增量（部分 JSON）
                            if hasattr(event.delta, 'partial_json'):
                                partial = event.delta.partial_json
                                yield {
                                    'type': 'tool_delta',
                                    'partial_json': partial
                                }
                            # 文本增量
                            elif hasattr(event.delta, 'text'):
                                text = event.delta.text
                                logger.debug(f'📝 文本增量: {text[:50]}...')
                                yield {
                                    'type': 'text_delta',
                                    'text': text
                                }

                    # 内容块完成
                    elif event.type == 'content_block_stop':
                        pass  # 等待获取最终消息

                # 获取最终消息
                final_message = stream.get_final_message()

                # 提取内容
                for content_block in final_message.content:
                    # 工具调用结果
                    if content_block.type == 'tool_use':
                        tool_name = content_block.name
                        tool_input = content_block.input

                        logger.info(f'✅ 工具调用完成: {tool_name}')
                        logger.info(f'Tool Input are: {tool_input}')

                        yield {
                            'type': 'tool_complete',
                            'tool_name': tool_name,
                            'tool_input': tool_input
                        }
                    # 文本内容（如果没有通过delta发送）
                    elif content_block.type == 'text':
                        text = content_block.text
                        logger.info(f'✅ 文本内容完成，长度: {len(text)}')
                        # 通常文本已经通过delta发送，这里只是备份
                        # 如果需要，可以发送完整文本
                        yield {
                            'type': 'text_complete',
                            'text': text
                        }
        
        except Exception as e:
            logger.error(f'❌ Streaming 调用失败: {str(e)}', exc_info=True)
            yield {
                'type': 'error',
                'error': str(e)
            }

    def call_claude_with_skill(
        self,
        user_prompt: str,
        skill_id: str,
        system_prompt: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        使用 Claude Skill 调用 API

        此方法强制使用 claude-sonnet-4-5-20250929 模型和 Code Execution 功能

        Args:
            user_prompt: 用户提示词
            skill_id: Anthropic Skill ID
            system_prompt: 系统提示词（可选）

        Returns:
            Dict containing the response:
            {
                "success": bool,
                "data": dict,  # 解析后的 JSON 数据
                "raw_text": str,  # 原始响应文本
                "error": str  # 错误信息（如果失败）
            }

        Raises:
            Exception: API 调用失败
        """
        try:
            logger.info('🤖 调用 Claude API with Skill')
            logger.info(f'🔧 Skill ID: {skill_id}')
            logger.info(f'📝 Model: claude-sonnet-4-5-20250929 (强制)')
            logger.debug(f'User Prompt (前100字): {user_prompt[:100]}...')

            # 构建 API 参数
            api_params = {
                'model': 'claude-sonnet-4-5-20250929',  # 强制使用此模型
                'max_tokens': 8000,
                'betas': [
                    'code-execution-2025-08-25',  # Code Execution
                    'skills-2025-10-02'  # Skills API
                ],
                'container': {
                    'skills': [
                        {
                            'type': 'custom',
                            'skill_id': skill_id,
                            'version': 'latest'
                        }
                    ]
                },
                'messages': [
                    {
                        'role': 'user',
                        'content': user_prompt
                    }
                ],
                'tools': [
                    {
                        'type': 'code_execution_20250825',
                        'name': 'code_execution'
                    }
                ]
            }

            # 如果提供了 system_prompt，添加到参数中
            if system_prompt:
                api_params['system'] = system_prompt

            # 调用 Beta API
            response = self.client.beta.messages.create(**api_params)

            logger.info('✅ Claude API with Skill 调用成功')

            # 记录 response 对象的关键属性
            logger.info(f'Response 属性:')
            logger.info(f'  - id: {response.id}')
            logger.info(f'  - model: {response.model}')
            logger.info(f'  - role: {response.role}')
            logger.info(f'  - stop_reason: {response.stop_reason}')

            # 检查是否有其他可能包含数据的属性
            if hasattr(response, 'output'):
                logger.info(f'  - output: {type(response.output)}')

            # 记录响应的所有 content blocks
            logger.info(f'📦 响应包含 {len(response.content)} 个 content blocks')
            for i, block in enumerate(response.content):
                logger.info(f'   Block {i}: type={block.type}')

                # 详细记录每个 block 的属性
                if hasattr(block, 'name'):
                    logger.info(f'      name={block.name}')
                if hasattr(block, 'id'):
                    logger.info(f'      id={block.id}')
                if hasattr(block, 'input'):
                    logger.info(f'      input type={type(block.input)}')
                    if isinstance(block.input, dict):
                        logger.info(f'      input keys={list(block.input.keys())}')

            # 将响应写入 JSON 文件以便调试
            if SAVE_DEBUG_RESPONSE:
                try:
                    import datetime
                    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
                    debug_dir = os.path.join(os.path.dirname(__file__), 'debug_responses')
                    os.makedirs(debug_dir, exist_ok=True)
                    debug_file = os.path.join(debug_dir, f'response_{timestamp}.json')
                    
                    # 将响应对象转换为字典
                    response_dict = {
                        'id': response.id,
                        'model': response.model,
                        'role': response.role,
                        'stop_reason': response.stop_reason,
                        'stop_sequence': getattr(response, 'stop_sequence', None),
                        'usage': {
                            'input_tokens': response.usage.input_tokens,
                            'output_tokens': response.usage.output_tokens,
                        } if hasattr(response, 'usage') else None,
                        'content': []
                    }
                    # 序列化每个 content block
                    for block in response.content:
                        block_dict = {
                            'type': block.type
                        }
                        if hasattr(block, 'text'):
                            block_dict['text'] = block.text
                        if hasattr(block, 'name'):
                            block_dict['name'] = block.name
                        if hasattr(block, 'id'):
                            block_dict['id'] = block.id
                        if hasattr(block, 'input'):
                            block_dict['input'] = block.input
                        response_dict['content'].append(block_dict)
                    
                    with open(debug_file, 'w', encoding='utf-8') as f:
                        json.dump(response_dict, f, indent=2, ensure_ascii=False)
                    
                    logger.info(f'💾 响应已保存到: {debug_file}')
                except Exception as e:
                    logger.warning(f'⚠️ 保存响应文件失败: {str(e)}')

            # 首先尝试从 tool_use block 中提取 skill 执行结果
            skill_result = None
            for block in response.content:
                if block.type == 'tool_use':
                    logger.info(f'🔧 找到 tool_use block: name={getattr(block, "name", "unknown")}')

                    # 检查是否是 code_execution
                    if hasattr(block, 'name') and block.name == 'code_execution':
                        logger.info('   这是 code_execution tool')

                        # 尝试从 input 中提取
                        if hasattr(block, 'input'):
                            input_data = block.input
                            logger.info(f'   input 类型: {type(input_data)}')

                            if isinstance(input_data, dict):
                                logger.info(f'   input 包含的键: {list(input_data.keys())}')

                                # 检查是否包含营养数据的关键字段
                                if 'bmr_kcal' in input_data or 'target_calories_kcal' in input_data:
                                    skill_result = input_data
                                    logger.info('   ✅ 这看起来是营养计算结果！')
                                    break
                                elif 'code' in input_data:
                                    logger.info('   这是代码输入，不是结果')
                                else:
                                    logger.info(f'   包含其他数据: {list(input_data.keys())[:5]}')
                            else:
                                logger.info(f'   input 不是 dict: {str(input_data)[:100]}')
                        else:
                            logger.info('   没有 input 属性')

            # 如果从 tool_use 中找到了结果，直接使用
            if skill_result and isinstance(skill_result, dict):
                logger.info('✅ 使用 tool_use block 中的 skill 执行结果')
                return {
                    'success': True,
                    'data': skill_result,
                    'raw_text': ''
                }

            # 否则，尝试从文本中提取
            logger.info('ℹ️ 未找到 tool_use 结果，尝试从文本中提取')

            # 提取响应文本
            response_text = ''
            for block in response.content:
                if block.type == 'text':
                    response_text += block.text
                    logger.debug(f'📝 文本块长度: {len(block.text)} 字符')

            logger.info(f'📊 总响应文本长度: {len(response_text)} 字符')

            # 记录响应文本的前 2000 字符（用于调试）
            if len(response_text) > 0:
                preview_length = min(2000, len(response_text))
                logger.info(f'📄 响应预览 (前 {preview_length} 字符):')
                logger.info('=' * 70)
                logger.info(response_text[:preview_length])
                logger.info('=' * 70)
            else:
                logger.warning('⚠️ 响应文本为空！')

            # 解析 JSON
            parsed_data = self._extract_json_from_skill_response(response_text)

            if parsed_data is not None:
                logger.info('✅ JSON 解析成功')
                logger.debug(f'解析后的数据键: {list(parsed_data.keys())}')
                return {
                    'success': True,
                    'data': parsed_data,
                    'raw_text': response_text
                }
            else:
                logger.error('❌ 无法从响应中提取有效的 JSON')
                logger.error('完整响应内容:')
                logger.error(response_text)
                return {
                    'success': False,
                    'error': 'Could not parse JSON from response',
                    'raw_text': response_text
                }

        except APIError as e:
            logger.error(f'❌ Claude API 错误: {e}')
            error_message = str(e)
            if 'rate_limit' in error_message.lower() or 'too many requests' in error_message.lower():
                return {
                    'success': False,
                    'error': 'API 调用频率超限，请稍后再试'
                }
            else:
                return {
                    'success': False,
                    'error': f'AI 服务错误: {error_message}'
                }

        except Exception as e:
            logger.error(f'❌ 调用失败: {str(e)}', exc_info=True)
            error_message = str(e)
            if 'connect' in error_message.lower() or 'network' in error_message.lower():
                return {
                    'success': False,
                    'error': '无法连接到 AI 服务，请检查网络'
                }
            return {
                'success': False,
                'error': f'系统错误: {error_message}'
            }

    def _extract_json_from_skill_response(self, text: str) -> Optional[Dict[str, Any]]:
        """
        从 Skill 响应中提取 JSON

        支持多种格式：
        1. 直接 JSON
        2. ```json code block
        3. 混合文本中的 JSON 对象

        Args:
            text: 响应文本

        Returns:
            解析后的 dict，或 None（如果解析失败）
        """
        import re
        import json

        logger.info('🔍 开始 JSON 提取...')

        # 1. 尝试直接解析整个文本
        logger.debug('尝试方法 1: 直接解析整个文本')
        try:
            data = json.loads(text)
            logger.info('✅ 方法 1 成功：直接解析')
            return data
        except json.JSONDecodeError as e:
            logger.debug(f'方法 1 失败: {str(e)}')

        # 2. 尝试提取 JSON code block
        logger.debug('尝试方法 2: 提取 ```json``` code block')
        json_block_pattern = r'```json\s*([\s\S]*?)\s*```'
        json_blocks = re.findall(json_block_pattern, text)

        if json_blocks:
            logger.debug(f'找到 {len(json_blocks)} 个 JSON code blocks')
            for i, block in enumerate(json_blocks):
                try:
                    data = json.loads(block)
                    logger.info(f'✅ 方法 2 成功：从 code block {i} 解析')
                    return data
                except json.JSONDecodeError as e:
                    logger.debug(f'Code block {i} 解析失败: {str(e)}')
        else:
            logger.debug('未找到 JSON code blocks')

        # 3. 尝试查找第一个完整的 JSON 对象
        logger.debug('尝试方法 3: 查找 JSON 对象')
        json_pattern = r'\{[\s\S]*\}'
        matches = re.findall(json_pattern, text)

        if matches:
            logger.debug(f'找到 {len(matches)} 个可能的 JSON 对象')
            for i, match in enumerate(matches):
                try:
                    data = json.loads(match)
                    logger.debug(f'JSON 对象 {i} 解析成功，检查关键字段...')
                    logger.debug(f'对象键: {list(data.keys())}')

                    # 检查是否包含期望的关键字段（营养计算相关）
                    if 'bmr_kcal' in data or 'target_calories_kcal' in data or 'macros' in data:
                        logger.info(f'✅ 方法 3 成功：从 JSON 对象 {i} 解析')
                        return data
                    else:
                        logger.debug(f'JSON 对象 {i} 缺少期望的关键字段')
                except json.JSONDecodeError as e:
                    logger.debug(f'JSON 对象 {i} 解析失败: {str(e)[:100]}')
        else:
            logger.debug('未找到 JSON 对象模式')

        logger.error('❌ 所有 JSON 提取方法均失败')
        return None


# 全局单例
_claude_client: Optional[ClaudeClient] = None


def get_claude_client() -> ClaudeClient:
    """获取 Claude 客户端单例"""
    global _claude_client
    if _claude_client is None:
        _claude_client = ClaudeClient()
    return _claude_client


