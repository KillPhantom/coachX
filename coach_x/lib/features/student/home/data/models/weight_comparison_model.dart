/// 体重对比结果模型
///
/// 用于存储最近两条体重记录的对比信息
class WeightComparisonResult {
  /// 当前体重
  final double? currentWeight;

  /// 上次体重
  final double? previousWeight;

  /// 体重变化量
  final double? change;

  /// 距离上次记录的天数
  final int? daysSince;

  /// 当前记录日期
  final DateTime? currentDate;

  /// 上次记录日期
  final DateTime? previousDate;

  /// 是否有数据
  final bool hasData;

  const WeightComparisonResult({
    this.currentWeight,
    this.previousWeight,
    this.change,
    this.daysSince,
    this.currentDate,
    this.previousDate,
    required this.hasData,
  });

  /// 创建空结果
  factory WeightComparisonResult.empty() {
    return const WeightComparisonResult(hasData: false);
  }

  /// 创建单条记录结果（无对比）
  factory WeightComparisonResult.single({
    required double weight,
    required DateTime date,
  }) {
    return WeightComparisonResult(
      currentWeight: weight,
      currentDate: date,
      hasData: true,
    );
  }

  @override
  String toString() {
    return 'WeightComparisonResult('
        'current: $currentWeight, '
        'previous: $previousWeight, '
        'change: $change, '
        'daysSince: $daysSince, '
        'hasData: $hasData)';
  }
}
