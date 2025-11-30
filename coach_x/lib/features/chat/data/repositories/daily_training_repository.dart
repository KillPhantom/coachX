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

  /// 添加新的关键帧
  ///
  /// [dailyTrainingId] 训练记录ID
  /// [exerciseTemplateId] 动作模版ID
  /// [videoIndex] 视频索引
  /// [imageUrl] 图片 URL
  /// [localPath] 本地路径（可选）
  /// [timestamp] 时间戳
  Future<void> addKeyframe(
    String dailyTrainingId,
    String exerciseTemplateId,
    int videoIndex,
    String imageUrl,
    String? localPath,
    double timestamp,
  );

  /// 获取指定学生在日期范围内的训练记录
  ///
  /// [studentId] 学生ID
  /// [startDate] 开始日期（包含），使用本地日期
  /// [endDate] 结束日期（包含），使用本地日期
  Future<List<DailyTrainingModel>> getTrainingsInRange({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
