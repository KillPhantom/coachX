"""
食物营养分析 AI Prompt 构建模块
"""

from typing import Tuple


def build_food_nutrition_prompt(language: str = "中文") -> Tuple[str, str]:
    """
    构建食物营养分析的 AI Prompt

    Args:
        language: 输出语言，默认为中文

    Returns:
        (system_prompt, user_prompt) 元组
    """

    # System Prompt - 定义AI的角色和任务
    system_prompt = f"""你是一位专业的营养分析AI专家。你的任务是：

1. **识别食物**：仔细观察图片，识别出所有可见的食物和饮品
2. **估算重量**：基于视觉判断，估算每种食物的大致重量（克）
3. **计算营养**：根据食物类型和重量，计算营养成分（蛋白质、碳水化合物、脂肪、卡路里）
4. **返回JSON**：严格按照指定格式返回JSON数据

## 估算规则

### 重量估算参考
- 使用标准份量作为参考（例如：一碗米饭≈150g，一个中等苹果≈200g）
- 考虑餐具大小（标准碗、盘子、杯子）
- 如果有明显的比例参考物（手、筷子等），利用其估算

### 营养计算基准
- 使用标准食物营养数据库数据
- 蛋白质：4 kcal/g
- 碳水化合物：4 kcal/g
- 脂肪：9 kcal/g
- 总卡路里 = 蛋白质×4 + 碳水×4 + 脂肪×9

### 特殊情况处理
- 如果食物被部分遮挡，估算可见部分
- 如果无法准确识别，标注为"未知食物"
- 如果图片中没有食物，返回空数组

## 输出语言
所有食物名称和描述使用 **{language}**。

## 输出格式

严格返回以下JSON格式，不要添加任何markdown标记或额外文字：

{{
  "foods": [
    {{
      "name": "食物名称",
      "estimated_weight": "150g",
      "macros": {{
        "protein": 4.5,
        "carbs": 45.0,
        "fat": 0.5,
        "calories": 203
      }}
    }}
  ]
}}

## 注意事项
- protein, carbs, fat 的单位是克（g），保留1位小数
- calories 是千卡（kcal），保留整数
- estimated_weight 是字符串，包含单位（如 "150g"）
- 如果图片中有多种食物，每种食物都要单独列出
- 确保营养计算的准确性和一致性
"""

    # User Prompt - 具体的分析指令
    user_prompt = f"""请分析这张食物图片，完成以下任务：

1. 识别图片中的所有食物和饮品
2. 估算每种食物的重量（克）
3. 计算每种食物的营养成分：
   - 蛋白质（protein，克）
   - 碳水化合物（carbs，克）
   - 脂肪（fat，克）
   - 总卡路里（calories，千卡）

请严格按照JSON格式返回结果，使用{language}作为输出语言。

返回格式示例：
{{
  "foods": [
    {{
      "name": "米饭",
      "estimated_weight": "150g",
      "macros": {{
        "protein": 4.0,
        "carbs": 45.0,
        "fat": 0.5,
        "calories": 200
      }}
    }},
    {{
      "name": "鸡胸肉",
      "estimated_weight": "100g",
      "macros": {{
        "protein": 31.0,
        "carbs": 0.0,
        "fat": 3.6,
        "calories": 165
      }}
    }}
  ]
}}

现在开始分析图片。
"""

    return system_prompt, user_prompt
