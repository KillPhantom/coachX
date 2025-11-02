# AI引导创建饮食计划 - 实现总结

**实现日期**: 2025-10-31
**功能**: AI引导创建饮食计划（使用Claude Skill）
**状态**: ✅ 完成

---

## 📋 功能概述

实现了使用Claude Skill (nutrition-calculator v2.0)自动生成完整7天饮食计划的功能。用户通过一步表单输入基本信息和目标，AI自动生成包含每日餐次和具体食物的详细饮食计划。

### 核心特性

- ✅ **一步表单引导创建**：简化的用户输入流程
- ✅ **Claude Skill集成**：使用nutrition-calculator v2.0 skill
- ✅ **训练计划引用**：可引用现有训练计划并启用碳循环
- ✅ **完整饮食计划生成**：7天×4-5餐×具体食物和营养数据
- ✅ **饮食偏好支持**：素食、纯素、碳循环、生酮等
- ✅ **过敏管理**：自动排除过敏原食物

---

## 🏗️ 架构设计

### 技术栈

**后端:**
- Python Cloud Functions (Firebase 2nd gen)
- Claude API with Extended Thinking (Skill调用)
- nutrition-calculator.skill v2.0

**前端:**
- Flutter + Cupertino UI
- Riverpod 2.x (状态管理)
- 新增Enums：ActivityLevel, DietGoal, DietaryPreference, Allergen

---

## 📂 文件清单

### 后端文件（3个）

#### 1. `functions/ai/claude_skills/skill_caller.py` ✨ **新建**

**功能**: Claude Skill调用辅助函数

**核心方法**:
- `call_nutrition_calculator_skill(params)` - 调用nutrition-calculator skill
- `_load_skill_file()` - 从.skill文件加载内容
- `_build_user_request(params)` - 构建用户请求文本

**实现细节**:
- 读取nutrition-calculator.skill文件（ZIP格式）
- 使用Extended Thinking模式调用Claude API
- 返回完整的饮食计划JSON

#### 2. `functions/ai/handlers.py` ✏️ **修改**

**新增函数**: `generate_diet_plan_with_skill(req)`

**请求参数**:
```python
{
  "weight_kg": float,        # 必需
  "height_cm": float,        # 必需
  "age": int,                # 必需
  "gender": str,             # 必需
  "activity_level": str,     # 必需
  "goal": str,               # 必需
  "body_fat_percentage": float,      # 可选
  "training_plan_id": str,           # 可选，引用现有训练计划
  "dietary_preferences": list,       # 可选
  "meal_count": int,                 # 可选，默认4
  "allergies": list,                 # 可选
  "plan_duration_days": int          # 可选，默认7
}
```

**返回格式**:
```python
{
  "status": "success",
  "data": {
    "bmr_kcal": float,
    "tdee_kcal": float,
    "target_calories_kcal": float,
    "diet_plan": {
      "name": str,
      "description": str,
      "days": [...]  # DietDay格式
    }
  }
}
```

**关键功能**:
- 训练计划引用：通过`training_plan_id`获取现有训练计划
- 自动转换训练计划格式为skill所需格式
- 启用碳循环：引用训练计划时自动添加`carb_cycling`偏好

#### 3. `functions/main.py` ✏️ **修改**

**修改内容**:
- 导入`generate_diet_plan_with_skill`
- 导出到`__all__`列表

---

### 前端文件（11个）

#### 数据层（4个）

**4. `lib/core/enums/activity_level.dart` ✨ 新建**

活动水平枚举：
- sedentary（久坐）
- lightlyActive（轻度活跃）
- moderatelyActive（中度活跃）
- veryActive（非常活跃）
- extremelyActive（极度活跃）

**5. `lib/core/enums/diet_goal.dart` ✨ 新建**

饮食目标枚举：
- muscleGain（增肌）
- fatLoss（减脂）
- maintenance（维持）

**6. `lib/core/enums/dietary_preference.dart` ✨ 新建**

饮食偏好枚举：
- vegetarian（素食）
- vegan（纯素）
- carbCycling（碳循环）
- intermittentFasting（间歇性断食）
- keto（生酮）
- highCarb（高碳水）

过敏原枚举：
- dairy（乳制品）
- nuts（坚果）
- gluten（麸质）

**7. `lib/features/coach/plans/data/models/diet_plan_generation_params.dart` ✨ 新建**

饮食计划生成参数模型：
- 包含所有必需和可选参数
- `toJson()` 方法用于API调用

---

#### UI层（2个）

**8. `lib/features/coach/plans/presentation/widgets/guided_diet_creation_sheet.dart` ✨ 新建**

AI引导创建饮食计划Sheet（全屏）

**布局结构**:
```
┌─────────────────────────────┐
│ AI 引导创建饮食计划    [取消]│ NavigationBar
├─────────────────────────────┤
│ 基本信息                     │
│ • 体重、身高、年龄、性别      │
│                              │
│ 目标设置                     │
│ • 饮食目标                   │
│ • 活动水平                   │
│                              │
│ > 高级选项（可折叠）         │
│   • 体脂率                   │
│   • 每日餐数                 │
│   • 饮食偏好                 │
│   • 过敏信息                 │
│   • 引用训练计划（TODO）     │
├─────────────────────────────┤
│ [     生成饮食计划     ]     │
└─────────────────────────────┘
```

