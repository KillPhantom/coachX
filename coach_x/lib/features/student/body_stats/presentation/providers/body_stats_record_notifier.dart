import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_stats_state.dart';
import 'package:coach_x/features/student/body_stats/data/repositories/body_stats_repository.dart';

/// Body Stats Record Notifier
///
/// 管理身体数据记录页面的状态和逻辑
class BodyStatsRecordNotifier extends StateNotifier<BodyStatsState> {
  final BodyStatsRepository _repository;

  BodyStatsRecordNotifier({
    required BodyStatsRepository repository,
    required String initialWeightUnit,
  })  : _repository = repository,
        super(BodyStatsState.initial(weightUnit: initialWeightUnit));

  /// 添加照片
  ///
  /// [localPath] 本地文件路径
  void addPhoto(String localPath) {
    if (state.isPhotosLimitReached) {
      AppLogger.warning('⚠️ 照片数量已达上限（3张）');
      state = state.copyWith(
        errorMessage: 'Maximum 3 photos allowed',
      );
      return;
    }

    final updatedPhotos = List<String>.from(state.photos)..add(localPath);
    state = state.copyWith(
      photos: updatedPhotos,
      clearError: true,
    );

    AppLogger.info('📸 添加照片: $localPath, 当前数量: ${updatedPhotos.length}');
  }

  /// 移除照片
  ///
  /// [index] 照片索引
  void removePhoto(int index) {
    if (index < 0 || index >= state.photos.length) {
      AppLogger.warning('⚠️ 无效的照片索引: $index');
      return;
    }

    final updatedPhotos = List<String>.from(state.photos)..removeAt(index);
    state = state.copyWith(
      photos: updatedPhotos,
      clearError: true,
    );

    AppLogger.info('🗑️ 移除照片: 索引 $index, 剩余数量: ${updatedPhotos.length}');
  }

  /// 设置体重
  ///
  /// [weight] 体重值
  void setWeight(double weight) {
    state = state.copyWith(
      weight: weight,
      clearError: true,
    );

    AppLogger.info('⚖️ 设置体重: $weight${state.weightUnit}');
  }

  /// 设置体重单位
  ///
  /// [unit] 体重单位 ('kg' 或 'lbs')
  void setWeightUnit(String unit) {
    if (unit != 'kg' && unit != 'lbs') {
      AppLogger.warning('⚠️ 无效的体重单位: $unit');
      return;
    }

    state = state.copyWith(
      weightUnit: unit,
      clearError: true,
    );

    AppLogger.info('📏 设置体重单位: $unit');
  }

  /// 设置体脂率
  ///
  /// [bodyFat] 体脂率（可为 null）
  void setBodyFat(double? bodyFat) {
    state = state.copyWith(
      bodyFat: bodyFat,
      clearError: true,
    );

    AppLogger.info('💪 设置体脂率: $bodyFat%');
  }

  /// 保存记录
  ///
  /// 返回是否保存成功
  Future<bool> saveRecord() async {
    // 验证数据
    if (!state.isValid) {
      AppLogger.warning('⚠️ 数据验证失败');
      state = state.copyWith(
        errorMessage: 'Please enter valid weight',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      AppLogger.info('💾 开始保存身体数据记录...');

      // 1. 上传照片
      final List<String> photoUrls = [];
      for (final localPath in state.photos) {
        try {
          final url = await _repository.uploadPhoto(localPath);
          photoUrls.add(url);
          AppLogger.info('✅ 照片上传成功: $url');
        } catch (e) {
          AppLogger.error('❌ 照片上传失败: $localPath', e);
          // 继续上传其他照片
        }
      }

      // 2. 保存记录
      final recordDate = DateTime.now().toIso8601String().split('T')[0];
      final measurement = await _repository.saveMeasurement(
        recordDate: recordDate,
        weight: state.weight!,
        weightUnit: state.weightUnit,
        bodyFat: state.bodyFat,
        photos: photoUrls,
      );

      AppLogger.info('✅ 身体数据记录保存成功: ${measurement.id}');

      // 3. 重置状态
      state = BodyStatsState.initial(weightUnit: state.weightUnit);

      return true;
    } catch (e, stack) {
      AppLogger.error('❌ 保存身体数据记录失败', e, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save record: ${e.toString()}',
      );
      return false;
    }
  }

  /// 重置状态
  void reset() {
    state = BodyStatsState.initial(weightUnit: state.weightUnit);
    AppLogger.info('🔄 重置记录状态');
  }

  /// 清除错误消息
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
