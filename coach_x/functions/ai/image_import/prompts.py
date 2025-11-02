"""
图片导入 Prompt 模板

为图片导入训练计划提供 Prompt 模板
"""

from ..training_plan.prompts import get_system_prompt


# ==================== 图片导入识别 ====================

VISION_IMPORT_PROMPT = """
你正在帮助用户从图片中导入训练计划。
请仔细分析这张图片，提取所有训练信息。

返回 JSON 格式如下：
{
  "name": "计划名称（如果能识别，否则生成一个）",
  "description": "简要描述（根据图片内容概括）",
  "days": [
    {
      "day": 1,
      "name": "训练日名称（如：胸部训练）",
      "type": "训练类型（如：胸部训练、腿部训练等）",
      "note": "备注（如果有）",
      "exercises": [
        {
          "name": "动作名称（保持图片原始语言）",
          "note": "动作备注（如果有）",
          "type": "strength",
          "sets": [
            {"reps": "次数", "weight": "重量"}
          ]
        }
      ]
    }
  ],
  "confidence": 0.95,
  "warnings": [
    "某些重量数据模糊，已使用默认值",
    "第3天的某个动作名称不清晰"
  ]
}

重要说明：
1. **动作名称**：
   - 保持图片中的原始语言（如果是中文就用中文，如果是英文就用英文）
   - 不要自行翻译动作名称
   - 常见动作：深蹲、卧推、硬拉、引体向上 或 Squats、Bench Press、Deadlift、Pull-ups

2. **数据提取**：
   - 仔细识别组数、次数、重量
   - 如果重量单位不明确，默认使用 "kg"
   - 如果次数范围（如8-12），取中间值 "10"
   - 如果数据模糊或缺失，标注到 warnings

3. **置信度评估（confidence）**：
   - 图片清晰，数据完整 → 0.9-1.0
   - 图片清晰，部分数据缺失 → 0.7-0.9
   - 图片模糊，数据不全 → 0.5-0.7
   - 难以识别 → < 0.5

4. **警告信息（warnings）**：
   - 列出所有不确定或缺失的信息
   - 指明具体位置（第几天、第几个动作）
   - 说明采取的默认处理方式

5. **训练日编号**：
   - day 字段从 1 开始递增
   - 保持连续性

6. **数据完整性**：
   - 确保每个动作至少有 1 组 sets
   - 每组至少要有 reps（次数）
   - weight 可选（自重动作可以为空字符串）

现在请分析图片并提取训练计划：
"""


def build_vision_import_prompt(language: str = '中文') -> tuple:
    """构建图片导入识别的 Prompt"""
    system = get_system_prompt(language)
    user = VISION_IMPORT_PROMPT
    return system, user
