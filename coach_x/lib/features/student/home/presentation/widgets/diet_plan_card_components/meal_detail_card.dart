import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';

/// 单餐详情卡片
///
/// 显示餐名、备注、食物列表和营养数据
class MealDetailCard extends StatelessWidget {
  final Meal meal;

  const MealDetailCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final macros = meal.macros;

    return Container(
      height: 160,
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
          // 餐名
          Text(
            meal.name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // 备注（如果有）
          if (meal.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meal.note,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppDimensions.spacingS),

          // 食物列表
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: meal.items.length,
              itemBuilder: (context, index) {
                final item = meal.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${item.food} ${item.amount}',
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppDimensions.spacingS),

          // 营养数据行
          Text(
            '${macros.calories.toInt()} ${l10n.kcal} | '
            'P:${macros.protein.toInt()}g | '
            'C:${macros.carbs.toInt()}g | '
            'F:${macros.fat.toInt()}g',
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
