# 饮食计划创建架构

## 功能概述

饮食计划创建功能支持教练通过三种方式创建个性化饮食方案：AI 引导创建（3步骤表单）、文本导入（OCR/粘贴）、手动创建。核心特性包括流式 AI 生成进度展示、BMR/TDEE 自动计算、训练计划关联、多种创建方式无缝切换。采用多状态页面架构，支持创建和编辑模式。

## 用户流程

### AI 引导创建流程
```
选择"AI 引导创建"
  ↓
Step 1: 输入个人资料（体重/身高/年龄/性别）
  ↓
Step 2: 设定目标与活动（饮食目标/活动水平/引用训练计划）
  ↓
Step 3: 饮食偏好与限制（每日餐数/饮食偏好/过敏信息）
  ↓
AI 流式生成（4步骤进度展示）
  ↓
显示统计摘要（BMR/TDEE/目标热量）
  ↓
用户点击"查看详情并编辑"按钮
  ↓
进入编辑模式 → 保存
```

### 其他创建方式
- **文本导入**: 上传图片/粘贴文本 → AI 解析 → 确认导入 → 编辑 → 保存
- **手动创建**: 直接进入编辑模式 → 添加天数/餐次 → 保存

## 技术架构

### 技术栈
- **Frontend**: Flutter + Riverpod (状态管理)
- **Backend**: Firebase Cloud Functions (Python)
- **AI**: Claude API (流式生成)

### 组件结构

```
lib/features/coach/plans/
├── data/
│   ├── models/
│   │   ├── create_diet_plan_state.dart         # 状态模型
│   │   ├── diet_plan_import_stats.dart         # 统计数据模型
│   │   └── diet_import_result.dart             # 导入结果模型
│   └── repositories/
│       └── diet_plan_repository.dart           # 数据访问层
└── presentation/
    ├── pages/
    │   └── create_diet_plan_page.dart          # 主页面 (6种状态切换)
    ├── providers/
    │   └── create_diet_plan_notifier.dart      # 状态管理 (Riverpod)
    └── widgets/
        └── create_plan/
            ├── shared/                         # 共享组件
            │   ├── progress_bar.dart           # 流式进度条
            │   └── step_card.dart              # 步骤卡片
            ├── diet/                           # 饮食计划专用组件
            │   ├── diet_ai_guided_view.dart    # AI 引导视图 (3步骤表单)
            │   ├── diet_ai_streaming_view.dart # AI 流式生成视图
            │   ├── diet_summary_card.dart      # 统计摘要卡片
            │   └── diet_text_import_summary_view.dart
            └── training/                       # 训练计划组件 (已重构)
```

### 状态管理

**CreateDietPlanState** - 饮食计划创建状态
```dart
class CreateDietPlanState {
  final String? planId;                        // 计划ID (编辑模式)
  final String planName;                       // 计划名称
  final List<DietDay> days;                    // 饮食天数列表
  final bool isLoading;                        // 加载状态
  final bool isEditMode;                       // 编辑/创建模式

  // AI 流式生成相关
  final DietPlanImportStats? dietStreamingStats; // 统计数据 (BMR/TDEE/目标热量)
  final int currentStep;                       // 当前步骤 (1-4)
  final double currentStepProgress;            // 当前步骤进度 (0-100)
  final AIGenerationStatus aiStatus;           // 生成状态 (idle/generating/success/error)
}
```

**CreatePlanPageState** - 页面状态枚举
```dart
enum CreatePlanPageState {
  initial,              // 初始选择界面 (3种创建方式)
  aiGuided,             // AI 引导创建 (3步骤表单)
  aiStreaming,          // AI 流式生成进度
  textImport,           // 文本导入
  textImportSummary,    // 文本导入摘要确认
  editing,              // 编辑模式
}
```

## 数据模型

### DietPlanImportStats
```dart
class DietPlanImportStats {
  final int totalDays;         // 饮食天数
  final int totalMeals;        // 总餐次
  final double bmr;            // 基础代谢率 (kcal/day)
  final double tdee;           // 总能量消耗 (kcal/day)
  final double targetCalories; // 目标热量 (kcal/day)
}
```

### DietPlanGenerationParams
```dart
class DietPlanGenerationParams {
  final double weight;         // 体重 (kg)
  final double height;         // 身高 (cm)
  final int age;               // 年龄
  final String gender;         // 性别 ('male'/'female')
  final double? bodyFat;       // 体脂率 (可选)
  final String dietGoal;       // 饮食目标 ('muscleGain'/'fatLoss'/'maintenance')
  final String activityLevel;  // 活动水平 ('sedentary'/'light'/'moderate'/'active'/'veryActive')
  final int mealCount;         // 每日餐数 (2-6)
  final Set<String> dietaryPreferences; // 饮食偏好
  final String? dietaryRestrictions;    // 饮食限制和其他要求
  final String? referenceTrainingPlanId; // 引用训练计划ID
}
```

