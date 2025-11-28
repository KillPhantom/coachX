import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';
import 'package:coach_x/features/coach/plans/data/models/create_plan_page_state.dart';
import 'package:coach_x/features/coach/plans/data/models/create_training_plan_state.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/providers/exercise_library_providers.dart';
import 'step_card.dart';
import 'summary_card.dart';
import 'create_templates_confirmation_dialog.dart';

class AIStreamingView extends ConsumerWidget {
  const AIStreamingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createTrainingPlanNotifierProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(l10n, state),
              const SizedBox(height: 35),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSteps(l10n, state),
                      // ✅ 成功：显示 SummaryCard
                      if (state.aiStatus == AIGenerationStatus.success &&
                          state.currentStep == 4 &&
                          state.aiStreamingStats != null) ...[
                        const SizedBox(height: 30),
                        SummaryCard(
                          stats: state.aiStreamingStats!,
                          onViewPlan: () => _handleViewPlan(context, ref),
                        ),
                      ],
                      // ✅ 失败：显示错误卡片
                      if (state.aiStatus == AIGenerationStatus.error) ...[
                        const SizedBox(height: 30),
                        _buildErrorCard(context, ref, l10n),
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

  Widget _buildHeader(AppLocalizations l10n, state) {
    return Column(
      children: [
        Text(
          l10n.aiStreamingSubtitle,
          style: AppTextStyles.bodySemiBold.copyWith(
            color: CupertinoColors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildProgressBar(state.currentStepProgress),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CupertinoColors.systemGrey4, width: 0.5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: constraints.maxWidth * (progress / 100),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSteps(AppLocalizations l10n, state) {
    return Column(
      children: [
        _buildStepCard(
          l10n,
          stepNumber: 1,
          title: l10n.step1Title,
          description: l10n.step1Description,
          currentStep: state.currentStep,
          currentStepProgress: state.currentStepProgress,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 2,
          title: l10n.step2Title,
          description: l10n.step2Description,
          currentStep: state.currentStep,
          currentStepProgress: state.currentStepProgress,
          detailText: state.currentStep == 2
              ? _getCurrentDayDetail(state)
              : null,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 3,
          title: l10n.step3Title,
          description: l10n.step3Description,
          currentStep: state.currentStep,
          currentStepProgress: state.currentStepProgress,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 4,
          title: l10n.step4Title,
          description: l10n.step4Description,
          currentStep: state.currentStep,
          currentStepProgress: state.currentStepProgress,
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
    required double currentStepProgress,
    String? detailText,
  }) {
    StepStatus status;
    if (currentStep > stepNumber) {
      status = StepStatus.completed;
    } else if (currentStep == stepNumber) {
      // 特殊处理：Step 4 完成时（进度100%）显示为 completed
      if (stepNumber == 4 && currentStepProgress >= 100) {
        status = StepStatus.completed;
      } else {
        status = StepStatus.loading;
      }
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

  String? _getCurrentDayDetail(CreateTrainingPlanState state) {
    if (state.currentDayInProgress != null) {
      final day = state.currentDayInProgress!;
      final exerciseNames = day.exercises.map((e) => e.name).take(3).join('、');
      return '正在生成第 ${day.day} 天：$exerciseNames...';
    }
    return null;
  }

  /// 构建错误卡片
  Widget _buildErrorCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 错误图标
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemRed,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // 错误标题
          Text(
            l10n.generationFailed,
            style: AppTextStyles.title3.copyWith(
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),

          // 错误消息（简化统一）
          Text(
            l10n.serverError,
            style: AppTextStyles.body.copyWith(
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // 重试按钮
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: () => _handleRetry(context, ref),
              child: Text(
                l10n.retryGeneration,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理重试
  void _handleRetry(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    AppLogger.info('🔄 用户点击重试生成');
    await notifier.retryGeneration();
  }

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

          // 强制刷新动作库，确保新模板已加载到缓存
          await ref.read(exerciseLibraryNotifierProvider.notifier).loadData();

          // 注入 templateId
          notifier.injectTemplateIdsIntoPlan(templateIdMap);

          // 进入 editing 状态
          notifier.updatePageState(CreatePlanPageState.editing);
        } catch (e) {
          // 显示错误
          if (context.mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('创建失败'),
                content: Text('无法创建动作模板: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('确定', style: AppTextStyles.buttonMedium),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        }
      }
    } else {
      // 没有新动作，直接进入 editing
      notifier.updatePageState(CreatePlanPageState.editing);
    }
  }
}
