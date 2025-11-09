import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'diet_plan_card_components/total_nutrition_card.dart';
import 'diet_plan_card_components/meal_detail_card.dart';

/// 饮食计划卡片
///
/// PageView全宽滚动卡片，第一张显示总营养，后续显示各餐详情
class DietPlanCard extends StatefulWidget {
  final DietDay dietDay;
  final Map<String, double>? progress;
  final ValueChanged<int>? onPageChanged;

  const DietPlanCard({
    super.key,
    required this.dietDay,
    this.progress,
    this.onPageChanged,
  });

  @override
  State<DietPlanCard> createState() => _DietPlanCardState();
}

class _DietPlanCardState extends State<DietPlanCard> {
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

  @override
  Widget build(BuildContext context) {
    // 默认进度为 0（TBD: 未来从 todayRecord 计算）
    final progressData =
        widget.progress ??
        {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};

    final totalPages =
        widget.dietDay.meals.length + 1; // +1 for total nutrition card

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
                macros: widget.dietDay.macros,
                progress: progressData,
              ),
            );
          } else {
            // 后续卡：餐次详情
            final mealIndex = index - 1;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              child: MealDetailCard(meal: widget.dietDay.meals[mealIndex]),
            );
          }
        },
      ),
    );
  }
}