## 数据流

### AI 引导创建流程
```
用户填写表单 (DietAIGuidedView)
  ↓
点击"生成计划"按钮
  ↓
_handleGenerationStart() → 切换到 aiStreaming 状态
  ↓
构建 DietPlanGenerationParams
  ↓
CreateDietPlanNotifier.generateFromParamsStreaming()
  ↓
计算 BMR/TDEE/目标热量 (_calculateDietStats)
  ↓
调用 AI API (流式生成)
  ↓
实时更新进度 (_updateStep) → UI 展示 (DietAIStreamingView)
  ↓
生成完成 (step 4 成功) → 显示 DietSummaryCard + 确认按钮
  ↓
用户点击"查看详情并编辑"按钮
  ↓
_handleStreamingConfirm() → 切换到 editing 状态
  ↓
用户编辑 → 保存到 Firestore
```

### BMR/TDEE 计算公式
```
BMR (男性) = 10 × weight + 6.25 × height - 5 × age + 5
BMR (女性) = 10 × weight + 6.25 × height - 5 × age - 161

TDEE = BMR × 活动系数
- sedentary: 1.2
- light: 1.375
- moderate: 1.55
- active: 1.725
- veryActive: 1.9

目标热量 = TDEE ± 调整值 (根据饮食目标)
- muscleGain: TDEE + 300-500
- fatLoss: TDEE - 500
- maintenance: TDEE
```

## 核心组件说明

### 1. CreateDietPlanPage (主页面)
**职责**: 管理页面状态切换，协调所有子视图

**6种页面状态**:
1. `initial` - 展示 3 种创建方式选择卡片
2. `aiGuided` - AI 引导创建 3 步骤表单
3. `aiStreaming` - AI 流式生成进度展示（4步骤）
4. `textImport` - 文本导入界面（OCR + 粘贴）
5. `textImportSummary` - 导入摘要确认
6. `editing` - 编辑模式（餐次列表 + 保存按钮）

**关键方法**:
- `_switchToState()` - 页面状态切换
- `_handleGenerationStart()` - AI 生成开始时切换到 aiStreaming 状态
- `_handleStreamingConfirm()` - 用户点击确认按钮后切换到 editing 状态
- `_handleTextImportSuccess()` - 处理文本导入结果
- `_createManualPlan()` - 创建空白计划

### 2. DietAIGuidedView (AI 引导创建)
**职责**: 3步骤表单，收集用户参数

**Step 1 - Personal Profile**:
- 体重、身高、年龄、性别
- 体脂率（可选，折叠展示）

**Step 2 - Goals & Activity**:
- 饮食目标 (muscleGain/fatLoss/maintenance)
- 活动水平 (5 levels)
- 引用训练计划（展开式下拉菜单）

**Step 3 - Preferences & Restrictions**:
- 每日餐数 (Slider: 2-6)
- 饮食偏好（多选：素食/纯素/低碳水/高蛋白/生酮）
- 其他要求（多行文本输入：过敏信息和不喜欢的食物）

**关键特性**:
- PageView 实现步骤切换
- 实时验证表单完整性 (`_canProceed`)
- 训练计划选择器采用展开式下拉菜单（类似 ExerciseSearchBar）

### 3. DietAIStreamingView (流式生成进度)
**职责**: 展示 AI 生成进度，提供实时反馈，并在完成后等待用户确认

**4步骤进度**:
1. 分析饮食要求 (0-20%)
2. 生成饮食计划 (20-85%)
3. 计算营养数据 (85-95%)
4. 完成生成 (100%)

**UI 元素**:
- 总进度条 (StreamingProgressBar)
- 4个步骤卡片 (StepCard) - 显示完成/进行中/待处理状态
- 统计摘要卡片 (DietSummaryCard) - 生成完成后显示 BMR/TDEE/目标热量
- 底部确认按钮 - 仅在生成成功后显示，文案"查看详情并编辑"
- 错误处理 - 支持重试

**交互流程**:
- 生成中：显示进度条 + 步骤卡片
- 生成成功：显示统计摘要 + 确认按钮
- 生成失败：显示错误卡片 + 重试按钮
- 用户点击确认 → 调用 `onConfirm` 回调 → 切换到 editing 状态

