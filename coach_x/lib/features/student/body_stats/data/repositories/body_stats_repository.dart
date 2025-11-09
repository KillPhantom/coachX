import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';

/// 身体测量数据仓库接口
abstract class BodyStatsRepository {
  /// 保存身体测量记录
  ///
  /// 参数:
  /// - [recordDate]: 记录日期 (ISO 8601格式)
  /// - [weight]: 体重值
  /// - [weightUnit]: 体重单位 ('kg' 或 'lbs')
  /// - [bodyFat]: 体脂率 (可选)
  /// - [photos]: 照片URL列表 (已上传到Firebase Storage)
  ///
  /// 返回: 新创建的测量记录
  Future<BodyMeasurementModel> saveMeasurement({
    required String recordDate,
    required double weight,
    required String weightUnit,
    double? bodyFat,
    List<String> photos = const [],
  });

  /// 获取身体测量历史记录
  ///
  /// 参数:
  /// - [startDate]: 开始日期 (可选)
  /// - [endDate]: 结束日期 (可选)
  ///
  /// 返回: 测量记录列表（按日期降序排序）
  Future<List<BodyMeasurementModel>> fetchMeasurements({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 更新身体测量记录
  ///
  /// 参数:
  /// - [measurementId]: 记录ID
  /// - [weight]: 体重值 (可选)
  /// - [weightUnit]: 体重单位 (可选)
  /// - [bodyFat]: 体脂率 (可选)
  /// - [photos]: 照片URL列表 (可选)
  ///
  /// 返回: 更新后的测量记录
  Future<BodyMeasurementModel> updateMeasurement({
    required String measurementId,
    double? weight,
    String? weightUnit,
    double? bodyFat,
    List<String>? photos,
  });

  /// 删除身体测量记录
  ///
  /// 参数:
  /// - [measurementId]: 记录ID
  Future<void> deleteMeasurement(String measurementId);

  /// 上传照片到Firebase Storage
  ///
  /// 参数:
  /// - [localPath]: 本地文件路径
  ///
  /// 返回: Firebase Storage URL
  Future<String> uploadPhoto(String localPath);
}
