import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_stats_history_state.dart';
import 'package:coach_x/features/student/body_stats/data/models/time_range_enum.dart';
import 'package:coach_x/features/student/body_stats/data/repositories/body_stats_repository.dart';

/// Body Stats History Notifier
///
/// 管理身体数据历史页面的状态和逻辑
class BodyStatsHistoryNotifier extends StateNotifier<BodyStatsHistoryState> {
  final BodyStatsRepository _repository;

  BodyStatsHistoryNotifier({required BodyStatsRepository repository})
    : _repository = repository,
      super(BodyStatsHistoryState.initial()) {
    // 初始化时加载数据
    loadMeasurements();
  }

  /// 加载测量记录
  ///
  /// 根据选定的时间范围加载数据
  Future<void> loadMeasurements() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      AppLogger.info('📥 加载身体测量记录...');

      // 计算日期范围（始终获取最大范围 90 天的数据）
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90));

      // 获取记录
      final measurements = await _repository.fetchMeasurements(
        startDate: startDate,
        endDate: now,
      );

      state = state.copyWith(measurements: measurements, isLoading: false);

      AppLogger.info('✅ 加载到 ${measurements.length} 条测量记录');
    } catch (e, stack) {
      AppLogger.error('❌ 加载测量记录失败', e, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load measurements: ${e.toString()}',
      );
    }
  }

  /// 设置时间范围
  ///
  /// [range] 时间范围
  void setTimeRange(TimeRange range) {
    if (state.selectedTimeRange == range) {
      AppLogger.info('⏰ 时间范围未改变: $range');
      return;
    }

    AppLogger.info('⏰ 切换时间范围: ${state.selectedTimeRange} → $range');

    // 只更新时间范围，filteredMeasurements getter 会自动过滤数据
    state = state.copyWith(selectedTimeRange: range);
  }

  /// 删除记录
  ///
  /// [measurementId] 记录ID
  Future<bool> deleteRecord(String measurementId) async {
    try {
      AppLogger.info('🗑️ 删除测量记录: $measurementId');

      // 调用 repository 删除
      await _repository.deleteMeasurement(measurementId);

      // 从列表中移除
      final updatedMeasurements = state.measurements
          .where((m) => m.id != measurementId)
          .toList();

      state = state.copyWith(
        measurements: updatedMeasurements,
        clearError: true,
      );

      AppLogger.info('✅ 测量记录删除成功: $measurementId');
      return true;
    } catch (e, stack) {
      AppLogger.error('❌ 删除测量记录失败', e, stack);
      state = state.copyWith(
        errorMessage: 'Failed to delete record: ${e.toString()}',
      );
      return false;
    }
  }

  /// 刷新列表
  ///
  /// 重新加载所有数据
  Future<void> refresh() async {
    AppLogger.info('🔄 刷新测量记录列表');
    await loadMeasurements();
  }

  /// 清除错误消息
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
