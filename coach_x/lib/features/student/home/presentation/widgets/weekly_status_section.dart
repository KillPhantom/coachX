import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/routes/route_names.dart';
import '../../data/models/weekly_stats_model.dart';
import '../providers/student_home_providers.dart';
import 'stat_card.dart';

/// 周状态区块
///
/// 显示本周7天的训练打卡状态 + 统计卡片
class WeeklyStatusSection extends ConsumerWidget {
  const WeeklyStatusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(weeklyStatsProvider);

    return statsAsync.when(
      loading: () => _buildLoadingState(l10n),
      error: (error, stack) => _buildErrorState(l10n, error),
      data: (stats) => _buildContentState(context, l10n, stats),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
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
      child: const Center(child: LoadingIndicator()),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, Object error) {
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
      child: Text(
        'Error: ${error.toString()}',
        style: AppTextStyles.caption1.copyWith(color: AppColors.errorRed),
      ),
    );
  }

  Widget _buildContentState(
    BuildContext context,
    AppLocalizations l10n,
    dynamic stats,
  ) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekDaysCN = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    final trainings = stats.currentWeek.trainings;
    final completedCount = stats.currentWeek.completedCount;
    final todayIndex = stats.currentWeek.todayIndex;
    final studentId = AuthService.currentUserId;
    final startDate = DateTime.tryParse(stats.currentWeek.startDate);

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
              Text(l10n.weeklyStatus, style: AppTextStyles.bodyMedium),
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
              final isCompleted = index < trainings.length
                  ? trainings[index].hasRecord
                  : false;
              final isToday = index == todayIndex;
              final dayLabel =
                  Localizations.localeOf(context).languageCode == 'zh'
                  ? weekDaysCN[index]
                  : weekDays[index];

              // 计算该天的日期
              final dayDate = startDate?.add(Duration(days: index));
              final dayDateString = dayDate != null
                  ? '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}'
                  : null;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (studentId != null) {
                      context.push(
                        RouteNames.getTrainingCalendarRoute(
                          studentId,
                          focusDate: dayDateString,
                        ),
                      );
                    }
                  },
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
                ),
              );
            }),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // 统计卡片区域
          Row(
            children: [
              // Weight Change
              Expanded(
                child: StatCard(
                  title: l10n.weightChange,
                  currentValue: stats.weightChange.hasData &&
                          stats.weightChange.currentWeight != null
                      ? '${stats.weightChange.currentWeight}${stats.weightChange.unit}'
                      : null,
                  previousValue: stats.weightChange.hasData &&
                          stats.weightChange.previousWeight != null
                      ? '${stats.weightChange.previousWeight}${stats.weightChange.unit}'
                      : null,
                  changeText: _buildWeightChangeText(stats.weightChange, l10n),
                  isPositiveChange: stats.weightChange.change != null &&
                      stats.weightChange.change! >= 0,
                  hasData: stats.weightChange.hasData,
                  onTap: () => context.push(RouteNames.studentBodyStatsHistory),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),

              // Calories Intake
              Expanded(
                child: StatCard(
                  title: l10n.caloriesIntake,
                  currentValue:
                      stats.caloriesChange.hasData &&
                          stats.caloriesChange.currentWeekTotal != null
                      ? '${stats.caloriesChange.currentWeekTotal!.toInt()}'
                      : null,
                  previousValue:
                      stats.caloriesChange.hasData &&
                          stats.caloriesChange.lastWeekTotal != null
                      ? '${stats.caloriesChange.lastWeekTotal!.toInt()}'
                      : null,
                  changeText:
                      stats.caloriesChange.hasData &&
                          stats.caloriesChange.change != null
                      ? (stats.caloriesChange.change! >= 0
                            ? '+${stats.caloriesChange.change!.toInt()}'
                            : '${stats.caloriesChange.change!.toInt()}')
                      : null,
                  subtitle:
                      stats.caloriesChange.hasData &&
                          stats.caloriesChange.change == null
                      ? '${l10n.thisWeekIntake} · ${l10n.noLastWeekData}'
                      : null,
                  isPositiveChange:
                      stats.caloriesChange.change != null &&
                      stats.caloriesChange.change! >= 0,
                  hasData: stats.caloriesChange.hasData,
                ),
              ),
            ],
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
          border: Border.all(color: AppColors.primaryColor, width: 2),
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

  /// 构建体重变化文本
  ///
  /// 显示规则：
  /// - 0 天: "today"
  /// - 1 天: "yesterday"
  /// - 2+ 天: "X days ago"
  String? _buildWeightChangeText(
    WeightChangeStats weightChange,
    AppLocalizations l10n,
  ) {
    if (weightChange.change == null) {
      return null;
    }

    final changeStr = weightChange.change! >= 0
        ? '+${weightChange.change!.toStringAsFixed(1)}'
        : weightChange.change!.toStringAsFixed(1);

    // 如果没有天数信息，只显示变化量
    if (weightChange.daysSince == null) {
      return changeStr;
    }

    // 根据天数选择显示文本
    final daysText = switch (weightChange.daysSince!) {
      0 => l10n.today,
      1 => l10n.yesterday,
      _ => l10n.daysAgo(weightChange.daysSince!),
    };

    return '$changeStr $daysText';
  }
}
