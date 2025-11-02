"""
补剂计划图片导入 Prompt 模板

为图片导入补剂计划提供 Prompt 模板
"""

# ==================== 补剂计划图片导入识别 ====================

SUPPLEMENT_VISION_IMPORT_PROMPT = """
你正在帮助用户从图片中导入补剂计划。
请仔细分析这张图片，提取所有补剂信息。

返回 JSON 格式如下：
{
  "name": "计划名称（如果能识别，否则生成一个）",
  "description": "简要描述（根据图片内容概括）",
  "days": [
    {
      "day": 1,
      "name": "日期名称（如：训练日、休息日）",
      "timings": [
        {
          "name": "时间段名称（如：早餐后、训练前、训练后、睡前）",
          "note": "时间段备注（如果有）",
          "supplements": [
            {
              "name": "补剂名称（保持图片原始语言）",
              "amount": "用量（包括单位，如：10g、2粒）",
              "note": "备注（如果有）"
            }
          ]
        }
      ]
    }
  ],
  "confidence": 0.95,
  "warnings": [
    "某些用量数据模糊，已使用默认值",
    "第3天的某个补剂名称不清晰"
  ]
}

重要说明：
1. **补剂名称**：
   - 保持图片中的原始语言（如果是中文就用中文，如果是英文就用英文）
   - 不要自行翻译补剂名称
   - 常见补剂：蛋白粉、肌酸、BCAA、谷氨酰胺 或 Whey Protein、Creatine、BCAA、Glutamine

2. **数据提取**：
   - 仔细识别补剂名称、用量、服用时间
   - 用量必须包含单位（g、mg、粒、勺等）
   - 如果用量不明确，标注到 warnings
   - 如果数据模糊或缺失，标注到 warnings

3. **时间段识别（timings）**：
   - 常见时间段：早餐后、训练前、训练中、训练后、睡前
   - 可以根据图片内容识别特殊时间段
   - 每个时间段必须有 name 字段

4. **置信度评估（confidence）**：
   - 图片清晰，数据完整 → 0.9-1.0
   - 图片清晰，部分数据缺失 → 0.7-0.9
   - 图片模糊，数据不全 → 0.5-0.7
   - 难以识别 → < 0.5

5. **警告信息（warnings）**：
   - 列出所有不确定或缺失的信息
   - 指明具体位置（第几天、第几个时间段、第几个补剂）
   - 说明采取的默认处理方式

6. **天数编号**：
   - day 字段从 1 开始递增
   - 保持连续性

7. **数据完整性**：
   - 确保每个补剂日至少有 1 个时间段 timings
   - 每个时间段至少要有 1 个补剂 supplements
   - 每个补剂必须有 name 和 amount

现在请分析图片并提取补剂计划：
"""


def build_supplement_vision_import_prompt(language: str = "中文"):
    """
    构建补剂计划图片导入 Prompt

    Args:
        language: 输出语言，默认中文

    Returns:
        (system_prompt, user_prompt) 元组
    """
    system_prompt = f"""
你是一个专业的补剂计划识别助手。
你的任务是从图片中准确提取补剂计划信息，并以结构化 JSON 格式返回。
确保 JSON 格式正确，可被解析, 不包含markdown wrapper
请使用 {language} 回复。
"""

    user_prompt = SUPPLEMENT_VISION_IMPORT_PROMPT

    return (system_prompt, user_prompt)
