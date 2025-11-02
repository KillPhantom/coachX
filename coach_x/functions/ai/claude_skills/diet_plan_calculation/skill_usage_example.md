```python
"""
Firebase Cloud Functions - Nutrition Calculator
Python版本，使用Claude API和nutrition-calculator skill
"""

import json
import os
import re
from typing import Dict, Any, Optional

from firebase_functions import https_fn, options
from firebase_admin import initialize_app, auth
from anthropic import Anthropic

# 初始化Firebase Admin
initialize_app()

# 初始化Anthropic客户端
anthropic_client = Anthropic(
    api_key=os.environ.get('ANTHROPIC_API_KEY')
)

# Nutrition Calculator Skill ID
# ⚠️ 部署前需要运行 upload_skill.py 获取此ID
NUTRITION_SKILL_ID = os.environ.get('NUTRITION_SKILL_ID', 'skill_placeholder')


@https_fn.on_call(
    region="us-central1",
    memory=options.MemoryOption.MB_512,
    timeout_sec=300,
    max_instances=10
)
def calculate_nutrition(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    计算用户的营养需求和详细饮食计划
    
    Args:
        req: Firebase CallableRequest对象，包含用户数据
        
    Returns:
        Dict包含计算结果或错误信息
    """
    try:
        # 1. 验证用户认证
        if not req.auth:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="User must be authenticated"
            )
        
        user_id = req.auth.uid
        
        # 2. 提取并验证请求数据
        data = req.data
        
        # 必需参数
        required_fields = ['weight_kg', 'height_cm', 'age', 'gender', 'activity_level', 'goal']
        missing_fields = [field for field in required_fields if field not in data]
        
        if missing_fields:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message=f"Missing required fields: {', '.join(missing_fields)}"
            )
        
        # 构建用户数据字典
        user_data = {
            'weight_kg': data['weight_kg'],
            'height_cm': data['height_cm'],
            'age': data['age'],
            'gender': data['gender'],
            'activity_level': data['activity_level'],
            'goal': data['goal'],
        }
        
        # 可选参数
        optional_fields = [
            'body_fat_percentage',
            'goal_rate_kg_per_month',
            'training_plan',
            'dietary_preferences',
            'meal_count',
            'allergies',
            'plan_duration_days'
        ]
        
        for field in optional_fields:
            if field in data and data[field] is not None:
                user_data[field] = data[field]
        
        # 3. 验证数据范围
        _validate_input_data(user_data)
        
        # 4. 记录请求日志
        print(f"🔍 Processing nutrition calculation for user: {user_id}")
        print(f"📊 User data: {json.dumps(user_data, ensure_ascii=False, indent=2)}")
        
        # 5. 调用Claude API
        nutrition_result = _call_claude_api(user_data)
        
        # 6. 记录成功日志
        print(f"✅ Nutrition calculation successful for user: {user_id}")
        print(f"🎯 Target calories: {nutrition_result.get('target_calories_kcal')} kcal")
        
        # 7. 返回结果
        return {
            'success': True,
            'data': nutrition_result,
            'user_id': user_id
        }
        
    except https_fn.HttpsError:
        # 重新抛出Firebase错误
        raise
        
    except Exception as e:
        # 捕获其他错误并记录
        print(f"❌ Error in calculate_nutrition: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Failed to calculate nutrition plan",
            details=str(e)
        )


def _validate_input_data(data: Dict[str, Any]) -> None:
    """验证输入数据的有效性"""
    
    # 验证体重
    if not (0 < data['weight_kg'] <= 300):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Weight must be between 0 and 300 kg"
        )
    
    # 验证身高
    if not (0 < data['height_cm'] <= 250):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Height must be between 0 and 250 cm"
        )
    
    # 验证年龄
    if not (10 <= data['age'] <= 120):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Age must be between 10 and 120 years"
        )
    
    # 验证性别
    if data['gender'] not in ['male', 'female']:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Gender must be 'male' or 'female'"
        )
    
    # 验证活动水平
    valid_activity_levels = ['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active']
    if data['activity_level'] not in valid_activity_levels:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Activity level must be one of: {', '.join(valid_activity_levels)}"
        )
    
    # 验证目标
    if data['goal'] not in ['fat_loss', 'muscle_gain', 'maintenance']:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Goal must be 'fat_loss', 'muscle_gain', or 'maintenance'"
        )
    
    # 验证体脂率（如果提供）
    if 'body_fat_percentage' in data:
        if not (0 <= data['body_fat_percentage'] <= 100):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Body fat percentage must be between 0 and 100"
            )


def _call_claude_api(user_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    调用Claude API进行营养计算
    
    Args:
        user_data: 用户输入数据
        
    Returns:
        营养计算结果
    """
    try:
        # 构建请求内容
        request_content = json.dumps(user_data, ensure_ascii=False, indent=2)
        
        # 构建用户消息
        user_message = f"""使用nutrition-calculator skill计算以下用户的营养需求和详细饮食计划：

{request_content}

请按照skill定义的格式返回完整的JSON结果，包括：
1. BMR、TDEE和目标热量
2. Macros分配（蛋白质、脂肪、碳水）
3. 详细的diet_plan_recommendation（按天/餐/食物格式）

确保返回的是有效的JSON格式。"""

        print(f"🤖 Calling Claude API with skill: {NUTRITION_SKILL_ID}")
        
        # 调用Claude API
        response = anthropic_client.beta.messages.create(
            model="claude-sonnet-4-5-20250929",
            max_tokens=8000,
            betas=["code-execution-2025-08-25", "skills-2025-10-02"],
            container={
                "skills": [
                    {
                        "type": "custom",
                        "skill_id": NUTRITION_SKILL_ID,
                        "version": "latest"
                    }
                ]
            },
            messages=[
                {
                    "role": "user",
                    "content": user_message
                }
            ],
            tools=[
                {
                    "type": "code_execution_20250825",
                    "name": "code_execution"
                }
            ]
        )
        
        # 提取响应文本
        response_text = ""
        for block in response.content:
            if block.type == "text":
                response_text += block.text
        
        print(f"📝 Claude response length: {len(response_text)} characters")
        
        # 解析JSON结果
        nutrition_data = _extract_json_from_response(response_text)
        
        if not nutrition_data:
            raise ValueError("Could not parse JSON from Claude response")
        
        # 验证返回的数据结构
        _validate_response_structure(nutrition_data)
        
        return nutrition_data
        
    except Exception as e:
        print(f"❌ Claude API call failed: {str(e)}")
        raise


def _extract_json_from_response(text: str) -> Optional[Dict[str, Any]]:
    """从Claude响应中提取JSON"""
    
    # 尝试直接解析整个文本
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    
    # 尝试提取JSON块（在```json ... ```中）
    json_block_pattern = r'```json\s*([\s\S]*?)\s*```'
    json_blocks = re.findall(json_block_pattern, text)
    
    if json_blocks:
        try:
            return json.loads(json_blocks[0])
        except json.JSONDecodeError:
            pass
    
    # 尝试查找第一个完整的JSON对象
    json_pattern = r'\{[\s\S]*\}'
    matches = re.findall(json_pattern, text)
    
    for match in matches:
        try:
            data = json.loads(match)
            # 检查是否包含期望的关键字段
            if 'bmr_kcal' in data or 'target_calories_kcal' in data:
                return data
        except json.JSONDecodeError:
            continue
    
    return None


def _validate_response_structure(data: Dict[str, Any]) -> None:
    """验证响应数据结构的完整性"""
    
    required_fields = ['bmr_kcal', 'tdee_kcal', 'target_calories_kcal', 'macros']
    
    missing_fields = [field for field in required_fields if field not in data]
    
    if missing_fields:
        raise ValueError(f"Response missing required fields: {', '.join(missing_fields)}")
    
    # 验证macros结构
    if 'macros' in data:
        required_macros = ['protein', 'fat', 'carbohydrates']
        missing_macros = [m for m in required_macros if m not in data['macros']]
        
        if missing_macros:
            raise ValueError(f"Macros missing required fields: {', '.join(missing_macros)}")


# ========== 可选：批量计算功能 ==========

@https_fn.on_call(
    region="us-central1",
    memory=options.MemoryOption.MB_1024,
    timeout_sec=540,
    max_instances=5
)
def batch_calculate_nutrition(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    批量计算多个用户的营养需求
    
    适用场景：
    - 健身房批量为会员生成计划
    - 营养师为多个客户生成方案
    
    Args:
        req: 包含多个用户数据的请求
        
    Returns:
        批量计算结果
    """
    try:
        # 验证用户认证
        if not req.auth:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="User must be authenticated"
            )
        
        users_data = req.data.get('users', [])
        
        if not users_data or not isinstance(users_data, list):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Must provide 'users' array"
            )
        
        # 限制批量数量
        if len(users_data) > 10:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Maximum 10 users per batch request"
            )
        
        results = []
        errors = []
        
        for idx, user_data in enumerate(users_data):
            try:
                _validate_input_data(user_data)
                nutrition_result = _call_claude_api(user_data)
                
                results.append({
                    'index': idx,
                    'success': True,
                    'data': nutrition_result
                })
                
            except Exception as e:
                errors.append({
                    'index': idx,
                    'success': False,
                    'error': str(e)
                })
        
        return {
            'success': True,
            'total': len(users_data),
            'successful': len(results),
            'failed': len(errors),
            'results': results,
            'errors': errors
        }
        
    except https_fn.HttpsError:
        raise
        
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="Batch calculation failed",
            details=str(e)
        )

```