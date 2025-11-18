import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';

/// Daily Training Repository 抽象接口
abstract class DailyTrainingRepository {
  /// 获取单个 Daily Training 记录
  ///
  /// [dailyTrainingId] 训练记录ID
  /// 返回训练模型，不存在返回null
  Future<DailyTrainingModel?> getDailyTraining(String dailyTrainingId);

  /// 监听单个 Daily Training 记录的实时更新
  ///
  /// [dailyTrainingId] 训练记录ID
  /// 返回训练模型的Stream，不存在时emit null
  Stream<DailyTrainingModel?> watchDailyTraining(String dailyTrainingId);

  /// 标记训练记录为已审核
  ///
  /// [dailyTrainingId] 训练记录ID
  Future<void> markAsReviewed(String dailyTrainingId);

  /// 更新指定关键帧的 URL 和 localPath（保留 timestamp）
  ///
  /// [dailyTrainingId] 训练记录ID
  /// [exerciseIndex] 动作索引
  /// [keyframeIndex] 关键帧索引（在 keyframes 数组中的位置）
  /// [newUrl] 新的图片 URL
  /// [newLocalPath] 新的本地路径（可选）
  Future<void> updateKeyframe(
    String dailyTrainingId,
    int exerciseIndex,
    int keyframeIndex,
    String newUrl,
    String? newLocalPath,
  );
}
