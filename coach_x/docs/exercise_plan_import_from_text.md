# 文本导入训练计划 - 架构文档

> 最后更新：2025-11-30
> 版本：1.0.0

## 📋 概述

文本导入功能允许教练通过粘贴或输入包含训练计划的文本，快速创建结构化的训练计划。系统会自动解析文本，识别训练日、动作、组数等信息，并与动作库进行智能匹配。

### 核心特性

- ✅ **智能文本解析**：自动识别训练日、动作名称、组数、重量等信息
- ✅ **动作库匹配**：自动匹配已有动作模板，减少重复创建
- ✅ **动作名称编辑**：支持在导入后修改动作名称
- ✅ **指导内容创建**：支持为新动作创建完整的指导内容（视频、图片、文字）
- ✅ **批量模板创建**：自动为未匹配的动作批量创建模板
- ✅ **无缝集成**：与现有训练计划编辑流程完全集成

---

## 🏗️ 整体架构

### 数据流图

```
用户输入文本
    ↓
[TextImportView] - 文本输入界面
    ↓
调用 Cloud Function: import_plan_from_text
    ↓
返回 ImportResult (包含 ExercisePlanModel)
    ↓
[CreateTrainingPlanNotifier.loadFromImportResult()]
    ├── 加载计划数据到 state
    ├── 计算动作统计 (_calculateExerciseStats)
    └── 生成 PlanImportStats
    ↓
导航到 [TextImportSummaryView] - 总结页面
    ├── 显示两个 section：
    │   ├── Exercise From Library（已匹配的动作）
    │   └── New Exercise（新动作）
    ├── 支持编辑动作名称
    ├── 支持为新动作创建指导
    └── 点击 Confirm
        ↓
[_handleConfirm()]
    ├── 应用名称修改
    ├── 批量创建剩余模板
    ├── 注入 exerciseTemplateId
    └── 进入 CreatePlanPageState.editing
    ↓
[TrainingDayEditor] - 标准编辑界面
```

### 页面状态机

```dart
enum CreatePlanPageState {
  selection,           // 选择创建方式
  textImport,          // 文本导入输入
  textImportSummary,   // 文本导入总结 ⭐ NEW
  aiGuided,            // AI 引导创建
  aiStreaming,         // AI 流式生成
  editing,             // 编辑计划
}
```

---

## 📊 数据模型

### 1. PlanImportStats

**文件**: `lib/features/coach/plans/data/models/plan_import_stats.dart`

**用途**: 存储计划导入后的统计信息（适用于 AI 生成和文本导入）

```dart
class PlanImportStats {
  /// 总训练天数
  final int totalDays;

  /// 总动作数（去重后）
  final int totalExercises;

  /// 复用的动作数（从动作库中匹配）
  final int reusedExercises;

  /// 新建的动作数（需要创建模板）
  final int newExercises;

  /// 复用的动作名称列表 ⭐ NEW
  final List<String> reusedExerciseNames;

  /// 需要新建的动作名称列表
  final List<String> newExerciseNames;

  /// 总组数
  final int totalSets;
}
```

**重要变更**：
- 从 `AIStreamingStats` 重命名为 `PlanImportStats`（更通用）
- 新增 `reusedExerciseNames` 字段，用于 UI 显示

### 2. CreateTrainingPlanState

**文件**: `lib/features/coach/plans/data/models/create_training_plan_state.dart`

**新增字段**：

```dart
/// 手动创建的动作模板映射（动作名称 -> 模板 ID）
/// 用于记录通过 "create guidance" 创建的模板
final Map<String, String> manuallyCreatedTemplates;
```

**用途**:
- 记录用户通过 "create guidance" 手动创建的模板 ID
- 在批量创建时排除这些已创建的动作
- 在注入 templateId 时合并所有来源的 ID

### 3. ImportResult

**文件**: `lib/features/coach/plans/data/models/import_result.dart`

```dart
class ImportResult {
  final bool isSuccess;
  final ExercisePlanModel? plan;
  final String? error;
}
```

**用途**: 封装 Cloud Function 返回的结果

---

## 🎨 核心组件

### 1. TextImportView

