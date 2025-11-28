import '../models/training_feed_item.dart';
import '../../../student/home/data/models/daily_training_model.dart';

abstract class TrainingFeedRepository {
  /// 生成 Feed Items 列表
  Future<List<TrainingFeedItem>> generateFeedItems(String dailyTrainingId);

  /// 实时监听训练数据变化
  Stream<DailyTrainingModel> watchDailyTraining(String dailyTrainingId);
}
