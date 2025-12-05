import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_plan_model.dart';
import '../providers/student_home_providers.dart';
import 'supplement_plan_card.dart';
import 'supplement_day_detail_sheet.dart';

/// 今日补剂计划区块
///
/// 显示今日的补剂计划
class TodaySupplementSection extends ConsumerWidget {
  const TodaySupplementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(studentPlansProvider);
    final activePlans = ref.watch(currentActivePlansProvider);
    final dayNumbersAsync = ref.watch(currentDayNumbersProvider);

    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (plans) {
        // 从 activePlans 获取当前激活的补剂计划
        final activeSupplementPlan =
            activePlans['supplementPlan'] as SupplementPlanModel?;

        // 如果没有补剂计划，显示空状态
        if (activeSupplementPlan == null) {
          return _buildEmptyState(l10n);
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Text(
                  l10n.supplementPlan,
                  style: AppTextStyles.bodyMedium,
                ),
              ),

              // 补剂卡片
              _buildSupplementCard(activeSupplementPlan, dayNumbersAsync),
            ],
          ),
        );
      },
    );
  }

  /// 构建空状态卡片
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(l10n.supplementPlan, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.spacingM),

          // 空状态内容
          Row(
            children: [
              Icon(
                CupertinoIcons.capsule,
                size: 20,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.noSupplementPlan,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementCard(
    SupplementPlanModel supplementPlan,
    Map<String, int> dayNumbers,
  ) {
    final dayNum = dayNumbers['supplement'] ?? 1;
    final supplementDay = supplementPlan.days.firstWhere(
      (day) => day.day == dayNum,
      orElse: () => supplementPlan.days.first,
    );

    // 计算总补剂数
    int totalSupplements = 0;
    for (final timing in supplementDay.timings) {
      totalSupplements += timing.supplements.length;
    }

    return Consumer(
      builder: (context, ref, child) => SupplementPlanCard(
        supplementsCount: totalSupplements,
        onTap: () => _showSupplementDayDetail(context, supplementDay),
      ),
    );
  }

  /// 显示补剂日详情
  void _showSupplementDayDetail(BuildContext context, supplementDay) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          SupplementDayDetailSheet(supplementDay: supplementDay),
    );
  }
}
