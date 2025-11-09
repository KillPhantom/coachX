import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';
import 'package:coach_x/features/student/body_stats/data/models/time_range_enum.dart';

/// 身体数据历史页面状态
///
/// 用于管理历史页面的状态
class BodyStatsHistoryState {
  /// 测量记录列表
  final List<BodyMeasurementModel> measurements;

  /// 选定的时间范围
  final TimeRange selectedTimeRange;

  /// 是否正在加载
  final bool isLoading;

  /// 错误消息
  final String? errorMessage;

  const BodyStatsHistoryState({
    this.measurements = const [],
    this.selectedTimeRange = TimeRange.days14,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 复制并修改部分字段
  BodyStatsHistoryState copyWith({
    List<BodyMeasurementModel>? measurements,
    TimeRange? selectedTimeRange,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BodyStatsHistoryState(
      measurements: measurements ?? this.measurements,
      selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// 创建初始状态
  factory BodyStatsHistoryState.initial() {
    return const BodyStatsHistoryState(
      measurements: [],
      selectedTimeRange: TimeRange.days14,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// 创建加载状态
  factory BodyStatsHistoryState.loading() {
    return const BodyStatsHistoryState(
      measurements: [],
      selectedTimeRange: TimeRange.days14,
      isLoading: true,
      errorMessage: null,
    );
  }

  /// 获取过滤后的测量数据（根据时间范围）
  List<BodyMeasurementModel> get filteredMeasurements {
    if (measurements.isEmpty) return [];

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: selectedTimeRange.days));

    return measurements.where((measurement) {
      try {
        final recordDate = DateTime.parse(measurement.recordDate);
        return recordDate.isAfter(cutoffDate) ||
            recordDate.isAtSameMomentAs(cutoffDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// 是否有数据
  bool get hasData => measurements.isNotEmpty;

  /// 是否有可显示的数据（根据当前时间范围）
  bool get hasFilteredData => filteredMeasurements.isNotEmpty;

  @override
  String toString() {
    return 'BodyStatsHistoryState(measurements: ${measurements.length}, range: $selectedTimeRange, isLoading: $isLoading, error: $errorMessage)';
  }
}
