# AI 流式生成 Overview Page - 执行计划

**创建时间**: 2025-11-17
**预计耗时**: 9-13 小时
**优先级**: High
**状态**: 📋 待执行

---

## 📌 执行前准备

### 环境检查
- [ ] Flutter SDK 版本 >= 3.16.0
- [ ] Dart SDK 版本 >= 3.2.0
- [ ] Firebase Emulator 已安装
- [ ] Python 环境已配置 (Python 3.10+)
- [ ] 所有依赖已安装 (`flutter pub get`, `pip install -r requirements.txt`)

### 代码备份
- [ ] 创建新分支: `git checkout -b feature/ai_streaming_overview`
- [ ] 确认当前代码可正常运行

### 相关文档
- [ ] 阅读 `docs/training_plan/exercise_plan_create_summary.md`
- [ ] 参考 UI 设计: `/Users/ivan/Downloads/training_plan_generator.html`

---

## 🔧 阶段 1: 前端数据模型与状态 (1-2h)

### ✅ 任务 1.1: 添加 `aiStreaming` 状态

**文件**: `lib/features/coach/plans/data/models/create_plan_page_state.dart`

**修改**:
```dart
enum CreatePlanPageState {
  initial,
  aiGuided,
  textImport,
  aiStreaming,  // ✅ 新增
  editing,
}
```

**验证**: 编译通过，无类型错误

---

### ✅ 任务 1.2: 创建 AI 流式统计模型

**文件**: `lib/features/coach/plans/data/models/ai_streaming_stats.dart` (新建)

```dart
/// AI 流式生成统计数据
class AIStreamingStats {
  /// 总训练天数
  final int totalDays;

  /// 总动作数
  final int totalExercises;

  /// 复用的动作数（从动作库中匹配）
  final int reusedExercises;

  /// 新建的动作数（需要创建模板）
  final int newExercises;

  /// 需要新建的动作名称列表
  final List<String> newExerciseNames;

  /// 总组数
  final int totalSets;

  const AIStreamingStats({
    this.totalDays = 0,
    this.totalExercises = 0,
    this.reusedExercises = 0,
    this.newExercises = 0,
    this.newExerciseNames = const [],
    this.totalSets = 0,
  });

  AIStreamingStats copyWith({
    int? totalDays,
    int? totalExercises,
    int? reusedExercises,
    int? newExercises,
    List<String>? newExerciseNames,
    int? totalSets,
  }) {
    return AIStreamingStats(
      totalDays: totalDays ?? this.totalDays,
      totalExercises: totalExercises ?? this.totalExercises,
      reusedExercises: reusedExercises ?? this.reusedExercises,
      newExercises: newExercises ?? this.newExercises,
      newExerciseNames: newExerciseNames ?? this.newExerciseNames,
      totalSets: totalSets ?? this.totalSets,
    );
  }

  @override
  String toString() => 'AIStreamingStats('
      'days: $totalDays, '
      'exercises: $totalExercises, '
      'reused: $reusedExercises, '
      'new: $newExercises)';
}
```

**验证**: 编译通过

---

### ✅ 任务 1.3: 扩展 `CreateTrainingPlanState`

**文件**: `lib/features/coach/plans/data/models/create_training_plan_state.dart`

**新增字段**:
```dart
class CreateTrainingPlanState {
  // ... 现有字段 ...

  /// AI 流式生成统计
  final AIStreamingStats? aiStreamingStats;

  /// 当前执行步骤 (1-4)
  final int currentStep;

  /// 当前步骤进度 (0-100)
  final double currentStepProgress;

  const CreateTrainingPlanState({
    // ... 现有参数 ...
    this.aiStreamingStats,
    this.currentStep = 0,
    this.currentStepProgress = 0.0,
  });

  CreateTrainingPlanState copyWith({
    // ... 现有参数 ...
    AIStreamingStats? aiStreamingStats,
    int? currentStep,
    double? currentStepProgress,
  }) {
    return CreateTrainingPlanState(
      // ... 现有字段 ...
      aiStreamingStats: aiStreamingStats ?? this.aiStreamingStats,
      currentStep: currentStep ?? this.currentStep,
      currentStepProgress: currentStepProgress ?? this.currentStepProgress,
    );
  }
}
```

**验证**: 编译通过，copyWith 方法正常工作

---

## 🎨 阶段 2: 前端 UI 组件 (3-4h)

### ✅ 任务 2.1: 创建 Step Card 组件

**文件**: `lib/features/coach/plans/presentation/widgets/create_plan/step_card.dart` (新建)