### 4. DietSummaryCard (统计摘要卡片)
**职责**: 展示饮食计划统计数据

**2x2 + 1 布局**:
```
┌──────────────┬──────────────┐
│ 饮食天数: 7   │ 总餐次: 28    │
├──────────────┼──────────────┤
│ BMR: 1650    │ TDEE: 2200   │
├──────────────┴──────────────┤
│ 目标热量: 2000 (居中)       │
└─────────────────────────────┘
```

**特性**:
- 数字动画效果
- 卡片缩放 + 渐入动画
- 渐变背景
- 可选的内部按钮（`onViewPlan` 参数为 null 时不显示）

### 5. CreateDietPlanNotifier (状态管理)
**职责**: 管理饮食计划创建/编辑的所有业务逻辑

**关键方法**:
- `generateFromParamsStreaming()` - AI 流式生成（4步骤进度）
- `_calculateDietStats()` - 计算 BMR/TDEE/目标热量
- `importFromText()` - 文本导入（OCR + 粘贴）
- `_updateStep()` - 更新生成步骤进度
- `saveDietPlan()` - 保存到 Firestore
- `loadDietPlan()` - 加载现有计划（编辑模式）

## 国际化支持

**新增 i18n keys** (38 个):
- 创建方式: `createDietPlan`, `aiGuidedDietCreate`, `manualDietCreate`
- 表单字段: `weightKg`, `heightCm`, `age`, `dietGoal`, `activityLevel`
- AI 生成步骤: `dietStep1Title` ~ `dietStep4Title` + descriptions
- 统计数据: `statDietTotalDays`, `statBMR`, `statTDEE`, `statTargetCalories`
- 按钮文案: `viewDetailsAndEdit` - "查看详情并编辑"（确认按钮）

## 错误处理

| 错误类型 | 处理方式 |
|---------|---------|
| AI 生成失败 | 显示错误卡片，支持重试 |
| 网络错误 | 显示错误对话框，允许手动重试 |
| 表单验证失败 | 禁用"下一步/生成"按钮，高亮缺失字段 |
| 保存失败 | 显示错误提示，不退出编辑模式 |
| 训练计划加载失败 | 显示错误对话框，允许重新加载 |

## 关键决策

### 1. 为什么采用多状态页面架构？
- **原因**: 3种创建方式（AI/文本/手动）需要不同的 UI 流程
- **优势**: 状态切换清晰，代码解耦，易于维护和测试
- **实现**: 使用枚举 `CreatePlanPageState` + `switch case` 渲染不同视图

### 2. 为什么使用流式生成？
- **原因**: AI 生成饮食计划耗时较长（10-30秒）
- **优势**: 实时反馈提升用户体验，避免"假死"感
- **实现**: 4步骤进度展示 + StreamingProgressBar

### 3. 为什么训练计划选择器采用展开式下拉菜单？
- **原因**: 避免弹出式对话框打断用户流程
- **优势**: 交互更自然，符合表单填写习惯
- **实现**: 参考 ExerciseSearchBar 的展开/收起动画

### 4. 为什么需要 DietPlanImportStats？
- **原因**: 统一管理统计数据（BMR/TDEE/目标热量）
- **优势**: 数据模型清晰，便于在多个组件间传递
- **用途**: AI 生成摘要、文本导入摘要、编辑页面信息展示

### 5. 为什么 AI 生成完成后需要用户手动确认？
- **原因**: 用户需要先查看生成结果摘要（统计数据）再决定是否进入编辑
- **优势**:
  - 提供清晰的流程分隔，用户能明确知道生成已完成
  - 避免自动跳转打断用户查看摘要的注意力
  - 给用户一个"检查点"，可以在进入编辑前查看关键指标
- **实现**:
  - 生成完成后停留在 `aiStreaming` 状态
  - 显示 `DietSummaryCard` 和底部确认按钮
  - 用户点击按钮后才切换到 `editing` 状态
- **注意事项**:
  - 首次创建不保存初始快照（避免无限循环）
  - 编辑模式才保存快照（用于检测未保存修改）

## 相关文档

- [训练计划创建架构](../training_plan_creation_architecture.md)
- [后端 API 文档](../../backend_apis_and_document_db_schemas.md)
- [Riverpod 状态管理最佳实践](../../state_management_guide.md)

---

**最后更新**: 2025-12-02

**变更历史**:
- 2025-12-02: 新增手动确认流程，AI 生成完成后需用户点击确认按钮才进入编辑模式
