import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../data/models/student_plans_model.dart';
import '../providers/student_home_providers.dart';
import 'diet_record_card.dart';
import 'exercise_record_card.dart';
import 'supplement_record_card.dart';

/// 今日记录区块
///
/// 显示今日的训练、饮食、补剂目标（从计划中读取）
class TodayRecordSection extends ConsumerWidget {
  const TodayRecordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(studentPlansProvider);
    final dayNumbersAsync = ref.watch(currentDayNumbersProvider);

    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (plans) {
        if (plans.hasNoPlan) {
          return const SizedBox.shrink();
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
                  l10n.todayRecord,
                  style: AppTextStyles.bodyMedium,
                ),
              ),

              // 内容区域
              _buildRecordCards(context, plans, dayNumbersAsync),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordCards(
    BuildContext context,
    StudentPlansModel plans,
    Map<String, int> dayNumbers,
  ) {
    return Column(
      children: [
        // 饮食记录
        if (plans.dietPlan != null) _buildDietCard(plans, dayNumbers),

        // 训练记录
        if (plans.exercisePlan != null) _buildExerciseCard(plans, dayNumbers),

        // 补剂记录
        if (plans.supplementPlan != null)
          _buildSupplementCard(plans, dayNumbers),
      ],
    );
  }

  Widget _buildDietCard(StudentPlansModel plans, Map<String, int> dayNumbers) {
    final dayNum = dayNumbers['diet'] ?? 1;
    final dietDay = plans.dietPlan!.days.firstWhere(
      (day) => day.day == dayNum,
      orElse: () => plans.dietPlan!.days.first,
    );

    return DietRecordCard(
      mealsCount: dietDay.meals.length,
      macros: dietDay.macros,
      onTap: () {
        // TODO: 跳转到饮食详情
      },
    );
  }

  Widget _buildExerciseCard(
      StudentPlansModel plans, Map<String, int> dayNumbers) {
    final dayNum = dayNumbers['exercise'] ?? 1;
    final trainingDay = plans.exercisePlan!.days.firstWhere(
      (day) => day.day == dayNum,
      orElse: () => plans.exercisePlan!.days.first,
    );

    return ExerciseRecordCard(
      exercisesCount: trainingDay.totalExercises,
      onTap: () {
        // TODO: 跳转到训练详情
      },
    );
  }

  Widget _buildSupplementCard(
      StudentPlansModel plans, Map<String, int> dayNumbers) {
    final dayNum = dayNumbers['supplement'] ?? 1;
    final supplementDay = plans.supplementPlan!.days.firstWhere(
      (day) => day.day == dayNum,
      orElse: () => plans.supplementPlan!.days.first,
    );

    // 计算总补剂数
    int totalSupplements = 0;
    for (final timing in supplementDay.timings) {
      totalSupplements += timing.supplements.length;
    }

    return SupplementRecordCard(
      supplementsCount: totalSupplements,
      onTap: () {
        // TODO: 跳转到补剂详情
      },
    );
  }
}