```dart
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

enum StepStatus { pending, loading, completed }

class StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final StepStatus status;
  final String? detailText;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.status,
    this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 15),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    Color backgroundColor;
    Widget iconChild;

    switch (status) {
      case StepStatus.pending:
        backgroundColor = CupertinoColors.systemGrey5;
        iconChild = Text(
          '$stepNumber',
          style: AppTextStyles.bodyMedium.copyWith(
            color: CupertinoColors.systemGrey,
          ),
        );
        break;
      case StepStatus.loading:
        backgroundColor = AppColors.primaryAction;
        iconChild = const CupertinoActivityIndicator(
          color: CupertinoColors.white,
          radius: 10,
        );
        break;
      case StepStatus.completed:
        backgroundColor = CupertinoColors.systemGreen;
        iconChild = const Icon(
          CupertinoIcons.check_mark,
          color: CupertinoColors.white,
          size: 20,
        );
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: iconChild),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTextStyles.subhead.copyWith(
            color: CupertinoColors.systemGrey,
          ),
        ),
        if (detailText != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detailText!,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.primaryAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
```

**验证**:
- [ ] 三种状态（pending, loading, completed）显示正常
- [ ] detailText 可选显示
- [ ] 动画流畅

---

### ✅ 任务 2.2: 创建 Summary Card 组件

**文件**: `lib/features/coach/plans/presentation/widgets/create_plan/summary_card.dart` (新建)

```dart
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/ai_streaming_stats.dart';

class SummaryCard extends StatefulWidget {
  final AIStreamingStats stats;
  final VoidCallback onViewPlan;

  const SummaryCard({
    super.key,
    required this.stats,
    required this.onViewPlan,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryAction,
                AppColors.primaryAction.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 20),
              _buildStats(l10n),
              const SizedBox(height: 20),
              _buildButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Text('✅', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Text(
          l10n.summaryTitle,
          style: AppTextStyles.title2.copyWith(
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            widget.stats.totalDays.toString(),
            l10n.statTotalDays,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatItem(
            widget.stats.totalExercises.toString(),
            l10n.statTotalExercises,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _AnimatedNumber(
            number: int.tryParse(number) ?? 0,
            style: AppTextStyles.largeTitle.copyWith(
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.footnote.copyWith(
              color: CupertinoColors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(AppLocalizations l10n) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(14),
      onPressed: widget.onViewPlan,
      child: Text(
        l10n.viewFullPlan,
        style: AppTextStyles.buttonLarge.copyWith(
          color: AppColors.primaryAction,
        ),
      ),
    );
  }
}

class _AnimatedNumber extends StatefulWidget {
  final int number;
  final TextStyle style;

  const _AnimatedNumber({
    required this.number,
    required this.style,
  });

  @override
  State<_AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<_AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = IntTween(begin: 0, end: widget.number).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}
```

**验证**:
- [ ] 进入动画流畅（scale + fade）
- [ ] 数字计数动画正常
- [ ] 按钮点击响应

---

### ✅ 任务 2.3: 创建 AI Streaming View 主页面

**文件**: `lib/features/coach/plans/presentation/widgets/create_plan/ai_streaming_view.dart` (新建)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';
import 'step_card.dart';
import 'summary_card.dart';