**文件**: `lib/features/coach/plans/presentation/widgets/create_plan/text_import_view.dart`

**职责**:
- 提供文本输入界面
- 调用后端 API 解析文本
- 处理解析结果并导航

**关键方法**:
```dart
Future<void> _handleImportFromText(String text) async {
  // 调用 Cloud Function
  final result = await AIService.importPlanFromText(text: text);

  // 加载到 state
  notifier.loadFromImportResult(result);

  // 导航到总结页面
  ref.read(createPlanPageStateProvider.notifier).state =
      CreatePlanPageState.textImportSummary;
}
```

### 2. TextImportSummaryView ⭐ 核心组件

**文件**: `lib/features/coach/plans/presentation/widgets/create_plan/text_import_summary_view.dart`

**职责**:
- 显示导入统计和动作分类
- 支持编辑动作名称
- 支持创建动作指导
- 协调批量创建和 templateId 注入

**UI 结构**:

```dart
CupertinoPageScaffold
├── Header（标题和副标题）
├── ScrollView
│   ├── Exercise From Library Section
│   │   └── List of ExerciseCard（只读，显示 "view guidance"）
│   └── New Exercise Section
│       └── List of ExerciseCard（可编辑，显示 "create guidance"）
└── Confirm Button（底部固定）
```

**状态管理**:
```dart
class _TextImportSummaryViewState {
  /// 动作名称编辑控制器 (originalName -> controller)
  final Map<String, TextEditingController> _nameControllers = {};
}
```

**关键方法**:

#### 查看已有动作指导
```dart
void _handleViewGuidance(String exerciseName) {
  final templates = ref.read(exerciseTemplatesProvider);
  final template = templates.firstWhereOrNull(
    (t) => t.name.trim().toLowerCase() == exerciseName.trim().toLowerCase(),
  );
  if (template != null) {
    ExerciseGuidanceSheet.show(context, template.id);
  }
}
```

#### 创建新动作指导
```dart
Future<void> _handleCreateGuidance(String originalName) async {
  // 1. 获取当前名称（可能被编辑过）
  final currentName = _nameControllers[originalName]?.text ?? originalName;

  // 2. 创建临时模板（预填充名称）
  final tempTemplate = ExerciseTemplateModel(
    id: '',
    ownerId: '',
    name: currentName,
    tags: const [],
    createdAt: now,
    updatedAt: now,
  );

  // 3. 显示创建 Sheet
  await CreateExerciseSheet.show(context, template: tempTemplate);

  // 4. 刷新动作库
  await ref.read(exerciseLibraryNotifierProvider.notifier).loadData();

  // 5. 查找新创建的模板
  final newTemplate = templates.firstWhereOrNull(...);

  // 6. 记录到 notifier
  if (newTemplate != null) {
    notifier.recordManuallyCreatedTemplate(currentName, newTemplate.id);
  }
}
```

#### 确认并进入编辑 ⭐ 最复杂的流程
```dart
Future<void> _handleConfirm() async {
  final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

  // 步骤1: 收集名称修改
  final nameChanges = <String, String>{};
  _nameControllers.forEach((oldName, controller) {
    if (controller.text != oldName) {
      nameChanges[oldName] = controller.text;
    }
  });

  // 步骤2: 应用名称修改到计划和统计
  if (nameChanges.isNotEmpty) {
    notifier.applyExerciseNameChanges(nameChanges);
  }

  // 步骤3: 收集需要批量创建的新动作（重新读取 state！）
  var currentState = ref.read(createTrainingPlanNotifierProvider);
  final allNewNames = currentState.aiStreamingStats!.newExerciseNames;
  final manuallyCreated = currentState.manuallyCreatedTemplates.keys.toSet();
  final needBatchCreate = allNewNames
      .where((name) => !manuallyCreated.contains(name))
      .toList();

  // 步骤4: 批量创建剩余模板
  Map<String, String> batchCreatedIds = {};
  if (needBatchCreate.isNotEmpty) {
    batchCreatedIds = await notifier.createExerciseTemplatesBatch(
      needBatchCreate,
    );
  }

  // 步骤5: 刷新动作库缓存
  await ref.read(exerciseLibraryNotifierProvider.notifier).loadData();

  // 步骤6: 合并所有 templateId（再次重新读取 state！）
  currentState = ref.read(createTrainingPlanNotifierProvider);
  final allTemplateIds = {
    ...currentState.manuallyCreatedTemplates,  // 手动创建的
    ...batchCreatedIds,                         // 批量创建的
  };

  // 步骤7: 注入 templateId 到计划
  notifier.injectTemplateIdsIntoPlan(allTemplateIds);

  // 步骤8: 进入 editing 状态
  notifier.updatePageState(CreatePlanPageState.editing);
}
```

