import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';

/// 餐次建议卡片组件
class MealSuggestionCard extends StatelessWidget {
  final Meal meal;
  final int index;
  final VoidCallback onToggleComplete;

  const MealSuggestionCard({
    super.key,
    required this.meal,
    required this.index,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final macros = meal.macros;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meal.name, style: AppTextStyles.bodyMedium),
              Text(
                '${macros.protein.toInt()}P/${macros.carbs.toInt()}C/${macros.fat.toInt()}F',
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...meal.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item.food}: ${item.amount}',
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.primaryColor,
              onPressed: onToggleComplete,
              child: Text(
                meal.completed ? l10n.mealCompleted : l10n.addRecord,
                style: AppTextStyles.footnote,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
