import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';
import 'package:coach_x/features/student/home/data/models/weight_comparison_model.dart';

/// 体重记录仓库接口
abstract class WeightRepository {
  /// 获取最近 N 条体重记录
  ///
  /// [studentId] 学生ID
  /// [limit] 获取数量，默认10条
  Future<List<BodyMeasurementModel>> getRecentMeasurements({
    required String studentId,
    int limit = 10,
  });

  /// 计算相对天数的体重变化
  ///
  /// [measurements] 体重记录列表（需要至少2条记录才能对比）
  /// 返回对比结果，包含变化量和天数差
  WeightComparisonResult calculateRelativeChange(
    List<BodyMeasurementModel> measurements,
  );
}
