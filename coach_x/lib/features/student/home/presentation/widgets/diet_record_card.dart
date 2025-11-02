import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// 饮食记录卡片
///
/// 显示今日饮食目标（营养数据）
class DietRecordCard extends StatelessWidget {
  final int mealsCount;
  final Macros macros;
  final VoidCallback? onTap;

  const DietRecordCard({
    super.key,
    required this.mealsCount,
    required this.macros,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.dividerLight,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和餐次数
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dietRecord,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.square_list,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.mealsCount(mealsCount),
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // 营养数据网格
            Row(
              children: [
                Expanded(
                  child: _buildMacroCard(
                    label: l10n.protein,
                    value: '${macros.protein.toInt()}g',
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                    textColor: AppColors.primaryText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroCard(
                    label: l10n.carbs,
                    value: '${macros.carbs.toInt()}g',
                    backgroundColor: const Color(0xFFFFF3CD),
                    textColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroCard(
                    label: l10n.fat,
                    value: '${macros.fat.toInt()}g',
                    backgroundColor: const Color(0xFFFEE2E2),
                    textColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingM,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
