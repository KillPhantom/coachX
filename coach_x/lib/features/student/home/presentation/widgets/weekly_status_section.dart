import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/routes/route_names.dart';
import '../../data/models/weight_comparison_model.dart';
import '../providers/student_home_providers.dart';
import '../providers/weight_comparison_provider.dart';
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

          const SizedBox(height: AppDimensions.spacingL),

          // 统计卡片区域
          Row(
            children: [
              // Weight Change
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final weightComparisonAsync = ref.watch(
                      weightComparisonProvider,
                    );

                    return weightComparisonAsync.when(
                      loading: () => StatCard(
                        title: l10n.weightChange,
                        hasData: false,
                        onTap: () =>
                            context.push(RouteNames.studentBodyStatsHistory),
                      ),
                      error: (_, __) => StatCard(
                        title: l10n.weightChange,
                        currentValue:
                            stats.weightChange.hasData &&
                                stats.weightChange.currentWeekAvg != null
                            ? '${stats.weightChange.currentWeekAvg}${stats.weightChange.unit}'
                            : null,
                        previousValue:
                            stats.weightChange.hasData &&
                                stats.weightChange.lastWeekAvg != null
                            ? '${stats.weightChange.lastWeekAvg}${stats.weightChange.unit}'
                            : null,
                        changeText: _buildWeeklyChangeText(stats.weightChange),
                        isPositiveChange:
                            stats.weightChange.change != null &&
                            stats.weightChange.change! >= 0,
                        hasData: stats.weightChange.hasData,
                        onTap: () =>
                            context.push(RouteNames.studentBodyStatsHistory),
                      ),
                      data: (comparison) {
                        // 决定显示模式：相对天数 or 周对比
                        final useRelativeMode =
                            comparison.hasData &&
                            comparison.daysSince != null &&
                            comparison.daysSince! < 7;

                        // 构建显示值
                        final currentValue =
                            comparison.hasData &&
                                comparison.currentWeight != null
                            ? '${comparison.currentWeight!.toStringAsFixed(1)}${stats.weightChange.unit}'
                            : (stats.weightChange.hasData &&
                                      stats.weightChange.currentWeekAvg != null
                                  ? '${stats.weightChange.currentWeekAvg}${stats.weightChange.unit}'
                                  : null);

                        final previousValue =
                            comparison.hasData &&
                                comparison.previousWeight != null
                            ? '${comparison.previousWeight!.toStringAsFixed(1)}${stats.weightChange.unit}'
                            : (stats.weightChange.hasData &&
                                      stats.weightChange.lastWeekAvg != null
                                  ? '${stats.weightChange.lastWeekAvg}${stats.weightChange.unit}'
                                  : null);

                        final changeText = useRelativeMode
                            ? _buildRelativeChangeText(comparison, l10n)
                            : _buildWeeklyChangeText(stats.weightChange);

                        final isPositive =
                            comparison.hasData && comparison.change != null
                            ? comparison.change! >= 0
                            : (stats.weightChange.change != null &&
                                  stats.weightChange.change! >= 0);

                        return StatCard(
                          title: l10n.weightChange,
                          currentValue: currentValue,
                          previousValue: previousValue,
                          changeText: changeText,
                          isPositiveChange: isPositive,
                          hasData:
                              comparison.hasData || stats.weightChange.hasData,
                          onTap: () =>
                              context.push(RouteNames.studentBodyStatsHistory),
                        );
                      },
                    );
                  },
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
                  isPositiveChange:
                      stats.caloriesChange.change != null &&
                      stats.caloriesChange.change! >= 0,
                  hasData: stats.caloriesChange.hasData,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),

              // Volume PR
              Expanded(
                child: StatCard(
                  title:
                      stats.volumePR.hasData &&
                          stats.volumePR.exerciseName != null
                      ? stats.volumePR.exerciseName!
                      : l10n.volumePR,
                  currentValue:
                      stats.volumePR.hasData &&
                          stats.volumePR.currentWeekVolume != null
                      ? '${stats.volumePR.currentWeekVolume!.toInt()}${stats.volumePR.unit}'
                      : null,
                  previousValue:
                      stats.volumePR.hasData &&
                          stats.volumePR.lastWeekVolume != null
                      ? '${stats.volumePR.lastWeekVolume!.toInt()}${stats.volumePR.unit}'
                      : null,
                  changeText:
                      stats.volumePR.hasData &&
                          stats.volumePR.improvement != null
                      ? (stats.volumePR.improvement! >= 0
                            ? '+${stats.volumePR.improvement!.toInt()}'
                            : '${stats.volumePR.improvement!.toInt()}')
                      : null,
                  isPositiveChange:
                      stats.volumePR.improvement != null &&
                      stats.volumePR.improvement! >= 0,
                  hasData: stats.volumePR.hasData,
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

  /// 构建相对天数的变化文本
  String? _buildRelativeChangeText(
    WeightComparisonResult comparison,
    AppLocalizations l10n,
  ) {
    if (comparison.change == null || comparison.daysSince == null) {
      return null;
    }

    final changeStr = comparison.change! >= 0
        ? '+${comparison.change!.toStringAsFixed(1)}'
        : comparison.change!.toStringAsFixed(1);

    final daysText = comparison.daysSince == 1
        ? l10n.yesterday
        : l10n.daysAgo(comparison.daysSince!);

    return '$changeStr $daysText';
  }

  /// 构建周对比的变化文本
  String? _buildWeeklyChangeText(dynamic weightChange) {
    if (weightChange.change == null) {
      return null;
    }

    return weightChange.change! >= 0
        ? '+${weightChange.change}'
        : '${weightChange.change}';
  }
}
