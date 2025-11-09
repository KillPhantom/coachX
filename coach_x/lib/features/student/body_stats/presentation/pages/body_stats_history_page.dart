import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/student/body_stats/data/models/time_range_enum.dart';
import 'package:coach_x/features/student/body_stats/presentation/providers/body_stats_providers.dart';
import 'package:coach_x/features/student/body_stats/presentation/widgets/weight_trend_chart.dart';
import 'package:coach_x/features/student/body_stats/presentation/widgets/measurement_record_card.dart';

/// 身体数据历史页面
///
/// 显示体重趋势图表和历史记录列表
class BodyStatsHistoryPage extends ConsumerWidget {
  const BodyStatsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(bodyStatsHistoryProvider);
    final displayUnit = ref.watch(userWeightUnitProvider).value ?? 'kg';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      child: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildNavigationBar(context, l10n),

            // 内容区域
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 20),
                    )
                  : !state.hasData
                      ? _buildEmptyState(l10n)
                      : _buildContent(context, ref, l10n, state, displayUnit),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建导航栏
  Widget _buildNavigationBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            child: const Icon(
              CupertinoIcons.back,
              color: AppColors.primaryText,
              size: 28,
            ),
          ),

          // 标题
          Text(
            l10n.bodyStatsHistory,
            style: AppTextStyles.title3,
          ),

          // 占位（保持对称）
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            l10n.noBodyStatsData,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    dynamic state,
    String displayUnit,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 下拉刷新
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await ref.read(bodyStatsHistoryProvider.notifier).refresh();
          },
        ),
          // 时间范围选择器
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: _buildTimeRangeSelector(context, ref, l10n, state),
            ),
          ),

          // 图表区域
          if (state.hasFilteredData)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      child: Text(
                        l10n.weightTrend,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    WeightTrendChart(
                      measurements: state.filteredMeasurements,
                      displayUnit: displayUnit,
                    ),
                  ],
                ),
              ),
            ),

          // 历史记录标题
          if (state.hasFilteredData)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingM,
                  AppDimensions.spacingL,
                  AppDimensions.spacingM,
                  AppDimensions.spacingS,
                ),
                child: Text(
                  l10n.history,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // 历史记录列表
          if (state.hasFilteredData)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final measurement = state.filteredMeasurements[index];
                    return MeasurementRecordCard(
                      measurement: measurement,
                      displayUnit: displayUnit,
                    );
                  },
                  childCount: state.filteredMeasurements.length,
                ),
              ),
            ),

          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.spacingXL),
          ),
        ],
    );
  }

  /// 构建时间范围选择器
  Widget _buildTimeRangeSelector(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    dynamic state,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: CupertinoSegmentedControl<TimeRange>(
        groupValue: state.selectedTimeRange,
        onValueChanged: (TimeRange value) {
          ref.read(bodyStatsHistoryProvider.notifier).setTimeRange(value);
        },
        children: {
          TimeRange.days14: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            child: Text(
              l10n.last14Days,
              style: AppTextStyles.callout.copyWith(
                color: state.selectedTimeRange == TimeRange.days14
                    ? AppColors.primaryText
                    : AppColors.textSecondary,
              ),
            ),
          ),
          TimeRange.days30: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            child: Text(
              l10n.last30Days,
              style: AppTextStyles.callout.copyWith(
                color: state.selectedTimeRange == TimeRange.days30
                    ? AppColors.primaryText
                    : AppColors.textSecondary,
              ),
            ),
          ),
          TimeRange.days90: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            child: Text(
              l10n.last90Days,
              style: AppTextStyles.callout.copyWith(
                color: state.selectedTimeRange == TimeRange.days90
                    ? AppColors.primaryText
                    : AppColors.textSecondary,
              ),
            ),
          ),
        },
        selectedColor: AppColors.primaryColor,
        unselectedColor: CupertinoColors.white,
        borderColor: AppColors.dividerLight,
      ),
    );
  }
}