**⚠️ 关键注意点**:
- 在每次 notifier 更新 state 后，必须重新读取 state
- 否则会使用旧数据，导致 templateId 注入失败

### 3. CreateExerciseSheet

**文件**: `lib/features/coach/exercise_library/presentation/widgets/create_exercise_sheet.dart`

**改进**:
```dart
// 之前：只检查 template 是否为 null
bool get _isEditMode => widget.template != null;

// 现在：检查 template 是否存在且 ID 不为空 ✅
bool get _isEditMode =>
    widget.template != null && widget.template!.id.isNotEmpty;
```

**用途**:
- 创建/编辑动作模板
- 支持预填充初始值（通过 template 参数）
- 自动判断创建或编辑模式

---

## 🔄 Notifier 方法

### CreateTrainingPlanNotifier

**文件**: `lib/features/coach/plans/presentation/providers/create_training_plan_notifier.dart`

#### 1. loadFromImportResult()

```dart
void loadFromImportResult(ImportResult result) {
  // 1. 验证结果
  if (!result.isSuccess || result.plan == null) return;

  // 2. 加载计划数据
  state = state.copyWith(
    planName: plan.name,
    description: plan.description,
    days: plan.days,
    errorMessage: '',
  );

  // 3. 计算动作统计
  final stats = _calculateExerciseStats();
  state = state.copyWith(aiStreamingStats: stats);
}
```

**⚠️ 注意**: 不在此阶段验证 exerciseTemplateId，因为文本导入时动作还没有 templateId

#### 2. _calculateExerciseStats() ⭐ 核心统计逻辑

```dart
PlanImportStats _calculateExerciseStats() {
  final exerciseTemplates = _ref.read(exerciseTemplatesProvider);
  final reusedExercises = <String>[];  // 复用的动作名称
  final newExercises = <String>[];     // 新动作名称

  // 遍历所有动作
  for (final day in state.days) {
    for (final exercise in day.exercises) {
      // 检查是否在动作库中（不区分大小写）
      final isInLibrary = exerciseTemplates.any((template) =>
          template.name.trim().toLowerCase() ==
          exercise.name.trim().toLowerCase());

      if (isInLibrary) {
        if (!reusedExercises.contains(exercise.name)) {
          reusedExercises.add(exercise.name);
        }
      } else {
        if (!newExercises.contains(exercise.name)) {
          newExercises.add(exercise.name);
        }
      }
    }
  }

  return PlanImportStats(
    totalDays: state.days.length,
    totalExercises: allExercises.toSet().length,
    reusedExercises: reusedExercises.length,
    newExercises: newExercises.length,
    reusedExerciseNames: reusedExercises,  // ⭐ NEW
    newExerciseNames: newExercises,
    totalSets: totalSets,
  );
}
```

#### 3. recordManuallyCreatedTemplate() ⭐ NEW

```dart
void recordManuallyCreatedTemplate(String exerciseName, String templateId) {
  final updated = {...state.manuallyCreatedTemplates, exerciseName: templateId};
  state = state.copyWith(manuallyCreatedTemplates: updated);
  AppLogger.info('📝 记录手动创建的模板: $exerciseName → $templateId');
}
```

**用途**: 记录通过 "create guidance" 创建的模板

#### 4. applyExerciseNameChanges() ⭐ NEW

