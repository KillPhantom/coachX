import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../providers/student_home_providers.dart';

/// 今日训练计划区块
///
/// 显示今日训练计划的详细内容
class TodayTrainingPlanSection extends ConsumerWidget {
  const TodayTrainingPlanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(studentPlansProvider);
    final dayNumbers = ref.watch(currentDayNumbersProvider);

    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (plans) {
        if (plans.exercisePlan == null) {
          return const SizedBox.shrink();
        }

        final dayNum = dayNumbers['exercise'] ?? 1;
        final trainingDay = plans.exercisePlan!.days.firstWhere(
          (day) => day.day == dayNum,
          orElse: () => plans.exercisePlan!.days.first,
        );

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
              // 计划标题和描述
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plans.exercisePlan!.name,
                          style: AppTextStyles.title3,
                        ),
                        if (plans.exercisePlan!.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            plans.exercisePlan!.description,
                            style: AppTextStyles.callout.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  // 计划频率标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      l10n.daysPerWeek(plans.exercisePlan!.totalDays),
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // 今日训练卡片
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.todayTraining(trainingDay.name),
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getExercisesSummary(trainingDay, l10n),
                                style: AppTextStyles.callout.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingS,
                          ),
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          onPressed: () {
                            // TODO: 跳转到训练计划详情
                          },
                          child: Text(
                            l10n.detail,
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getExercisesSummary(dynamic trainingDay, AppLocalizations l10n) {
    final exercises = trainingDay.exercises as List;
    if (exercises.isEmpty) {
      return l10n.noExercises;
    }

    // 取前3个动作名称
    final names = exercises.take(3).map((e) => e.name).join(', ');
    if (exercises.length > 3) {
      return '$names...';
    }
    return names;
  }
}
