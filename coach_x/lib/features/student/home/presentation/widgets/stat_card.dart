import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 统计卡片组件
///
/// 用于显示各类统计数据：体重、卡路里、Volume PR等
class StatCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? currentValue;
  final String? previousValue;
  final String? changeText;
  final bool isPositiveChange;
  final bool hasData;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    this.subtitle,
    this.currentValue,
    this.previousValue,
    this.changeText,
    this.isPositiveChange = true,
    this.hasData = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!hasData) {
      // 无数据状态
      return _buildEmptyCard(l10n);
    }

    // 检查是否只有上周数据，没有本周数据
    final hasOnlyPreviousData = currentValue == null && previousValue != null;

    final cardContent = Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.dividerLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            title,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacingXS),

          // 当前值或上周数据
          if (currentValue != null)
            Text(
              currentValue!,
              style: AppTextStyles.title3.copyWith(
                color: AppColors.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (hasOnlyPreviousData)
            // 本周无数据，显示上周数据作为参考
            Text(
              previousValue!,
              style: AppTextStyles.title3.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: AppDimensions.spacingXS),

          // 对比信息和变化量
          if (changeText != null) ...[
            Row(
              children: [
                // 变化量
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositiveChange
                                ? AppColors.errorRed
                                : AppColors.successGreen)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    changeText!,
                    style: AppTextStyles.caption3.copyWith(
                      color: isPositiveChange
                          ? AppColors.errorRed
                          : AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (subtitle != null)
            // 显示说明文字
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            )
          else if (hasOnlyPreviousData)
            // 本周无数据时的提示
            Text(
              l10n.lastWeekData,
              style: AppTextStyles.caption3.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );

    // 如果有 onTap，使用 GestureDetector 包裹
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }

  Widget _buildEmptyCard(AppLocalizations l10n) {
    final emptyCard = Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.dividerLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 标题
          Text(
            title,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacingS),

          // 图标和提示
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Expanded(
                child: Text(
                  l10n.noDataStartRecording,
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // 如果有 onTap，使用 GestureDetector 包裹
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: emptyCard);
    }

    return emptyCard;
  }
}
