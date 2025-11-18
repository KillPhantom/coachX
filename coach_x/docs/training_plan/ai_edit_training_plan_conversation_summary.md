# AI 对话式编辑训练计划 - 实现总结

## 功能概述

支持教练通过自然语言对话编辑训练计划，AI 自动解析用户意图并生成结构化修改建议，教练逐个审查后应用修改。核心特性：
- Memory 系统记忆用户偏好
- SSE 流式实时响应
- Review Mode 逐个审查修改
- **ExerciseTemplate 自动关联** - AI 生成的动作自动匹配动作库或创建新模板

---

## 核心用户流程

```
教练打开现有计划
  ↓
点击 ✨ 按钮打开 AI 对话面板
  ↓
输入修改请求（自然语言）
  例如："把所有重量降低10%"
  ↓
AI 实时思考 → 生成修改建议
  ↓
自动进入 Review Mode
  ↓
逐个审查修改（接受/拒绝）
  ↓
应用最终计划
```

---

## 技术架构

### 前端
- **UI**: CupertinoModalPopup (70% 高度)
- **状态管理**:
  - `EditConversationNotifier` - 对话状态
  - `SuggestionReviewNotifier` - Review Mode 状态
- **关键组件**:
  - `AIEditChatPanel` - 对话面板
  - `ReviewModeOverlay` - 修改审查 UI

### 后端
- **API**: `/edit_plan_conversation` (SSE 流式)
- **AI**: Claude API + Tool Use (`edit_plan` tool)
- **Memory**: `MemoryManager` 加载用户偏好和对话历史
- **ExerciseTemplate 集成**:
  - 自动加载教练动作库
  - AI 返回动作名称 → 后端匹配或创建模板 → 注入 `exerciseTemplateId`

---

## 数据模型

### PlanEditSuggestion
```dart
class PlanEditSuggestion {
  final String analysis;                    // AI 分析
  final List<PlanChange> changes;           // 修改列表（必需）
  final String? summary;                    // 修改总结（可选）
}
```

### PlanChange
```dart
class PlanChange {
  final ChangeType type;           // 修改类型
  final String target;             // 目标标识
  final String description;        // 描述
  final String reason;             // 理由
  final dynamic before;            // 修改前（字符串或数组）
  final dynamic after;             // 修改后（字符串或数组）
  final int dayIndex;              // 训练日索引（0-based）
  final int? exerciseIndex;        // 动作索引（可选）
  final String id;                 // 唯一标识
}

enum ChangeType {
  modifyExercise,      // 修改动作
  addExercise,         // 添加动作
  removeExercise,      // 删除动作
  modifyExerciseSets,  // 修改训练组（exercise-level）
  addDay,              // 添加训练日
  removeDay,           // 删除训练日
  modifyDayName,       // 修改名称
  reorder,             // 调整顺序
  adjustIntensity,     // 调整强度
  other,               // 其他
}
```

---

## 数据流

### 编辑请求流程
```
1. 前端发送 POST /edit_plan_conversation
   Body: {user_id, plan_id, user_message, current_plan}
   ↓
2. 后端加载:
   - 用户 Memory (偏好、对话历史)
   - 教练动作库 (ExerciseTemplate)
   ↓
3. 构建 Prompt (含动作库列表) → 调用 Claude API
   ↓
4. AI 返回结构化修改建议 (analysis + changes)
   ↓
5. 后端处理:
   - 为每个 change 添加唯一 ID
   - 对 add_exercise/modify_exercise 类型:
     * 提取动作名称
     * 匹配动作库（精确/模糊匹配）
     * 若不匹配 → 快捷创建新模板
     * 注入 exerciseTemplateId 到 change.after
   ↓
6. SSE 流式返回事件:
   - thinking: AI 思考过程
   - analysis: 分析结果
   - suggestion: 修改建议（含 exerciseTemplateId）
   - complete: 完成
```

### Review Mode 流程
```
前端检测到 pendingSuggestion
  ↓
自动启动 Review Mode
  ↓
显示第一个修改（1/N）
  - 自动滚动到目标 Card
  - 显示 before/after 对比
  ↓
用户选择: 接受 | 拒绝 | 全部接受 | 退出
  ↓
应用修改到 workingPlan（前端增量应用）
  ↓
完成后应用最终计划
```

