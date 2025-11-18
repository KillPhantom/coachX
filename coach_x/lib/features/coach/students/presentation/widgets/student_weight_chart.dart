import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/student_detail_model.dart';
import '../providers/student_detail_providers.dart';

/// 体重趋势图表组件（使用独立Provider）
class StudentWeightChart extends ConsumerWidget {
  final String studentId;

  const StudentWeightChart({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedRange = ref.watch(selectedTimeRangeProvider);

    // watch独立的weightTrendProvider
    final weightTrendAsync = ref.watch(
      weightTrendProvider((studentId, selectedRange)),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和时间筛选器
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weightTrend,
                style: AppTextStyles.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildPeriodSelector(ref, selectedRange),
            ],
          ),

          const SizedBox(height: 12),

          // 图表（处理异步状态）
          weightTrendAsync.when(
            loading: () => SizedBox(
              height: 180,
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (error, _) =>
                SizedBox(height: 180, child: _buildEmptyChart(l10n)),
            data: (weightTrend) {
              if (weightTrend.hasData) {
                return SizedBox(
                  height: 180,
                  child: _buildLineChart(weightTrend),
                );
              } else {
                return _buildEmptyChart(l10n);
              }
            },
          ),

          const SizedBox(height: 12),

          // 底部统计（处理异步状态）
          weightTrendAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
            data: (weightTrend) => _buildChartStats(l10n, weightTrend),
          ),
        ],
      ),
    );
  }

  /// 构建时间筛选器
  Widget _buildPeriodSelector(WidgetRef ref, String selectedRange) {
    final ranges = ['1M', '3M', '6M', '1Y'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ranges.map((range) {
        final isSelected = range == selectedRange;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            color: isSelected ? AppColors.primaryAction : null,
            borderRadius: BorderRadius.circular(6),
            onPressed: () {
              ref.read(selectedTimeRangeProvider.notifier).state = range;
            },
            child: Text(
              range,
              style: AppTextStyles.caption1.copyWith(
                color: isSelected
                    ? CupertinoColors.white
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建折线图
  Widget _buildLineChart(WeightTrend weightTrend) {
    if (weightTrend.dataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = weightTrend.dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final minY =
        weightTrend.dataPoints
            .map((p) => p.weight)
            .reduce((a, b) => a < b ? a : b) -
        5;
    final maxY =
        weightTrend.dataPoints
            .map((p) => p.weight)
            .reduce((a, b) => a > b ? a : b) +
        5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.dividerLight, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondaryBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.secondaryBlue,
                  strokeWidth: 2,
                  strokeColor: CupertinoColors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.secondaryBlue.withValues(alpha: 0.2),
                  AppColors.secondaryBlue.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dataPoint = weightTrend.dataPoints[spot.x.toInt()];
                return LineTooltipItem(
                  '${dataPoint.weight.toStringAsFixed(1)} kg\n${_formatDate(dataPoint.date)}',
                  AppTextStyles.caption1.copyWith(color: CupertinoColors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// 构建空图表占位
  Widget _buildEmptyChart(AppLocalizations l10n) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No weight data available',
        style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  /// 构建图表底部统计
  Widget _buildChartStats(AppLocalizations l10n, WeightTrend weightTrend) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: weightTrend.starting.toStringAsFixed(1),
            label: l10n.starting,
          ),
          _buildStatItem(
            value: weightTrend.current.toStringAsFixed(1),
            label: l10n.current,
          ),
          _buildStatItem(
            value:
                '${weightTrend.change >= 0 ? '+' : ''}${weightTrend.change.toStringAsFixed(1)}',
            label: l10n.change,
            isChange: true,
          ),
          _buildStatItem(
            value: weightTrend.target.toStringAsFixed(1),
            label: l10n.target,
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required String value,
    required String label,
    bool isChange = false,
  }) {
    Color valueColor = AppColors.primaryText;
    if (isChange && value != '0.0') {
      valueColor = value.startsWith('+')
          ? CupertinoColors.systemRed
          : CupertinoColors.systemGreen;
    }

    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.subhead.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 格式化日期
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}';
    } catch (e) {
      return dateStr;
    }
  }
}