**核心组件**:
- `_buildBasicInfoForm()` - 基本信息表单
- `_buildGoalSelection()` - 目标选择（Wrap布局）
- `_buildAdvancedOptions()` - 高级选项（可折叠）
- `_buildMultiSelector()` - 多选组件（用于偏好和过敏）

**9. `lib/features/coach/plans/presentation/pages/create_diet_plan_page.dart` ✏️ 修改**

**修改内容**:
- NavigationBar添加`trailing`: Sparkle icon
- 仅在非编辑模式显示（`!state.isEditMode`）
- 点击触发`_showGuidedCreationSheet()`
- 导入`guided_diet_creation_sheet.dart`

**代码片段**:
```dart
trailing: !state.isEditMode
    ? CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showGuidedCreationSheet(context, notifier),
        child: const Icon(
          CupertinoIcons.sparkles,
          color: CupertinoColors.activeBlue,
        ),
      )
    : null,
```

---

#### 状态管理层（2个）

**10. `lib/core/services/ai_service.dart` ✏️ 修改**

**新增方法**: `generateDietPlanWithSkill(params)`

**签名**:
```dart
static Future<Map<String, dynamic>> generateDietPlanWithSkill({
  required Map<String, dynamic> params,
})
```

**返回数据**:
```dart
{
  'name': String,          // 计划名称
  'description': String,   // 计划描述
  'days': List<dynamic>,   // DietDay JSON列表
}
```

**11. `lib/features/coach/plans/presentation/providers/create_diet_plan_notifier.dart` ✏️ 修改**

**新增方法**: `generateFromSkill(DietPlanGenerationParams params)`

**功能**:
1. 调用`AIService.generateDietPlanWithSkill()`
2. 解析返回的JSON
3. 转换`days`为`List<DietDay>`
4. 更新state（planName, description, days）
5. 错误处理和loading状态管理

**新增导入**:
```dart
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_generation_params.dart';
```

---

## 🔑 核心实现细节

### 1. Skill文件加载

nutrition-calculator.skill是一个ZIP文件，内部结构：
```
nutrition-calculator.skill (ZIP)
├── nutrition-calculator/
│   ├── SKILL.md              # Skill定义和说明
│   ├── references/           # 参考文档
│   └── scripts/              # Python脚本
```

`skill_caller.py`通过`zipfile`模块读取`SKILL.md`内容。

### 2. 训练计划引用与碳循环

当用户提供`training_plan_id`时：
1. 后端从Firestore读取训练计划
2. 调用`_convert_training_plan_to_skill_format()`转换为skill格式
3. 自动添加`carb_cycling`到`dietary_preferences`
4. Skill根据训练日/休息日动态调整碳水和脂肪摄入

**转换逻辑**（简化版）:
```python
{
  "days_per_week": int,
  "schedule": [
    {"day": 1, "type": "strength", "focus": "full_body", "intensity": "moderate"},
    {"day": 2, "type": "rest"},
    ...
  ]
}
```

### 3. Extended Thinking模式

调用Claude API时使用Extended Thinking模式：
```python
system_prompt = f"""你是一个营养计算专家助手。

你有一个专业的营养计算skill可以使用。

{skill_content}

请严格按照用户提供的参数调用这个skill，并返回完整的饮食计划。"""
```

### 4. UI表单验证

表单验证逻辑：
```dart
bool get _canGenerate {
  return _weightController.text.isNotEmpty &&
      _heightController.text.isNotEmpty &&
      _ageController.text.isNotEmpty;
}
```

### 5. 数据流

```
用户填写表单
    ↓
构建 DietPlanGenerationParams
    ↓
params.toJson() → API调用
    ↓
后端: generate_diet_plan_with_skill
    ↓
后端: call_nutrition_calculator_skill
    ↓
Claude API (Extended Thinking + Skill)
    ↓
返回: {name, description, days}
    ↓
前端: AIService.generateDietPlanWithSkill
    ↓
前端: CreateDietPlanNotifier.generateFromSkill
    ↓
解析并转换 List<DietDay>
    ↓
更新 State → UI刷新
```

### 优先级1

- [ ] **训练计划选择器**：在高级选项中添加训练计划选择下拉框
- [ ] **营养目标预览**：生成前预览计算的BMR/TDEE/目标热量
- [ ] **生成进度指示**：显示AI生成进度（thinking状态）

### 优先级2

- [ ] **历史参数保存**：记住用户上次输入的参数
- [ ] **模板功能**：保存常用参数组合为模板
- [ ] **批量生成**：为多个学生批量生成计划

---

## 📊 代码统计

- **新建文件**: 8个
- **修改文件**: 4个
- **新增代码行数**: ~1,500行
- **后端函数**: 1个（generate_diet_plan_with_skill）
- **前端Enum**: 4个
- **前端Widget**: 1个

---

## 🐛 已知问题

1. **训练计划引用UI未完成**：高级选项中暂未添加训练计划选择器（标注TODO）
2. **Skill文件路径硬编码**：路径写死在`skill_caller.py`中
3. **错误提示不够友好**：API错误直接显示原始错误信息

---

## 📝 相关文档

- 原始饮食计划实现: `docs/create_diet_plan_implementation.md`
- Skill使用说明: `functions/ai/claude_skills/diet_plan_calculation/使用说明_v2.0.md`
- 训练计划AI生成: `docs/ai_create_plan_streaming_summary.md`

---

**最后更新**: 2025-10-31
**实现者**: Claude Code
**文档版本**: 1.0
