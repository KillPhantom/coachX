"""
Claude Skills 管理模块

自动检测、上传和管理 Claude Skills
"""

import os
import re
from typing import Dict, Any, Optional
from pathlib import Path
from anthropic import Anthropic

from utils.logger import logger


def verify_skill(skill_id: str) -> Dict[str, Any]:
    """
    验证 skill 是否存在于 Anthropic

    Args:
        skill_id: 要验证的 skill ID

    Returns:
        {
            "exists": bool,
            "skill_id": str,
            "display_title": str,
            "created_at": str,
            "updated_at": str
        }

    Raises:
        Exception: API 调用失败
    """
    try:
        # 初始化客户端
        api_key = os.environ.get('ANTHROPIC_API_KEY')

        if not api_key:
            raise ValueError('ANTHROPIC_API_KEY 未配置在环境变量中')

        client = Anthropic(api_key=api_key)

        logger.info(f'🔍 验证 skill: {skill_id}')

        # 使用 retrieve() 方法获取 skill
        skill = client.beta.skills.retrieve(
            skill_id=skill_id,
            betas=["skills-2025-10-02"]
        )

        logger.info(f'✅ Skill 存在: {skill.display_title}')

        return {
            'exists': True,
            'skill_id': skill.id,
            'display_title': skill.display_title,
            'created_at': str(skill.created_at),
            'updated_at': str(skill.updated_at)
        }

    except Exception as e:
        logger.warning(f'⚠️ Skill 验证失败: {str(e)}')
        return {
            'exists': False,
            'error': str(e)
        }


def upload_skill(skill_path: str) -> Dict[str, Any]:
    """
    上传 skill 文件到 Anthropic

    Args:
        skill_path: skill 文件的路径（.skill 文件）

    Returns:
        {
            "success": bool,
            "skill_id": str,
            "display_title": str,
            "created_at": str,
            "error": str (if failed)
        }

    Raises:
        Exception: 上传失败
    """
    try:
        # 初始化客户端
        api_key = os.environ.get('ANTHROPIC_API_KEY')

        if not api_key:
            raise ValueError('ANTHROPIC_API_KEY 未配置在环境变量中')

        client = Anthropic(api_key=api_key)

        # 检查文件是否存在
        skill_file = Path(skill_path)
        if not skill_file.exists():
            raise FileNotFoundError(f'Skill 文件不存在: {skill_path}')

        logger.info(f'📦 上传 skill 文件: {skill_path}')
        logger.info(f'📏 文件大小: {skill_file.stat().st_size / 1024:.2f} KB')

        # 读取 skill 文件
        with open(skill_path, 'rb') as f:
            skill_data = f.read()

        # 上传 skill
        logger.info('🚀 正在上传到 Anthropic...')

        skill = client.beta.skills.create(
            display_title="Nutrition Calculator v2.0",
            files=[
                (skill_file.name, skill_data)
            ],
            betas=["skills-2025-10-02"]
        )

        logger.info(f'✅ Skill 上传成功!')
        logger.info(f'📝 Skill ID: {skill.id}')
        logger.info(f'📅 创建时间: {skill.created_at}')

        return {
            'success': True,
            'skill_id': skill.id,
            'display_title': "Nutrition Calculator v2.0",
            'created_at': str(skill.created_at)
        }

    except Exception as e:
        logger.error(f'❌ Skill 上传失败: {str(e)}', exc_info=True)
        return {
            'success': False,
            'error': str(e)
        }


def update_skill_constant(skill_id: str) -> bool:
    """
    更新 skill_constants.py 文件，写入 skill_id

    Args:
        skill_id: 要写入的 skill ID

    Returns:
        bool: 更新是否成功
    """
    try:
        # 获取 skill_constants.py 文件路径
        current_dir = Path(__file__).parent
        constants_file = current_dir / 'skill_constants.py'

        if not constants_file.exists():
            logger.error(f'❌ 常量文件不存在: {constants_file}')
            return False

        # 读取文件内容
        with open(constants_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # 使用正则表达式替换
        pattern = r'NUTRITION_CALCULATOR_SKILL_ID\s*=\s*None'
        replacement = f'NUTRITION_CALCULATOR_SKILL_ID = "{skill_id}"'

        new_content = re.sub(pattern, replacement, content)

        # 检查是否发生了替换
        if new_content == content:
            logger.warning('⚠️ 常量文件中未找到匹配的 NUTRITION_CALCULATOR_SKILL_ID = None')
            # 尝试强制替换（可能已经有值）
            pattern2 = r'NUTRITION_CALCULATOR_SKILL_ID\s*=\s*["\']?[^"\'\n]*["\']?'
            new_content = re.sub(pattern2, replacement, content)

        # 写回文件
        with open(constants_file, 'w', encoding='utf-8') as f:
            f.write(new_content)

        logger.info(f'✅ 常量文件已更新: {constants_file}')
        logger.info(f'📝 Skill ID: {skill_id}')

        return True

    except Exception as e:
        logger.error(f'❌ 更新常量文件失败: {str(e)}', exc_info=True)
        return False


def get_or_create_nutrition_skill() -> str:
    """
    获取或创建 Nutrition Calculator Skill

    工作流程：
    1. 从 skill_constants 读取 NUTRITION_CALCULATOR_SKILL_ID
    2. 如果为 None -> 上传 skill
    3. 如果不为 None -> 验证是否存在
       - 存在 -> 返回 skill_id
       - 不存在 -> 上传 skill
    4. 上传后更新常量文件

    Returns:
        str: Skill ID

    Raises:
        Exception: 无法获取或创建 skill
    """
    try:
        # 导入常量
        from . import skill_constants

        skill_id = skill_constants.NUTRITION_CALCULATOR_SKILL_ID

        # 如果已有 skill_id，先验证是否存在
        if skill_id is not None:
            logger.info(f'📋 检测到已有 Skill ID: {skill_id}')

            result = verify_skill(skill_id)

            if result.get('exists'):
                logger.info('✅ Skill 验证通过，直接使用')
                return skill_id
            else:
                logger.warning(f'⚠️ Skill 不存在或已被删除，将重新上传')
        else:
            logger.info('📋 首次运行，未检测到 Skill ID')

        # 需要上传 skill
        logger.info('🔄 开始自动上传 nutrition-calculator skill...')

        # 获取 skill 文件路径
        current_dir = Path(__file__).parent
        skill_file = current_dir / 'diet_plan_calculation' / 'nutrition-calculator.skill'

        if not skill_file.exists():
            raise FileNotFoundError(f'Skill 文件不存在: {skill_file}')

        # 上传 skill
        upload_result = upload_skill(str(skill_file))

        if not upload_result.get('success'):
            error_msg = upload_result.get('error', 'Unknown error')
            raise Exception(f'Skill 上传失败: {error_msg}')

        new_skill_id = upload_result['skill_id']

        # 更新常量文件
        logger.info('📝 更新常量文件...')
        if update_skill_constant(new_skill_id):
            logger.info('✅ Skill 设置完成，可以正常使用')
        else:
            logger.warning('⚠️ 常量文件更新失败，下次运行时会重新上传')
            logger.warning(f'💡 请手动将以下 Skill ID 写入 skill_constants.py:')
            logger.warning(f'   NUTRITION_CALCULATOR_SKILL_ID = "{new_skill_id}"')

        return new_skill_id

    except Exception as e:
        logger.error(f'❌ 获取或创建 Skill 失败: {str(e)}', exc_info=True)
        raise
