import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';

/// 今日训练记录Repository接口
abstract class TodayTrainingRepository {
  /// 监听今日训练记录
  ///
  /// [userId] 用户ID
  /// [date] 日期 (格式: "yyyy-MM-dd")
  /// 返回今日训练记录的实时流
  Stream<DailyTrainingModel?> watchTodayTraining(String userId, String date);
}
