import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/student/diet/data/models/student_diet_record_model.dart';
import '../providers/student_home_providers.dart';
import 'diet_plan_card_components/total_nutrition_card.dart';
import 'diet_plan_card_components/meal_detail_card.dart';
import 'meal_detail_bottom_sheet.dart';

/// 饮食计划卡片
///
/// PageView全宽滚动卡片，第一张显示总营养，后续显示各餐详情
class DietPlanCard extends ConsumerStatefulWidget {
  final DietDay? dietDay;
  final List<Meal> mergedMeals;
  final Macros? actualMacros;
  final StudentDietRecordModel? todayDietRecord;
  final Map<String, double>? progress;
  final ValueChanged<int>? onPageChanged;

  const DietPlanCard({
    super.key,
    this.dietDay,
    required this.mergedMeals,
    this.actualMacros,
    this.todayDietRecord,
    this.progress,
    this.onPageChanged,
  });

  @override
  ConsumerState<DietPlanCard> createState() => _DietPlanCardState();
}

class _DietPlanCardState extends ConsumerState<DietPlanCard> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 显示餐次详情 Bottom Sheet
  void _showMealDetailSheet(BuildContext context, Meal recordedMeal) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => MealDetailBottomSheet(
        recordedMeal: recordedMeal,
        onUpdate: (updatedMeal) => _handleMealUpdate(updatedMeal),
      ),
    );
  }

  /// 处理餐次更新
  Future<void> _handleMealUpdate(Meal updatedMeal) async {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      throw Exception('用户未登录');
    }

    try {
      // 获取今天的日期
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 调用 Cloud Function 更新餐次
      await CloudFunctionsService.call('update_meal_record', {
        'studentId': userId,
        'date': today,
        'meal': updatedMeal.toJson(),
      });

      // 刷新相关 Provider
      ref.invalidate(optimizedTodayTrainingProvider);
      ref.invalidate(dietProgressProvider);
      ref.invalidate(actualDietMacrosProvider);

      AppLogger.info('餐次更新成功');
    } catch (e) {
      AppLogger.error('餐次更新失败', e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressData =
        widget.progress ??
        {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};

    final totalPages =
        widget.mergedMeals.length + 1; // +1 for total nutrition card

    // 计算目标营养值：
    // 1. 优先使用教练设置的 dietDay.macros（从 meals 累加计算）
    // 2. 如果教练未设置 meals，则使用 dietDay.targetMacros（教练设置的目标值）
    // 3. 如果都没有，使用零值（仅显示实际摄入，不计算进度）
    Macros targetMacros;
    if (widget.dietDay != null && widget.dietDay!.meals.isNotEmpty) {
      // 教练设置了具体餐次，使用餐次累加的营养值
      targetMacros = widget.dietDay!.macros;
    } else if (widget.dietDay?.targetMacros != null) {
      // 教练设置了目标营养值但没有具体餐次
      targetMacros = widget.dietDay!.targetMacros!;
    } else {
      // 没有任何目标值
      targetMacros = Macros.zero();
    }

    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: widget.onPageChanged,
        itemCount: totalPages,
        itemBuilder: (context, index) {
          if (index == 0) {
            // 第一张卡：总营养
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              child: TotalNutritionCard(
                macros: targetMacros,
                actualMacros: widget.actualMacros,
                progress: progressData,
              ),
            );
          } else {
            // 后续卡：餐次详情
            final mealIndex = index - 1;
            final displayMeal = widget.mergedMeals[mealIndex];

            // 从今日记录中查找匹配的餐次
            final recordedMeal = widget.todayDietRecord?.meals
                .cast<Meal?>()
                .firstWhere((m) => m?.name == displayMeal.name,
                    orElse: () => null);

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              child: MealDetailCard(
                meal: displayMeal,
                recordedMeal: recordedMeal,
                onViewDetails: recordedMeal != null
                    ? () => _showMealDetailSheet(context, recordedMeal)
                    : null,
              ),
            );
          }
        },
      ),
    );
  }
}
