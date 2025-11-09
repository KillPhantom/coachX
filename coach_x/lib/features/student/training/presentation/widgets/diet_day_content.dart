import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';

/// 饮食日内容组件
///
/// 展示单日完整饮食计划，包括所有餐次和总营养汇总
class DietDayContent extends StatelessWidget {
  final DietDay dietDay;

  const DietDayContent({super.key, required this.dietDay});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 所有餐次列表
        ...dietDay.meals.map((meal) => _buildMealCard(context, meal, l10n)),

        // 总营养汇总
        const SizedBox(height: AppDimensions.spacingM),
        _buildTotalNutritionCard(context, l10n),
      ],
    );
  }

  /// 构建单餐卡片
  Widget _buildMealCard(BuildContext context, Meal meal, AppLocalizations l10n) {
    final macros = meal.macros;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
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
          ),

          // 备注（如果有）
          if (meal.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meal.note,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.spacingS),

          // 食物列表
          ...meal.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.circle_fill,
                    size: 6,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.food} ${item.amount}',
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacingS),
          Container(
            height: 1,
            color: AppColors.dividerLight,
          ),
          const SizedBox(height: AppDimensions.spacingS),

          // 营养数据行
          Text(
            '${macros.calories.toInt()} ${l10n.kcal} | '
            'P:${macros.protein.toInt()}g | '
            'C:${macros.carbs.toInt()}g | '
            'F:${macros.fat.toInt()}g',
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建总营养汇总卡片
  Widget _buildTotalNutritionCard(BuildContext context, AppLocalizations l10n) {
    final totalMacros = dietDay.macros;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            l10n.totalNutrition,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // 总卡路里
          Row(
            children: [
              const Icon(
                CupertinoIcons.flame_fill,
                size: 20,
                color: AppColors.primaryText,
              ),
              const SizedBox(width: 8),
              Text(
                '${totalMacros.calories.toInt()} ${l10n.kcal}',
                style: AppTextStyles.title3.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingS),

          // 宏营养素
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem(
                l10n.protein,
                totalMacros.protein.toInt(),
                const Color(0xFFFF6B6B),
              ),
              _buildMacroItem(
                l10n.carbs,
                totalMacros.carbs.toInt(),
                const Color(0xFFF59E0B),
              ),
              _buildMacroItem(
                l10n.fat,
                totalMacros.fat.toInt(),
                const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个宏营养素项
  Widget _buildMacroItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value}g',
          style: AppTextStyles.callout.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
