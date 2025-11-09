import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import '../providers/plan_page_providers.dart';
import 'day_selector_pills.dart';
import 'diet_day_content.dart';

/// 饮食计划内容页
///
/// 显示完整的饮食计划，包括日期选择器和每日详情
class DietPlanContent extends ConsumerWidget {
  final DietPlanModel? plan;
  final Future<void> Function()? onRefresh;

  const DietPlanContent({super.key, this.plan, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (plan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.doc_text,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.noPlanAssigned,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.contactCoachForPlan,
                style: AppTextStyles.subhead.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final selectedDay = ref.watch(selectedDietDayProvider);

    // 获取选中天的数据
    final selectedDietDay = plan!.days.firstWhere(
      (day) => day.day == selectedDay,
      orElse: () => plan!.days.first,
    );

    // 如果选中的天数超出范围，重置为第一天
    if (selectedDay > plan!.days.length) {
      Future.microtask(() {
        ref.read(selectedDietDayProvider.notifier).state = 1;
      });
    }

    return CustomScrollView(
      slivers: [
        // 下拉刷新
        if (onRefresh != null)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),

        // Plan Description
        if (plan!.description.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              child: Text(
                plan!.description,
                style: AppTextStyles.subhead.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

        // Day Selector Pills
        if (plan!.days.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              child: DaySelectorPills(
                totalDays: plan!.days.length,
                selectedDay: selectedDay,
                onDaySelected: (day) {
                  ref.read(selectedDietDayProvider.notifier).state = day;
                },
              ),
            ),
          ),

        // Diet Day Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              0,
              AppDimensions.spacingM,
              AppDimensions.spacingXXXL,
            ),
            child: plan!.days.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacingXL),
                      child: Text(
                        l10n.noPlanAssigned,
                        style: AppTextStyles.subhead.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : DietDayContent(dietDay: selectedDietDay),
          ),
        ),
      ],
    );
  }
}
