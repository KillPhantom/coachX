import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';
import 'package:intl/intl.dart';

/// 体重趋势图表
///
/// 使用 fl_chart 显示体重变化趋势
class WeightTrendChart extends StatelessWidget {
  /// 测量记录列表
  final List<BodyMeasurementModel> measurements;

  /// 显示单位
  final String displayUnit;

  const WeightTrendChart({
    super.key,
    required this.measurements,
    required this.displayUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No data to display',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    // 按日期排序（升序）
    final sortedMeasurements = List<BodyMeasurementModel>.from(measurements)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    // 准备图表数据
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedMeasurements.length; i++) {
      final measurement = sortedMeasurements[i];
      final weight = measurement.getWeightInUnit(displayUnit);
      spots.add(FlSpot(i.toDouble(), weight));
    }

    // 计算Y轴范围
    final weights = spots.map((s) => s.y).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final yMin = (minWeight - range * 0.1).floorToDouble();
    final yMax = (maxWeight + range * 0.1).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppColors.dividerLight, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedMeasurements.length) {
                    return const SizedBox.shrink();
                  }

                  final measurement = sortedMeasurements[index];
                  final date = DateTime.parse(measurement.recordDate);
                  final dateStr = DateFormat('M/d').format(date);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (sortedMeasurements.length - 1).toDouble(),
          minY: yMin,
          maxY: yMax,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.primaryColor,
                    strokeWidth: 2,
                    strokeColor: AppColors.backgroundWhite,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= sortedMeasurements.length) {
                    return null;
                  }

                  final measurement = sortedMeasurements[index];
                  final date = DateTime.parse(measurement.recordDate);
                  final dateStr = DateFormat('MMM d').format(date);

                  return LineTooltipItem(
                    '$dateStr\n${spot.y.toStringAsFixed(1)} $displayUnit',
                    AppTextStyles.caption1.copyWith(
                      color: CupertinoColors.white,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
