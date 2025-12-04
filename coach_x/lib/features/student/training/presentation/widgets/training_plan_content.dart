import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import '../providers/plan_page_providers.dart';
import 'body_part_chips.dart';
import 'exercise_item_card.dart';

/// 训练计划内容页
///
/// 显示训练计划的完整内容，包括Coach's Plan、部位筛选、动作列表
class TrainingPlanContent extends ConsumerWidget {
  final ExercisePlanModel? plan;
  final Future<void> Function()? onRefresh;

  const TrainingPlanContent({super.key, this.plan, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedBodyPart = ref.watch(selectedBodyPartProvider);

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
                l10n.noPlanFound,
                style: AppTextStyles.title3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.createNewTrainingPlan,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              CupertinoButton.filled(
                onPressed: () {
                  context.push('/training-plan/new');
                },
                child: Text(l10n.getStarted, style: AppTextStyles.buttonMedium),
              ),
            ],
          ),
        ),
      );
    }

    // 提取所有部位名称
    final bodyParts = plan!.days.map((day) => day.name).toSet().toList();

    // 如果没有选中部位且有训练日，默认选中第一个
    if (selectedBodyPart == null && bodyParts.isNotEmpty) {
      Future.microtask(() {
        ref.read(selectedBodyPartProvider.notifier).state = bodyParts.first;
      });
    }

    // 根据选中的部位筛选训练天
    final filteredDays = selectedBodyPart == null
        ? plan!.days
        : plan!.days.where((day) => day.name == selectedBodyPart).toList();

    // 收集所有动作
    final List<Exercise> allExercises = [];
    for (var day in filteredDays) {
      allExercises.addAll(day.exercises);
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

        // Body Part Chips
        if (bodyParts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              child: BodyPartChips(bodyParts: bodyParts),
            ),
          ),

        // 间距
        const SliverToBoxAdapter(
          child: SizedBox(height: AppDimensions.spacingM),
        ),

        // Exercise List
        if (allExercises.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                selectedBodyPart != null
                    ? l10n.noExercisesForBodyPart
                    : l10n.noExercises,
                style: AppTextStyles.subhead.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              0,
              AppDimensions.spacingM,
              AppDimensions.spacingXXXL,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return ExerciseItemCard(exercise: allExercises[index]);
              }, childCount: allExercises.length),
            ),
          ),
      ],
    );
  }
}
