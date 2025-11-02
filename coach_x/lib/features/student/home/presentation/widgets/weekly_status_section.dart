import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 周状态区块
///
/// 显示本周7天的训练打卡状态
/// 注意：当前使用占位数据，因为dailyTraining尚未实现
class WeeklyStatusSection extends StatelessWidget {
  const WeeklyStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // TODO: 替换为真实数据
    // 当前使用占位数据：假设周一、周二、周三已完成，今天是周四
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekDaysCN = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final completedDays = [true, true, true, false, false, false, false];
    final todayIndex = 3; // 周四
    final completedCount = 3;

    return Container(
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
          // 标题和统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weeklyStatus,
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                l10n.daysRecorded(completedCount),
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // 7天圆点
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isCompleted = completedDays[index];
              final isToday = index == todayIndex;
              final dayLabel = Localizations.localeOf(context).languageCode == 'zh'
                  ? weekDaysCN[index]
                  : weekDays[index];

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: AppTextStyles.caption1.copyWith(
                        color: isToday
                            ? AppColors.primaryText
                            : AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildDayIndicator(isCompleted, isToday),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayIndicator(bool isCompleted, bool isToday) {
    if (isCompleted) {
      // 已完成：绿色圆点+勾
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.successColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.check_mark,
          color: AppColors.backgroundWhite,
          size: 16,
        ),
      );
    } else if (isToday) {
      // 今天：主色圆点+环形边框+加号
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: AppColors.primaryText,
          size: 16,
        ),
      );
    } else {
      // 未完成：灰色圆点
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.dividerLight,
          shape: BoxShape.circle,
        ),
      );
    }
  }
}
