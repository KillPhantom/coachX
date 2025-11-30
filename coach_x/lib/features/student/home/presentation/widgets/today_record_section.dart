import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import '../../data/models/student_plans_model.dart';
import '../../data/models/daily_training_model.dart';
import '../../../diet/data/models/student_diet_record_model.dart';
import '../providers/student_home_providers.dart';
import 'diet_plan_card.dart';

/// 今日饮食计划区块
///
/// 显示今日的饮食计划
class TodayRecordSection extends ConsumerWidget {
  const TodayRecordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(studentPlansProvider);
    final dayNumbersAsync = ref.watch(currentDayNumbersProvider);
    final progress = ref.watch(dietProgressProvider);
    final actualMacros = ref.watch(actualDietMacrosProvider);
    final todayTrainingAsync = ref.watch(optimizedTodayTrainingProvider);

    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (plans) {
        if (plans.hasNoPlan) {
          return const SizedBox.shrink();
        }

        // 处理 dayNumbers 加载中的情况
        // 如果 dayNumbers 尚未加载完成，提供默认值 { 'diet': 1 }
        // dayNumbersAsync 已经是 Map<String, int> 类型，不是 AsyncValue
        final dayNumbers = dayNumbersAsync;

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
                child: Text(l10n.todayRecord, style: AppTextStyles.bodyMedium),
              ),

              // 内容区域（包含指示器）
              _buildRecordCards(
                context,
                plans,
                dayNumbers,
                progress,
                actualMacros,
                todayTrainingAsync.valueOrNull, // 使用 valueOrNull 安全访问
              ),
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
    Map<String, double>? progress,
    Macros? actualMacros,
    DailyTrainingModel? todayTraining,
  ) {
    // 只显示饮食计划
    if (plans.dietPlan == null) {
      return const SizedBox.shrink();
    }

    return _DietPlanWithIndicator(
      plans: plans,
      dayNumbers: dayNumbers,
      progress: progress,
      actualMacros: actualMacros,
      todayDietRecord: todayTraining?.diet,
    );
  }
}

/// 内部 Widget：饮食计划卡片 + 指示器
class _DietPlanWithIndicator extends StatefulWidget {
  final StudentPlansModel plans;
  final Map<String, int> dayNumbers;
  final Map<String, double>? progress;
  final Macros? actualMacros;
  final StudentDietRecordModel? todayDietRecord;

  const _DietPlanWithIndicator({
    required this.plans,
    required this.dayNumbers,
    this.progress,
    this.actualMacros,
    this.todayDietRecord,
  });

  @override
  State<_DietPlanWithIndicator> createState() => _DietPlanWithIndicatorState();
}

class _DietPlanWithIndicatorState extends State<_DietPlanWithIndicator> {
  int _currentPage = 0;
  int _totalPages = 0;

  /// 合并计划餐次和学生自行添加的餐次
  List<Meal> _getMergedMeals(List<Meal> planMeals, List<Meal>? recordedMeals) {
    if (recordedMeals == null || recordedMeals.isEmpty) {
      return planMeals;
    }

    // 获取计划餐次的名称集合
    final planMealNames = planMeals.map((m) => m.name).toSet();

    // 找出学生自行添加的餐次（不在计划中的）
    final extraMeals =
        recordedMeals.where((m) => !planMealNames.contains(m.name)).toList();

    // 合并：计划餐次 + 额外餐次
    return [...planMeals, ...extraMeals];
  }

  @override
  Widget build(BuildContext context) {
    // 处理 dayNumbers 为空的情况
    final dayNum = widget.dayNumbers['diet'] ?? 1;

    // 获取当天的饮食计划，处理空列表情况
    final dietDay = widget.plans.dietPlan!.days.isNotEmpty
        ? widget.plans.dietPlan!.days.firstWhere(
            (day) => day.day == dayNum,
            orElse: () => widget.plans.dietPlan!.days.first,
          )
        : null;

    // 获取计划餐次和学生记录餐次
    final planMeals = dietDay?.meals ?? <Meal>[];
    final recordedMeals = widget.todayDietRecord?.meals;

    // 合并餐次列表
    final mergedMeals = _getMergedMeals(planMeals, recordedMeals);

    _totalPages = mergedMeals.length + 1;

    return Column(
      children: [
        // 饮食计划卡片
        DietPlanCard(
          dietDay: dietDay,
          mergedMeals: mergedMeals,
          actualMacros: widget.actualMacros,
          todayDietRecord: widget.todayDietRecord,
          progress: widget.progress,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
        ),

        // 圆点指示器
        if (_totalPages > 1) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildPageIndicator(),
          const SizedBox(height: AppDimensions.spacingM),
        ],
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppColors.primaryColor
                : AppColors.dividerLight,
          ),
        );
      }),
    );
  }
}