---

## ExerciseTemplate 集成 (2025-11-17 更新)

### 核心改进
1. **移除 note 字段**: Exercise 模型不再包含 `note`，从 ExerciseTemplate 读取指导内容
2. **强制模板关联**: 所有动作必须有 `exerciseTemplateId`
3. **自动匹配/创建**: AI 编辑时后端自动处理模板关联

### 后端处理逻辑
```python
# functions/ai/streaming.py:stream_edit_plan_conversation

# 1. 加载动作库
coach_id = _get_coach_id_from_plan(plan_id)
exercise_templates = _fetch_coach_exercise_templates(coach_id)

# 2. 传递给 AI (Prompt 中包含动作库列表)
system_prompt, user_prompt = build_edit_conversation_prompt(
    ...,
    exercise_templates=exercise_templates
)

# 3. AI 返回后注入 ID
for change in changes:
    if change['type'] in ['add_exercise', 'modify_exercise']:
        exercise_name = _extract_exercise_name_from_change(change)

        # 匹配或创建
        template_id = _match_or_create_template(
            coach_id,
            exercise_name,
            exercise_templates
        )

        # 注入到 after 字段
        _inject_exercise_template_id(change, template_id)
```

### AI Tool Schema 更新
```python
# functions/ai/tools.py

# ❌ 移除字段
"note": {"type": "string"}  # 已从所有 exercise 相关 schema 中删除

# ✅ 保留字段
- name: 动作名称
- sets: 训练组列表
- exerciseTemplateId: 由后端自动注入（AI 无需生成）
```

### 前端验证
```dart
// lib/.../suggestion_review_notifier.dart:_parseCompleteExercise

final exercise = Exercise(..., exerciseTemplateId: data['exerciseTemplateId']);

// 开发阶段验证（不阻塞）
if (exercise.exerciseTemplateId == null) {
  AppLogger.warning('⚠️ 动作缺少exerciseTemplateId（后端应已处理）');
}
```

---

## 关键组件

### 后端
| 文件 | 职责 |
|------|------|
| `functions/ai/streaming.py` | SSE 流式处理，ExerciseTemplate 匹配/创建 |
| `functions/ai/tools.py` | Tool schema 定义 (已移除 note 字段) |
| `functions/ai/training_plan/prompts.py` | Prompt 构建，动作库格式化 |

### 前端
| 文件 | 职责 |
|------|------|
| `lib/.../edit_conversation_notifier.dart` | 对话状态管理，处理 SSE 事件 |
| `lib/.../suggestion_review_notifier.dart` | Review Mode 状态，应用修改逻辑 |
| `lib/.../ai_edit_chat_panel.dart` | 对话 UI |
| `lib/.../review_mode_overlay.dart` | Review Mode UI（516 行，exercise-level before/after 对比） |

---

## 错误处理

| 错误类型 | 处理方式 |
|---------|---------|
| 加载动作库失败 | 警告日志，继续执行（AI 仍可生成动作，但无 ID） |
| 匹配模板失败 | 快捷创建新模板（默认空标签） |
| 注入 ID 失败 | 错误日志，该 change 缺失 exerciseTemplateId（前端警告） |
| AI 返回空 changes | 警告，不创建 suggestion |
| 缺失必需字段 | 验证日志，标记错误但不阻塞 |

---

## 性能优化

- **Token 节省**: 后端不返回完整 `modifiedPlan`，仅返回 `changes`，前端增量应用
- **Exercise-Level 粒度**: 一个动作的所有组作为一个 change，而非逐组修改（节省 75% Token）
- **动作库缓存**: Firestore 查询仅在编辑开始时执行一次

---

## 相关文档

- `exercise_plan_create_summary.md` - ExerciseTemplate 集成总览
- `exercise_library_implementation.md` - 动作库实现
- `backend_apis_and_document_db_schemas.md` - API 定义

---

**最后更新**: 2025-11-17
**状态**: ✅ 已集成 ExerciseTemplate，所有动作强制关联模板
