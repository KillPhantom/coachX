import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/home/data/models/student_plans_model.dart';
import 'package:coach_x/features/student/home/presentation/providers/student_home_providers.dart';
import '../providers/plan_page_providers.dart';
import 'training_plan_content.dart';
import 'diet_plan_content.dart';
import 'supplement_plan_content.dart';
import 'plan_dropdown.dart';

/// 计划页面标签视图
///
/// 包含三个标签页：Training / Diet / Supplements
class PlanTabsView extends ConsumerWidget {
  final StudentPlansModel plans;
  final Future<void> Function()? onRefresh;

  const PlanTabsView({super.key, required this.plans, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTab = ref.watch(selectedPlanTabProvider);

    return Column(
      children: [
        // 标签切换器
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: CupertinoSlidingSegmentedControl<PlanTab>(
            groupValue: selectedTab,
            backgroundColor: AppColors.backgroundLight,
            thumbColor: AppColors.primaryColor,
            padding: const EdgeInsets.all(4),
            children: {
              PlanTab.training: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                child: Text(
                  l10n.planTabTraining,
                  style: AppTextStyles.callout.copyWith(
                    color: selectedTab == PlanTab.training
                        ? AppColors.primaryText
                        : AppColors.textSecondary,
                    fontWeight: selectedTab == PlanTab.training
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              PlanTab.diet: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                child: Text(
                  l10n.planTabDiet,
                  style: AppTextStyles.callout.copyWith(
                    color: selectedTab == PlanTab.diet
                        ? AppColors.primaryText
                        : AppColors.textSecondary,
                    fontWeight: selectedTab == PlanTab.diet
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              PlanTab.supplements: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                child: Text(
                  l10n.planTabSupplements,
                  style: AppTextStyles.callout.copyWith(
                    color: selectedTab == PlanTab.supplements
                        ? AppColors.primaryText
                        : AppColors.textSecondary,
                    fontWeight: selectedTab == PlanTab.supplements
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            },
            onValueChanged: (value) {
              if (value != null) {
                ref.read(selectedPlanTabProvider.notifier).state = value;
                // 切换标签时重置部位筛选
                ref.read(selectedBodyPartProvider.notifier).state = null;
              }
            },
          ),
        ),

        // 内容区域
        Expanded(child: _buildTabContent(context, selectedTab, ref)),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, PlanTab tab, WidgetRef ref) {
    switch (tab) {
      case PlanTab.training:
        return _buildTrainingTab(context, ref);
      case PlanTab.diet:
        return _buildDietTab(context, ref);
      case PlanTab.supplements:
        return _buildSupplementTab(context, ref);
    }
  }

  /// 构建训练计划 Tab
  Widget _buildTrainingTab(BuildContext context, WidgetRef ref) {
    final activeExercisePlanId = ref.watch(activeExercisePlanIdProvider);
    final activePlans = ref.watch(currentActivePlansProvider);
    final activePlan = activePlans['exercisePlan'];

    return Column(
      children: [
        // Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
          ),
          child: PlanDropdown(
            plans: plans.exercisePlans,
            activePlanId: activeExercisePlanId,
            onPlanSelected: (planId) async {
              try {
                await CloudFunctionsService.updateActivePlan(
                  planType: 'exercise',
                  planId: planId,
                );
                // Invalidate studentPlansProvider to refresh
                ref.invalidate(studentPlansProvider);
              } catch (e, stackTrace) {
                AppLogger.error('更新 Active Exercise Plan 失败', e, stackTrace);
              }
            },
            onCreateNew: () {
              context.push('/training-plan/new');
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Content
        Expanded(
          child: TrainingPlanContent(plan: activePlan, onRefresh: onRefresh),
        ),
      ],
    );
  }

  /// 构建饮食计划 Tab
  Widget _buildDietTab(BuildContext context, WidgetRef ref) {
    final activeDietPlanId = ref.watch(activeDietPlanIdProvider);
    final activePlans = ref.watch(currentActivePlansProvider);
    final activePlan = activePlans['dietPlan'];

    return Column(
      children: [
        // Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
          ),
          child: PlanDropdown(
            plans: plans.dietPlans,
            activePlanId: activeDietPlanId,
            onPlanSelected: (planId) async {
              try {
                await CloudFunctionsService.updateActivePlan(
                  planType: 'diet',
                  planId: planId,
                );
                // Invalidate studentPlansProvider to refresh
                ref.invalidate(studentPlansProvider);
              } catch (e, stackTrace) {
                AppLogger.error('更新 Active Diet Plan 失败', e, stackTrace);
              }
            },
            onCreateNew: () {
              context.push('/diet-plan/new');
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Content
        Expanded(
          child: DietPlanContent(plan: activePlan, onRefresh: onRefresh),
        ),
      ],
    );
  }

  /// 构建补剂计划 Tab
  Widget _buildSupplementTab(BuildContext context, WidgetRef ref) {
    final activeSupplementPlanId = ref.watch(activeSupplementPlanIdProvider);
    final activePlans = ref.watch(currentActivePlansProvider);
    final activePlan = activePlans['supplementPlan'];

    return Column(
      children: [
        // Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
          ),
          child: PlanDropdown(
            plans: plans.supplementPlans,
            activePlanId: activeSupplementPlanId,
            onPlanSelected: (planId) async {
              try {
                await CloudFunctionsService.updateActivePlan(
                  planType: 'supplement',
                  planId: planId,
                );
                // Invalidate studentPlansProvider to refresh
                ref.invalidate(studentPlansProvider);
              } catch (e, stackTrace) {
                AppLogger.error('更新 Active Supplement Plan 失败', e, stackTrace);
              }
            },
            onCreateNew: () {
              context.push('/supplement-plan/new');
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Content
        Expanded(
          child: SupplementPlanContent(plan: activePlan, onRefresh: onRefresh),
        ),
      ],
    );
  }
}