class AIStreamingView extends ConsumerWidget {
  const AIStreamingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createTrainingPlanNotifierProvider);
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 35),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProgressBar(state.currentStepProgress),
                      const SizedBox(height: 25),
                      _buildSteps(l10n, state, notifier),
                      if (state.currentStep == 4 &&
                          state.aiStreamingStats != null) ...[
                        const SizedBox(height: 30),
                        SummaryCard(
                          stats: state.aiStreamingStats!,
                          onViewPlan: () => _handleViewPlan(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          '🏋️ ${l10n.aiStreamingTitle}',
          style: AppTextStyles.title1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aiStreamingSubtitle,
          style: AppTextStyles.subhead.copyWith(
            color: CupertinoColors.systemGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress / 100,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryAction,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSteps(
    AppLocalizations l10n,
    state,
    notifier,
  ) {
    return Column(
      children: [
        _buildStepCard(
          l10n,
          stepNumber: 1,
          title: l10n.step1Title,
          description: l10n.step1Description,
          currentStep: state.currentStep,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 2,
          title: l10n.step2Title,
          description: l10n.step2Description,
          currentStep: state.currentStep,
          detailText: state.currentStep == 2 ? _getCurrentDayDetail(state) : null,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 3,
          title: l10n.step3Title,
          description: l10n.step3Description,
          currentStep: state.currentStep,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 4,
          title: l10n.step4Title,
          description: l10n.step4Description,
          currentStep: state.currentStep,
        ),
      ],
    );
  }

  Widget _buildStepCard(
    AppLocalizations l10n, {
    required int stepNumber,
    required String title,
    required String description,
    required int currentStep,
    String? detailText,
  }) {
    StepStatus status;
    if (currentStep > stepNumber) {
      status = StepStatus.completed;
    } else if (currentStep == stepNumber) {
      status = StepStatus.loading;
    } else {
      status = StepStatus.pending;
    }

    return AnimatedOpacity(
      opacity: currentStep >= stepNumber ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: currentStep >= stepNumber ? Offset.zero : const Offset(0, 0.1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: StepCard(
          stepNumber: stepNumber,
          title: title,
          description: description,
          status: status,
          detailText: detailText,
        ),
      ),
    );
  }

  String? _getCurrentDayDetail(state) {
    if (state.currentDayInProgress != null) {
      final day = state.currentDayInProgress!;
      final exerciseNames = day.exercises.map((e) => e.name).take(3).join('、');
      return '正在生成第 ${day.day} 天：$exerciseNames...';
    }
    return null;
  }

  void _handleViewPlan(BuildContext context, WidgetRef ref) {
    // TODO: Show confirmation dialog
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
    // notifier.showCreateTemplatesConfirmation();
  }
}
```

**验证**:
- [ ] 4 个步骤卡片显示正常
- [ ] 进度条动画流畅
- [ ] Step 2 实时显示详情
- [ ] Summary Card 在完成后显示

---

### ✅ 任务 2.4: 创建确认对话框

**文件**: `lib/features/coach/plans/presentation/widgets/create_plan/create_templates_confirmation_dialog.dart` (新建)

```dart
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';

class CreateTemplatesConfirmationDialog extends StatelessWidget {
  final int newExerciseCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CreateTemplatesConfirmationDialog({
    super.key,
    required this.newExerciseCount,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int newExerciseCount,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CreateTemplatesConfirmationDialog(
        newExerciseCount: newExerciseCount,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: Text(
        l10n.confirmCreateTemplatesTitle,
        style: AppTextStyles.title3,
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          l10n.confirmCreateTemplates(newExerciseCount),
          style: AppTextStyles.body,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel,
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: onConfirm,
          child: Text(l10n.confirmCreateButton),
        ),
      ],
    );
  }
}
```

**验证**:
- [ ] 对话框显示正常
- [ ] 文案正确（包含动作数量）
- [ ] 按钮响应正常

---

## 🧠 阶段 3: 前端 State Management (2-3h)

### ✅ 任务 3.1: 扩展 `CreateTrainingPlanNotifier` - 步骤管理

**文件**: `lib/features/coach/plans/presentation/providers/create_training_plan_notifier.dart`

在类中添加以下方法：

```dart
/// 更新流式生成步骤
void _updateStreamingStep(int step, double progress) {
  state = state.copyWith(
    currentStep: step,
    currentStepProgress: progress,
  );
  AppLogger.debug('📊 Streaming Step: $step, Progress: $progress%');
}

/// 重置流式统计
void _resetStreamingStats() {
  state = state.copyWith(
    aiStreamingStats: const AIStreamingStats(),
    currentStep: 0,
    currentStepProgress: 0.0,
  );
}
```

---

### ✅ 任务 3.2: 添加动作统计计算逻辑

在 `create_training_plan_notifier.dart` 中添加:

```dart
/// 计算动作统计
///
/// 对比生成的动作和动作库，统计复用和新建的数量
AIStreamingStats _calculateExerciseStats() {
  final exerciseTemplates = _ref.read(exerciseTemplatesProvider);
  final allExercises = <String>[];
  final reusedExercises = <String>[];
  final newExercises = <String>[];
  int totalSets = 0;

  // 收集所有动作名称
  for (final day in state.days) {
    for (final exercise in day.exercises) {
      allExercises.add(exercise.name);
      totalSets += exercise.sets.length;

      // 检查是否在动作库中（模糊匹配）
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

  final stats = AIStreamingStats(
    totalDays: state.days.length,
    totalExercises: allExercises.toSet().length,
    reusedExercises: reusedExercises.length,
    newExercises: newExercises.length,
    newExerciseNames: newExercises,
    totalSets: totalSets,
  );

  AppLogger.info('📊 Exercise Stats: $stats');
  return stats;
}
```

**验证**:
- [ ] 统计数据正确
- [ ] 模糊匹配生效（忽略大小写和空格）

---

### ✅ 任务 3.3: 修改流式生成方法

修改 `generateFromParamsStreaming` 方法，添加步骤更新：

```dart
Future<void> generateFromParamsStreaming(PlanGenerationParams params) async {
  try {
    AppLogger.info('🔄 开始流式生成训练计划');

    // Step 1: 分析训练要求 (20%)
    _updateStreamingStep(1, 20);

    // 获取教练的动作库列表
    final exerciseTemplates = _ref.read(exerciseTemplatesProvider);

    if (exerciseTemplates.isNotEmpty) {
      params = params.copyWith(exerciseTemplates: exerciseTemplates);
      AppLogger.info('📚 已添加 ${exerciseTemplates.length} 个动作模板到生成参数');
    } else {
      AppLogger.info('⚠️ 未找到动作库，AI 将自由选择动作名称');
    }

    // 清空现有数据
    state = state.copyWith(
      days: [],
      aiStatus: AIGenerationStatus.generating,
      errorMessage: '',
      currentDayInProgress: null,
      currentDayNumber: null,
    );

    // 延迟 500ms 让用户看到 Step 1
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 2: 生成训练计划 (20% → 85%)
    _updateStreamingStep(2, 20);

    final totalDays = params.daysPerWeek;
    int completedDays = 0;

    // 监听流式事件
    await for (final event in AIService.generatePlanStreaming(params: params)) {
      if (event.isThinking) {
        // 思考过程
        if (event.content != null) {
          AppLogger.debug('💭 思考: ${event.content}');
        }
      } else if (event.isDayStart) {
        // 开始生成新的一天
        AppLogger.info('📅 开始生成第 ${event.day} 天');
        state = state.copyWith(
          currentDayInProgress: ExerciseTrainingDay.empty(event.day!),
          currentDayNumber: event.day,
        );
      } else if (event.isExerciseComplete) {
        // 动作完成 - 追加到当前训练日
        if (state.currentDayInProgress != null && event.exerciseData != null) {
          final updatedDay = state.currentDayInProgress!.addExercise(
            event.exerciseData!,
          );
          state = state.copyWith(currentDayInProgress: updatedDay);
          AppLogger.info(
            '✅ 第 ${event.day} 天第 ${event.exerciseIndex} 个动作已添加: ${event.exerciseData!.name}',
          );
        }
      } else if (event.isDayComplete) {
        // 一天完成
        if (state.currentDayInProgress != null) {
          final updatedDays = [...state.days, state.currentDayInProgress!];
          state = state.copyWith(
            days: updatedDays,
            currentDayInProgress: null,
            currentDayNumber: null,
          );
          completedDays++;

          // 更新 Step 2 进度 (20% → 85%)
          final progress = 20 + (65 * completedDays / totalDays);
          _updateStreamingStep(2, progress);

          AppLogger.info('🎉 第 ${event.day} 天已完成');
        }
      } else if (event.isComplete) {
        // Step 3: 匹配动作库 (85% → 95%)
        _updateStreamingStep(3, 85);
        await Future.delayed(const Duration(milliseconds: 500));

        // 计算统计
        final stats = _calculateExerciseStats();
        state = state.copyWith(aiStreamingStats: stats);

        _updateStreamingStep(3, 95);
        await Future.delayed(const Duration(milliseconds: 500));

        // Step 4: 完成 (100%)
        _updateStreamingStep(4, 100);

        state = state.copyWith(
          aiStatus: AIGenerationStatus.success,
          currentDayInProgress: null,
          currentDayNumber: null,
        );
        AppLogger.info('🎉 流式生成完成 - 共 ${state.days.length} 天');
        break;
      } else if (event.isError) {
        // 错误
        state = state.copyWith(
          aiStatus: AIGenerationStatus.error,
          errorMessage: event.error ?? '生成失败',
          currentDayInProgress: null,
          currentDayNumber: null,
        );
        AppLogger.error('❌ 流式生成失败: ${event.error}');
        break;
      }
    }
  } catch (e, stackTrace) {
    AppLogger.error('❌ 流式生成异常', e, stackTrace);
    state = state.copyWith(
      aiStatus: AIGenerationStatus.error,
      errorMessage: '生成失败: $e',
      currentDayInProgress: null,
      currentDayNumber: null,
    );
  }
}
```

**验证**:
- [ ] 4 个步骤按顺序执行
- [ ] 进度条平滑过渡
- [ ] 统计数据在 Step 3 计算
- [ ] Step 4 显示 Summary Card

---

### ✅ 任务 3.4: 添加批量创建模板方法

```dart
/// 批量创建动作模板
///
/// [exerciseNames] 需要创建的动作名称列表
///
/// 返回 Map<exerciseName, templateId>
Future<Map<String, String>> createExerciseTemplatesBatch(
  List<String> exerciseNames,
) async {
  try {
    AppLogger.info('🔧 开始批量创建 ${exerciseNames.length} 个动作模板');

    state = state.copyWith(loadingStatus: LoadingStatus.loading);

    final repository = _ref.read(exerciseLibraryRepositoryProvider);
    final templateIdMap = await repository.batchCreateTemplates(exerciseNames);

    state = state.copyWith(loadingStatus: LoadingStatus.success);

    AppLogger.info('✅ 批量创建完成: $templateIdMap');
    return templateIdMap;
  } catch (e) {
    AppLogger.error('❌ 批量创建模板失败', e);
    state = state.copyWith(
      loadingStatus: LoadingStatus.error,
      errorMessage: '创建动作模板失败: $e',
    );
    rethrow;
  }
}
```

---

### ✅ 任务 3.5: 添加注入 templateId 方法

```dart
/// 注入 exerciseTemplateId 到计划中
///
/// [templateIdMap] 动作名称 → 模板ID 的映射
void _injectTemplateIdsIntoPlan(Map<String, String> templateIdMap) {
  AppLogger.info('💉 开始注入 exerciseTemplateId');

  final updatedDays = state.days.map((day) {
    final updatedExercises = day.exercises.map((exercise) {
      final templateId = templateIdMap[exercise.name];
      if (templateId != null) {
        AppLogger.debug('  ${exercise.name} → $templateId');
        return exercise.copyWith(exerciseTemplateId: templateId);
      }
      return exercise;
    }).toList();

    return day.copyWith(exercises: updatedExercises);
  }).toList();

  state = state.copyWith(days: updatedDays);
  AppLogger.info('✅ 注入完成');
}
```

---

## 📦 阶段 4: 前端参数传递修复 (30min)

### ✅ 任务 4.1: 修改 `PlanGenerationParams.toJson()`

**文件**: `lib/features/coach/plans/data/models/plan_generation_params.dart:152-157`

**修改**:
```dart
// 动作库列表（传递完整数据：id + name + tags）
if (exerciseTemplates != null && exerciseTemplates!.isNotEmpty)
  'exercise_templates': exerciseTemplates!.map((template) => {
    'id': template.id,        // ✅ 新增
    'name': template.name,
    'tags': template.tags,
  }).toList(),
```

**验证**:
- [ ] toJson 包含 id 字段
- [ ] 后端能正确接收 id

---

## 🔙 阶段 5: 后端 Tool Schema 修复 (30min)

### ✅ 任务 5.1: 修改 `get_single_day_tool`

**文件**: `functions/ai/tools.py:46-75`

在 exercise properties 中添加:

```python
"exerciseTemplateId": {
    "type": "string",
    "description": "动作模板ID。如果提供了动作库，必须从库中选择动作并使用对应的模板ID。"
}
```

完整的 exercise properties:
```python
"exercises": {
    "type": "array",
    "description": "该训练日的所有动作列表",
    "items": {
        "type": "object",
        "properties": {
            "name": {
                "type": "string",
                "description": "动作名称。..."
            },
            "exerciseTemplateId": {  # ✅ 新增
                "type": "string",
                "description": "动作模板ID。如果提供了动作库，必须从库中选择动作并使用对应的模板ID。"
            },
            "sets": {
                "type": "array",
                # ...
            }
        },
        "required": ["name", "sets"]  # exerciseTemplateId 是可选的
    }
}
```

**验证**:
- [ ] Tool schema 验证通过
- [ ] Claude 能在返回数据中包含 exerciseTemplateId

---

## 📝 阶段 6: 后端 Prompt 优化 (1h)

### ✅ 任务 6.1: 修改 `_format_exercise_library`

**文件**: `functions/ai/training_plan/prompts.py:591-621`

**修改**:
```python
def _format_exercise_library(exercise_templates: list) -> tuple:
    """格式化动作库列表"""
    if not exercise_templates or len(exercise_templates) == 0:
        return ("", "- 可以自由选择适合的动作")

    # 格式化动作库列表
    exercise_lines = []
    for template in exercise_templates:
        name = template.get('name', '未知动作')
        template_id = template.get('id', '')  # ✅ 新增
        tags = template.get('tags', [])
        tags_text = f"（{', '.join(tags)}）" if tags else ""
        # ✅ 包含 ID
        exercise_lines.append(f"   - {name} [ID: {template_id}]{tags_text}")

    exercise_list_text = '\n'.join(exercise_lines)

    library_section = f"""
**可用动作库（共 {len(exercise_templates)} 个动作）：**
{exercise_list_text}
"""

    # ✅ 更新选择规则
    selection_rule = "- **重要：必须从上述动作库中选择动作，并在返回数据的 exerciseTemplateId 字段中填入对应的 ID**"

    return (library_section, selection_rule)
```

**验证**:
- [ ] Prompt 包含 template ID
- [ ] selection_rule 明确说明需要填写 exerciseTemplateId

---

## 🚀 阶段 7: 后端批量创建 API (2h)

### ✅ 任务 7.1: 创建批量创建处理器

**文件**: `functions/exercise_library/batch_handlers.py` (新建)

```python
"""
批量创建动作模板的处理器
"""

from firebase_admin import firestore
from firebase_functions import https_fn
from typing import Dict, Any, List
from utils.logger import logger


@https_fn.on_call()
def create_exercise_templates_batch(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    批量创建动作模板

    Args:
        req.data: {
            "coach_id": str,
            "exercise_names": List[str]
        }

    Returns:
        {
            "status": "success",
            "data": {
                "template_id_map": {
                    "深蹲": "template_id_1",
                    "卧推": "template_id_2"
                }
            }
        }
    """
    try:
        # 验证输入
        coach_id = req.data.get('coach_id')
        exercise_names = req.data.get('exercise_names', [])

        if not coach_id:
            raise ValueError('Missing coach_id')

        if not exercise_names or not isinstance(exercise_names, list):
            raise ValueError('Invalid exercise_names')

        logger.info(f'🔧 开始批量创建 {len(exercise_names)} 个模板 - Coach: {coach_id}')

        # 初始化 Firestore
        db = firestore.client()
        template_id_map = {}

        # 批量创建模板
        batch = db.batch()

        for exercise_name in exercise_names:
            # 创建新模板文档
            template_ref = db.collection('exerciseTemplates').document()

            template_data = {
                'name': exercise_name,
                'tags': [],  # 默认空标签
                'coachId': coach_id,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            }

            batch.set(template_ref, template_data)
            template_id_map[exercise_name] = template_ref.id

            logger.info(f'  ✅ 准备创建: {exercise_name} -> {template_ref.id}')

        # 提交批量操作
        batch.commit()
        logger.info(f'✅ 批量创建完成: {len(template_id_map)} 个模板')

        return {
            'status': 'success',
            'data': {
                'template_id_map': template_id_map
            }
        }

    except Exception as e:
        logger.error(f'❌ 批量创建模板失败: {str(e)}', exc_info=True)
        return {
            'status': 'error',
            'error': str(e)
        }
```

**验证**:
- [ ] API 能正常创建模板
- [ ] 返回的 template_id_map 正确
- [ ] Firestore 中能看到创建的模板

---

### ✅ 任务 7.2: 注册 Cloud Function

**文件**: `functions/main.py`

添加导入和 export:

```python
# ... 现有 imports ...

from exercise_library.batch_handlers import create_exercise_templates_batch

# ... 现有 exports ...

# Exercise Library - Batch Operations
exports['create_exercise_templates_batch'] = create_exercise_templates_batch
```

**验证**:
- [ ] `firebase deploy --only functions` 成功
- [ ] 函数出现在 Firebase Console

---

## 🔌 阶段 8: 前端 API 集成 (1h)

### ✅ 任务 8.1: 添加 Cloud Functions 服务方法

**文件**: `lib/core/services/cloud_functions_service.dart`

添加方法:

```dart
/// 批量创建动作模板
///
/// [exerciseNames] 动作名称列表
///
/// 返回 Map<exerciseName, templateId>
static Future<Map<String, String>> createExerciseTemplatesBatch(
  List<String> exerciseNames,
) async {
  try {
    AppLogger.info('🔧 调用批量创建模板 API: ${exerciseNames.length} 个');

    final response = await call(
      'create_exercise_templates_batch',
      data: {
        'coach_id': AuthService.currentUserId,
        'exercise_names': exerciseNames,
      },
    );

    if (response['status'] == 'success') {
      final data = response['data'] as Map<String, dynamic>;
      final templateIdMap = Map<String, String>.from(
        data['template_id_map'] as Map,
      );

      AppLogger.info('✅ 批量创建成功: ${templateIdMap.length} 个模板');
      return templateIdMap;
    } else {
      throw Exception(response['error'] ?? 'Unknown error');
    }
  } catch (e) {
    AppLogger.error('❌ 批量创建模板 API 调用失败', e);
    rethrow;
  }
}
```

**验证**:
- [ ] API 调用成功
- [ ] 返回数据格式正确

---

### ✅ 任务 8.2: 添加 Repository 接口方法

**文件**: `lib/features/coach/exercise_library/data/repositories/exercise_library_repository.dart`

添加接口:

```dart
/// 批量创建动作模板
///
/// [exerciseNames] 动作名称列表
///
/// 返回 Map<exerciseName, templateId>
Future<Map<String, String>> batchCreateTemplates(List<String> exerciseNames);
```

---

### ✅ 任务 8.3: 实现 Repository 方法

**文件**: `lib/features/coach/exercise_library/data/repositories/exercise_library_repository_impl.dart`

实现方法:

```dart
@override
Future<Map<String, String>> batchCreateTemplates(
  List<String> exerciseNames,
) async {
  try {
    AppLogger.info('📦 Repository: 批量创建 ${exerciseNames.length} 个模板');

    final templateIdMap = await CloudFunctionsService.createExerciseTemplatesBatch(
      exerciseNames,
    );

    AppLogger.info('✅ Repository: 批量创建完成');
    return templateIdMap;
  } catch (e) {
    AppLogger.error('❌ Repository: 批量创建失败', e);
    rethrow;
  }
}
```

**验证**:
- [ ] Repository 方法调用成功

---

## 🌐 阶段 9: 国际化 (30min)

### ✅ 任务 9.1: 添加 i18n keys

**文件**: `lib/l10n/app_en.arb`

添加以下 keys:

```json
{
  "aiStreamingTitle": "AI Training Plan Generator",
  "aiStreamingSubtitle": "Creating your personalized training plan",
  "step1Title": "Analyzing Requirements",
  "step1Description": "Validating your training goals and parameters...",
  "step2Title": "Generating Training Plan",
  "step2Description": "AI is designing your workout routine...",
  "step3Title": "Matching Exercise Library",
  "step3Description": "Checking reusable exercises...",
  "step4Title": "Finalizing",
  "step4Description": "Final review and validation...",
  "summaryTitle": "Generation Complete!",
  "statTotalDays": "Training Days",
  "statTotalExercises": "Total Exercises",
  "statReusedExercises": "Reused",
  "statNewExercises": "New",
  "viewFullPlan": "View Full Plan",
  "confirmCreateTemplatesTitle": "Create Exercise Templates",
  "confirmCreateTemplates": "Will create {count} new exercise templates to your library",
  "@confirmCreateTemplates": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "confirmCreateButton": "Confirm Create",
  "creatingTemplates": "Creating templates...",
  "cancel": "Cancel"
}
```

**文件**: `lib/l10n/app_zh.arb`

```json
{
  "aiStreamingTitle": "AI 训练计划生成器",
  "aiStreamingSubtitle": "正在为您定制专属训练方案",
  "step1Title": "分析训练要求",
  "step1Description": "正在验证您的训练目标和参数...",
  "step2Title": "生成训练计划",
  "step2Description": "AI 正在为您设计训练动作...",
  "step3Title": "匹配动作库",
  "step3Description": "正在检查可复用的动作...",
  "step4Title": "完成生成",
  "step4Description": "最后检查和验证...",
  "summaryTitle": "生成完成！",
  "statTotalDays": "训练天数",
  "statTotalExercises": "训练动作",
  "statReusedExercises": "复用",
  "statNewExercises": "新建",
  "viewFullPlan": "查看完整计划",
  "confirmCreateTemplatesTitle": "创建动作模板",
  "confirmCreateTemplates": "将创建 {count} 个新动作模板到您的动作库",
  "@confirmCreateTemplates": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "confirmCreateButton": "确认创建",
  "creatingTemplates": "正在创建模板...",
  "cancel": "取消"
}
```

---

### ✅ 任务 9.2: 生成国际化代码

**命令**:
```bash
flutter gen-l10n
```

**验证**:
- [ ] `lib/l10n/app_localizations.dart` 已更新
- [ ] 所有新 keys 可用
- [ ] 参数化字符串正常工作

---

## 🔗 阶段 10: 页面路由与集成 (1h)

### ✅ 任务 10.1: 修改 `CreateTrainingPlanPage` 状态切换

**文件**: `lib/features/coach/plans/presentation/pages/create_training_plan_page.dart`

在 `build` 方法中添加 `aiStreaming` 状态的处理:

```dart
@override
Widget build(BuildContext context) {
  final state = ref.watch(createTrainingPlanNotifierProvider);

  return CupertinoPageScaffold(
    child: SafeArea(
      child: _buildBody(state.pageState),
    ),
  );
}

Widget _buildBody(CreatePlanPageState pageState) {
  switch (pageState) {
    case CreatePlanPageState.initial:
      return InitialView(onSelectMethod: _handleMethodSelection);

    case CreatePlanPageState.aiGuided:
      return AIGuidedView(onGenerate: _handleGenerateFromAI);

    case CreatePlanPageState.textImport:
      return TextImportView(onImport: _handleImportFromText);

    case CreatePlanPageState.aiStreaming:  // ✅ 新增
      return const AIStreamingView();

    case CreatePlanPageState.editing:
      return EditingView(onSave: _handleSave);
  }
}

void _handleGenerateFromAI(PlanGenerationParams params) {
  final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

  // 切换到 aiStreaming 状态
  notifier.updatePageState(CreatePlanPageState.aiStreaming);

  // 开始流式生成
  notifier.generateFromParamsStreaming(params);
}
```

**验证**:
- [ ] 从 aiGuided 正确进入 aiStreaming
- [ ] 页面过渡流畅

---

### ✅ 任务 10.2: 添加 "查看完整计划" 逻辑

在 `AIStreamingView` 的 `_handleViewPlan` 方法中:

```dart
void _handleViewPlan(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
  final state = ref.read(createTrainingPlanNotifierProvider);

  final newExerciseCount = state.aiStreamingStats?.newExercises ?? 0;

  if (newExerciseCount > 0) {
    // 显示确认对话框
    final confirmed = await CreateTemplatesConfirmationDialog.show(
      context,
      newExerciseCount: newExerciseCount,
    );

    if (confirmed == true) {
      try {
        // 批量创建模板
        final newExerciseNames = state.aiStreamingStats!.newExerciseNames;
        final templateIdMap = await notifier.createExerciseTemplatesBatch(
          newExerciseNames,
        );

        // 注入 templateId
        notifier._injectTemplateIdsIntoPlan(templateIdMap);

        // 进入 editing 状态
        notifier.updatePageState(CreatePlanPageState.editing);
      } catch (e) {
        // 显示错误
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('创建失败'),
            content: Text('无法创建动作模板: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  } else {
    // 没有新动作，直接进入 editing
    notifier.updatePageState(CreatePlanPageState.editing);
  }
}
```

**验证**:
- [ ] 有新动作时显示确认对话框
- [ ] 创建成功后进入 editing 状态
- [ ] 所有 exercise 都有 exerciseTemplateId

---

## 🧪 阶段 11: 测试与验证 (2h)

### ✅ 任务 11.1: 单元测试 - 统计计算

**文件**: `test/features/coach/plans/ai_streaming_stats_test.dart` (新建)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coach_x/features/coach/plans/data/models/ai_streaming_stats.dart';

void main() {
  group('AIStreamingStats', () {
    test('should create stats with correct values', () {
      const stats = AIStreamingStats(
        totalDays: 3,
        totalExercises: 18,
        reusedExercises: 12,
        newExercises: 6,
        newExerciseNames: ['深蹲', '卧推'],
        totalSets: 54,
      );

      expect(stats.totalDays, 3);
      expect(stats.totalExercises, 18);
      expect(stats.reusedExercises, 12);
      expect(stats.newExercises, 6);
      expect(stats.newExerciseNames.length, 2);
      expect(stats.totalSets, 54);
    });

    test('should copyWith correctly', () {
      const stats = AIStreamingStats(totalDays: 3);
      final updated = stats.copyWith(totalDays: 5);

      expect(updated.totalDays, 5);
    });
  });
}
```

**运行**: `flutter test test/features/coach/plans/ai_streaming_stats_test.dart`

---

### ✅ 任务 11.2: 后端 API 测试

使用 Firebase Emulator 测试:

```bash
# 1. 启动 emulator
firebase emulators:start --only functions

# 2. 使用 curl 测试
curl -X POST http://localhost:5001/your-project/us-central1/create_exercise_templates_batch \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "coach_id": "test_coach_123",
      "exercise_names": ["深蹲", "卧推", "硬拉"]
    }
  }'
```

**验证**:
- [ ] 返回 status: "success"
- [ ] template_id_map 包含 3 个条目
- [ ] Firestore 中能看到创建的模板

---

### ✅ 任务 11.3: 端到端测试

手动测试完整流程:

1. [ ] 进入 CreateTrainingPlanPage
2. [ ] 选择 AI 引导创建
3. [ ] 填写参数，点击生成
4. [ ] 进入 aiStreaming 状态
5. [ ] 观察 4 个步骤依次执行
6. [ ] Step 2 显示实时生成详情
7. [ ] Step 3 计算统计数据
8. [ ] Step 4 显示 Summary Card
9. [ ] 点击 "查看完整计划"
10. [ ] 显示确认对话框（如有新动作）
11. [ ] 确认后创建模板
12. [ ] 进入 editing 状态
13. [ ] 验证所有 exercise 都有 exerciseTemplateId

---

### ✅ 任务 11.4: 边界情况测试

测试以下场景:

**场景 1: 空动作库**
- [ ] 所有动作都标记为 "新建"
- [ ] 批量创建所有动作

**场景 2: 完全匹配**
- [ ] 所有动作都标记为 "复用"
- [ ] 不显示确认对话框
- [ ] 直接进入 editing

**场景 3: 部分匹配**
- [ ] 正确统计复用和新建数量
- [ ] 只创建新动作的模板

**场景 4: 网络错误**
- [ ] 生成失败显示错误信息
- [ ] 允许用户返回

**场景 5: 创建模板失败**
- [ ] 显示错误对话框
- [ ] 允许用户重试

---

## 🎨 阶段 12: 优化与收尾 (1-2h)

### ✅ 任务 12.1: 添加动画效果

在 `AIStreamingView` 中确保:

- [ ] Step cards stagger animation (每个延迟 100ms)
- [ ] Progress bar 平滑过渡
- [ ] Summary card scale + fade in
- [ ] 数字计数动画 (1s)

---

### ✅ 任务 12.2: 性能优化

- [ ] 使用 `const` constructor 减少 rebuild
- [ ] 添加 `RepaintBoundary` 包裹独立动画组件
- [ ] 测试页面切换性能 (应 < 50ms)

---

### ✅ 任务 12.3: 错误处理优化

添加完善的错误处理:

- [ ] 生成失败 → 显示错误，允许返回
- [ ] 批量创建失败 → 显示错误，允许重试
- [ ] 网络超时 → 提示检查网络
- [ ] 所有错误都有用户友好的提示

---

### ✅ 任务 12.4: 更新文档

- [ ] 更新 `docs/training_plan/exercise_plan_create_summary.md`
- [ ] 添加流程图到文档
- [ ] 更新 `README.md` 提及新功能
- [ ] 添加截图/录屏到文档

---

## ✅ 最终检查清单

### 编译与运行
- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 全部通过
- [ ] `flutter build apk --debug` 成功
- [ ] 在真机上测试运行正常

### 功能验证
- [ ] AI 流式生成正常
- [ ] 4 个步骤依次执行
- [ ] 统计数据准确
- [ ] 批量创建模板成功
- [ ] exerciseTemplateId 正确注入

### UI/UX
- [ ] 动画流畅 (60fps)
- [ ] 颜色符合设计 (AppColors.primaryAction)
- [ ] 所有文案使用 i18n
- [ ] Typography 使用 AppTextStyles

### 后端
- [ ] Cloud Functions 部署成功
- [ ] API 调用正常
- [ ] Firestore 数据正确

---

## 📝 提交检查清单

- [ ] 代码已 format (`dart format .`)
- [ ] Git commit message 清晰
- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] 准备好提交 PR

---

**执行完成后，在新对话中报告执行结果！**