```dart
void applyExerciseNameChanges(Map<String, String> nameChanges) {
  // 1. 更新计划中的动作名称
  final updatedDays = state.days.map((day) {
    final updatedExercises = day.exercises.map((exercise) {
      final newName = nameChanges[exercise.name];
      return newName != null
        ? exercise.copyWith(name: newName)
        : exercise;
    }).toList();
    return day.copyWith(exercises: updatedExercises);
  }).toList();

  state = state.copyWith(days: updatedDays);

  // 2. 同时更新统计数据中的名称
  if (state.aiStreamingStats != null) {
    final stats = state.aiStreamingStats!;
    final updatedNewNames = stats.newExerciseNames.map((name) {
      return nameChanges[name] ?? name;
    }).toList();

    final updatedStats = stats.copyWith(newExerciseNames: updatedNewNames);
    state = state.copyWith(aiStreamingStats: updatedStats);
  }
}
```

**用途**: 应用用户在总结页面编辑的动作名称

#### 5. injectTemplateIdsIntoPlan()

```dart
void injectTemplateIdsIntoPlan(Map<String, String> templateIdMap) {
  final updatedDays = state.days.map((day) {
    final updatedExercises = day.exercises.map((exercise) {
      final templateId = templateIdMap[exercise.name];
      if (templateId != null) {
        return exercise.copyWith(exerciseTemplateId: templateId);
      }
      return exercise;
    }).toList();
    return day.copyWith(exercises: updatedExercises);
  }).toList();

  state = state.copyWith(days: updatedDays);
}
```

**用途**: 将所有 templateId 注入到计划的每个动作中

---

## 🌐 国际化

### 新增翻译 Keys

**文件**: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`

| Key | English | 中文 |
|-----|---------|------|
| `textImportSummaryTitle` | Text Import Complete | 文本解析完成 |
| `textImportSummarySubtitle` | Successfully extracted training plan from text | 成功从文本中提取训练计划 |
| `exerciseFromLibrary` | Exercise From Library | 动作库中的动作 |
| `newExercise` | New Exercise | 新动作 |
| `viewGuidance` | view guidance | 查看指导 |
| `createGuidance` | create guidance | 创建指导 |
| `confirm` | Confirm | 确认 |

---

## 📁 相关文件清单

### 数据模型
- `lib/features/coach/plans/data/models/plan_import_stats.dart` - 统计模型（重命名）
- `lib/features/coach/plans/data/models/create_training_plan_state.dart` - 页面状态（新增字段）
- `lib/features/coach/plans/data/models/create_plan_page_state.dart` - 页面状态枚举（新增 textImportSummary）
- `lib/features/coach/plans/data/models/import_result.dart` - 导入结果
- `lib/features/coach/plans/data/models/exercise_plan_model.dart` - 训练计划模型

### UI 组件
- `lib/features/coach/plans/presentation/widgets/create_plan/text_import_view.dart` - 文本输入界面
- `lib/features/coach/plans/presentation/widgets/create_plan/text_import_summary_view.dart` - **总结页面（核心）**
- `lib/features/coach/plans/presentation/widgets/create_plan/summary_card.dart` - 统计卡片（类型更新）
- `lib/features/coach/exercise_library/presentation/widgets/create_exercise_sheet.dart` - 创建动作 Sheet（改进判断逻辑）
- `lib/features/student/training/presentation/widgets/exercise_guidance_sheet.dart` - 查看指导 Sheet

### State Management
- `lib/features/coach/plans/presentation/providers/create_training_plan_notifier.dart` - **核心业务逻辑**
- `lib/features/coach/plans/presentation/providers/create_training_plan_providers.dart` - Providers 定义
- `lib/features/coach/exercise_library/presentation/providers/exercise_library_providers.dart` - 动作库 Providers

### 国际化
- `lib/l10n/app_en.arb` - 英文翻译
- `lib/l10n/app_zh.arb` - 中文翻译

---

## 🔍 关键技术决策

### 1. 为什么重命名 AIStreamingStats 为 PlanImportStats？

**原因**:
- AI 生成和文本导入的统计需求完全一致
- 避免代码重复
- 提供更通用的语义

**影响**:
- 所有引用该类型的地方都需要更新
- 文件名也需要更新

### 2. 为什么需要 manuallyCreatedTemplates？

**问题**: 如何区分哪些动作已通过 "create guidance" 创建？

**解决方案**: 在 state 中维护一个 Map
- Key: 动作名称（修改后的）
- Value: 模板 ID

**用途**:
- 批量创建时排除已创建的动作
- 注入 templateId 时合并所有来源

### 3. 为什么需要在 _handleConfirm 中多次重新读取 state？

**问题**: Notifier 更新 state 是同步的，但 ref.read() 可能获取旧值

**解决方案**: 每次 notifier 更新后立即重新读取
```dart
notifier.applyExerciseNameChanges(nameChanges);
var currentState = ref.read(...);  // ✅ 重新读取
```

**教训**: 不要在方法开始时读取一次 state 就一直使用

### 4. 为什么 CreateExerciseSheet 需要改进判断逻辑？

**问题**: 只检查 `template != null` 无法区分真正的编辑模式

**场景**: 预填充名称时传递了一个 ID 为空的 template

**解决方案**:
```dart
bool get _isEditMode =>
    widget.template != null && widget.template!.id.isNotEmpty;
