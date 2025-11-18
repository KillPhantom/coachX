import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// 饮食日编辑面板
class DietDayEditor extends StatelessWidget {
  final VoidCallback? onAddMeal;
  final Widget? mealsWidget;
  final Macros? totalMacros;

  const DietDayEditor({
    super.key,
    this.onAddMeal,
    this.mealsWidget,
    this.totalMacros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Total Macros Summary
          if (totalMacros != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar_circle_fill,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Total',
                        style: AppTextStyles.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMacroChip(
                        context,
                        '${totalMacros!.protein.toStringAsFixed(1)}g',
                        '蛋白质',
                        CupertinoIcons.bolt_fill,
                        AppColors.secondaryBlue,
                      ),
                      _buildMacroChip(
                        context,
                        '${totalMacros!.carbs.toStringAsFixed(1)}g',
                        '碳水',
                        CupertinoIcons.flame_fill,
                        AppColors.secondaryOrange,
                      ),
                      _buildMacroChip(
                        context,
                        '${totalMacros!.fat.toStringAsFixed(1)}g',
                        '脂肪',
                        CupertinoIcons.drop_fill,
                        AppColors.secondaryRed,
                      ),
                      _buildMacroChip(
                        context,
                        totalMacros!.calories.toStringAsFixed(0),
                        '卡路里',
                        CupertinoIcons.flame_fill,
                        AppColors.secondaryPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Meals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '餐次列表 (Meals)',
                style: AppTextStyles.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onAddMeal != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onAddMeal,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '添加',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Meals List
          if (mealsWidget != null) mealsWidget!,
        ],
      ),
    );
  }

  Widget _buildMacroChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption1.copyWith()),
              Text(
                value,
                style: AppTextStyles.caption2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
