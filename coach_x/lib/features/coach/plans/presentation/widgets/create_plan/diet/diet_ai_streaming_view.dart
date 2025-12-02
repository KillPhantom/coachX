import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_providers.dart';
import '../shared/step_card.dart';
import '../shared/progress_bar.dart';
import 'diet_summary_card.dart';

/// 饮食计划 AI 流式生成进度视图
///
/// 显示饮食计划生成的 4 个步骤进度：
/// Step 1: 分析饮食要求 (0-20%)
/// Step 2: 生成饮食计划 (20-85%)
/// Step 3: 计算营养数据 (85-95%)
/// Step 4: 完成生成 (100%)
class DietAIStreamingView extends ConsumerWidget {
  final VoidCallback onConfirm;

  const DietAIStreamingView({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createDietPlanNotifierProvider);

    final currentStep = state.currentStep;
    final currentStepProgress = state.currentStepProgress;
    final aiStatus = state.aiStatus;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header and content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(l10n, currentStepProgress),
                    const SizedBox(height: 35),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSteps(l10n, currentStep, currentStepProgress),

                            // ✅ 成功：显示 DietSummaryCard
                            if (aiStatus == AIGenerationStatus.success &&
                                state.dietStreamingStats != null) ...[
                              const SizedBox(height: 30),
                              DietSummaryCard(stats: state.dietStreamingStats!),
                            ],

                            // ❌ 失败：显示错误卡片
                            if (aiStatus == AIGenerationStatus.error) ...[
                              const SizedBox(height: 30),
                              _buildErrorCard(context, l10n),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom confirm button (only show when success)
            if (aiStatus == AIGenerationStatus.success &&
                currentStep == 4) ...[
              _buildConfirmButton(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, double progress) {
    return Column(
      children: [
        Text(
          'AI 正在生成您的饮食计划',
          style: AppTextStyles.bodySemiBold.copyWith(
            color: CupertinoColors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        StreamingProgressBar(progress: progress),
      ],
    );
  }

  Widget _buildSteps(AppLocalizations l10n, int currentStep, double currentStepProgress) {
    return Column(
      children: [
        _buildStepCard(
          l10n,
          stepNumber: 1,
          title: l10n.dietStep1Title,
          description: l10n.dietStep1Description,
          currentStep: currentStep,
          currentStepProgress: currentStepProgress,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 2,
          title: l10n.dietStep2Title,
          description: l10n.dietStep2Description,
          currentStep: currentStep,
          currentStepProgress: currentStepProgress,
          detailText: _getCurrentDayDetail(currentStep),
        ),
        _buildStepCard(
          l10n,
          stepNumber: 3,
          title: l10n.dietStep3Title,
          description: l10n.dietStep3Description,
          currentStep: currentStep,
          currentStepProgress: currentStepProgress,
        ),
        _buildStepCard(
          l10n,
          stepNumber: 4,
          title: l10n.dietStep4Title,
          description: l10n.dietStep4Description,
          currentStep: currentStep,
          currentStepProgress: currentStepProgress,
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

  String? _getCurrentDayDetail(int currentStep) {
    // TODO: 从 state.currentDayInProgress 获取
    if (currentStep == 2) {
      return '正在生成第 3 天：早餐-燕麦粥，午餐-鸡胸肉沙拉...';
    }
    return null;
  }

  /// 构建错误卡片
  Widget _buildErrorCard(BuildContext context, AppLocalizations l10n) {
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

          // 错误消息
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
              onPressed: () => _handleRetry(context),
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
  void _handleRetry(BuildContext context) {
    // TODO: 调用 notifier.retryGeneration()
  }

  /// 构建底部确认按钮
  Widget _buildConfirmButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onConfirm,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.viewDetailsAndEdit,
              style: AppTextStyles.buttonLarge.copyWith(
                color: CupertinoColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
