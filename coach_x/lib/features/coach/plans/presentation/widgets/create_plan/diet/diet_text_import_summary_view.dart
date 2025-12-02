import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'diet_summary_card.dart';

/// 饮食计划文本导入总结视图
///
/// 显示从文本/OCR 导入的饮食计划统计摘要
class DietTextImportSummaryView extends ConsumerWidget {
  const DietTextImportSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // TODO: 监听 CreateDietPlanNotifier 的状态
    // final state = ref.watch(createDietPlanNotifierProvider);
    // final stats = state.dietStreamingStats;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // 标题区域
            _buildHeader(l10n),

            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 统计摘要卡片
                    // TODO: 传入实际的 stats
                    // DietSummaryCard(
                    //   stats: stats!,
                    //   onViewPlan: () => _handleConfirm(context, ref),
                    // ),

                    // 临时占位
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.doc_text,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '文本导入成功',
                            style: AppTextStyles.title3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '等待 Session 4 实现状态管理',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部确认按钮
            _buildConfirmButton(l10n, context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '导入完成',
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '以下是导入的饮食计划统计',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(
      AppLocalizations l10n, BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: () => _handleConfirm(context, ref),
            child: Text(
              l10n.confirm,
              style: AppTextStyles.buttonLarge.copyWith(
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleConfirm(BuildContext context, WidgetRef ref) {
    // TODO: 切换到 editing 状态
    // final notifier = ref.read(createDietPlanNotifierProvider.notifier);
    // notifier.updatePageState(CreatePlanPageState.editing);
  }
}