```

---

## 🐛 常见问题和解决方案

### 问题1: 验证错误 "动作必须关联动作模板"

**症状**: 加载计划时报错，页面显示无限加载

**原因**: 文本导入时动作还没有 templateId（正常现象）

**解决方案**: 移除 `loadFromImportResult()` 中的验证逻辑
```dart
// ❌ 删除这段代码
final errors = PlanValidator.getValidationErrors(plan);
if (errors.isNotEmpty) {
  return;  // 导致页面卡住
}

// ✅ 添加注释说明
// 注意：不在此阶段验证 exerciseTemplateId
// templateId 会在用户确认后批量创建并注入
```

### 问题2: 点击 Confirm 后页面为空

**症状**: 进入编辑页面，只显示训练日 pill，没有动作

**原因**: 使用了旧的 state，导致 templateId 注入失败

**解决方案**: 在每次更新后重新读取 state
```dart
// ❌ 错误
final state = ref.read(...);
notifier.applyExerciseNameChanges(nameChanges);
final stats = state.aiStreamingStats;  // 旧数据！

// ✅ 正确
notifier.applyExerciseNameChanges(nameChanges);
var currentState = ref.read(...);  // 重新读取
final stats = currentState.aiStreamingStats;
```

### 问题3: 保存模板时报错 "document path 不能为空"

**症状**: 点击 "create guidance" 后保存失败

**原因**: CreateExerciseSheet 误判为编辑模式

**解决方案**: 改进 `_isEditMode` 判断逻辑，检查 ID 是否为空

---

## 🚀 未来改进方向

### 1. 优化用户体验
- [ ] 添加加载进度提示（批量创建时）
- [ ] 支持拖拽排序动作
- [ ] 支持批量编辑动作属性

### 2. 增强功能
- [ ] 支持导入历史记录
- [ ] 支持模板复用建议
- [ ] 支持自动纠错（拼写错误）

### 3. 性能优化
- [ ] 缓存动作匹配结果
- [ ] 批量创建优化（并发控制）
- [ ] 懒加载动作库

---

## 📚 参考资源

### 相关文档
- `docs/backend_apis_and_document_db_schemas.md` - 后端 API 和数据库结构
- `docs/training_plan/exercise_plan_create_summary.md` - 训练计划创建总览
- `CLAUDE.md` - 项目开发规范

### 云函数
- `functions/ai/text_import/handlers.py` - 文本解析逻辑

### 测试场景
1. 基础文本导入
2. 包含新动作的文本
3. 编辑动作名称
4. 创建动作指导
5. 批量创建模板

---

## ✅ 实施检查清单

- [x] 重命名 AIStreamingStats 为 PlanImportStats
- [x] 添加 reusedExerciseNames 字段
- [x] 扩展 CreateTrainingPlanState
- [x] 实现 recordManuallyCreatedTemplate()
- [x] 实现 applyExerciseNameChanges()
- [x] 重构 TextImportSummaryView
- [x] 改进 CreateExerciseSheet 判断逻辑
- [x] 添加国际化支持
- [x] 修复验证逻辑问题
- [x] 修复 state 重新读取问题
- [x] 修复模板保存问题
- [x] 完成测试验证

---

**最后更新**: 2025-11-30
**维护者**: Claude Code
**版本**: 1.0.0
