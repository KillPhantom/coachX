# 文本导入 API 测试用例

## 测试前准备

1. 配置 API Key:
```bash
cd functions
# 创建 .env 文件（如果不存在）
echo "ANTHROPIC_API_KEY=your-api-key-here" > .env
```

2. 启动模拟器:
```bash
export $(cat .env | xargs) && firebase emulators:start
```

3. 获取项目 ID（从 Firebase Console 或 .firebaserc）

---

## 测试用例 1: 英文简洁格式

**请求**:
```bash
curl -X POST http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/import_plan_from_text \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "data": {
      "text_content": "Day 1: Chest & Triceps\nBench Press 4x8 60kg\nIncline Dumbbell Press 3x12 20kg\nCable Flyes 3x15\nTricep Pushdown 3x12\n\nDay 2: Back & Biceps\nPull-ups 4x8\nBarbell Row 4x10 50kg"
    }
  }'
```

**期望结果**:
- status: "success"
- data.plan.days: 包含 2 个训练日
- Day 1 包含 4 个动作
- Day 2 包含 2 个动作

---

## 测试用例 2: 中文详细格式

**请求**:
```bash
curl -X POST http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/import_plan_from_text \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "data": {
      "text_content": "第一天 胸部训练\n卧推 4组8次 60公斤\n上斜哑铃卧推 3组12次 20公斤\n夹胸 3组15次\n\n第二天 背部训练\n引体向上 4组8次\n杠铃划船 4组10次 50公斤",
      "language": "中文"
    }
  }'
```

**期望结果**:
- 动作名称保持中文
- 正确解析组数和次数
- 正确解析重量（"公斤" → "kg"）

---

## 测试用例 3: 混合格式

**请求**:
```bash
curl -X POST http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/import_plan_from_text \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "data": {
      "text_content": "周一 - 腿部训练 (Leg Day)\n深蹲 Squat: 5x5 @ 80kg\n罗马尼亚硬拉 RDL 4x8 70kg\n保加利亚分腿蹲 3x10 each leg"
    }
  }'
```

**期望结果**:
- 支持中英混合动作名称
- 正确解析 "5x5" 和 "@80kg" 格式
- 正确处理 "each leg" 等描述

---

## 测试用例 4: 不规范输入

**请求**:
```bash
curl -X POST http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/import_plan_from_text \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{
    "data": {
      "text_content": "卧推\n深蹲 60kg\n硬拉 4组"
    }
  }'
```

**期望结果**:
- 自动补全缺失的组数次数（默认 3x10）
- 创建默认的 "Day 1"
- confidence 较低（< 0.8）
- warnings 包含提示信息

---

## 验证要点

### 1. 数据结构验证
```json
{
  "status": "success",
  "data": {
    "plan": {
      "name": "训练计划",
      "description": "",
      "days": [
        {
          "day": 1,
          "type": "...",
          "name": "...",
          "exercises": [
            {
              "name": "...",
              "type": "strength",
              "sets": [
                {
                  "reps": "8",
                  "weight": "60kg",
                  "completed": false
                }
              ]
            }
          ],
          "completed": false
        }
      ]
    },
    "confidence": 0.95,
    "warnings": []
  }
}
```

### 2. 字段类型检查
- ✅ reps: string
- ✅ weight: string
- ✅ completed: boolean
- ✅ day: integer
- ✅ type: string ("strength")

### 3. 边界情况
- 空文本 → 400 错误
- 无法解析 → confidence < 0.5, warnings 提示
- 缺少组数 → 默认 3x10
- 缺少重量 → weight 为空字符串 ""

---

## 错误处理测试

### 空内容
```bash
curl -X POST http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/import_plan_from_text \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -d '{"data": {"text_content": ""}}'
```

**期望**: HTTP 400, "text_content 不能为空"

### 未登录
```bash
curl -X POST http://127.0.0.1:5001/YOUR_PROJECT_ID/us-central1/import_plan_from_text \
  -H "Content-Type: application/json" \
  -d '{"data": {"text_content": "Day 1"}}'
```

**期望**: HTTP 401, "用户未登录"

---

## 日志验证

检查 Functions 日志应包含：
- ✅ `📝 文本导入请求 - 用户: xxx`
- ✅ `文本长度: xxx 字符`
- ✅ `🌐 语言设置: xxx`
- ✅ `🔍 开始解析文本内容`
- ✅ `✅ 文本解析成功`
- ✅ `✅ 文本导入处理完成 - 置信度: xx%`
- ✅ `解析到 x 个训练日`
