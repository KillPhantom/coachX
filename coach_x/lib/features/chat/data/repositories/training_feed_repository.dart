import '../models/training_feed_item.dart';
import '../../../student/home/data/models/daily_training_model.dart';

abstract class TrainingFeedRepository {
  /// 生成 Feed Items 列表
  Future<List<TrainingFeedItem>> generateFeedItems(String dailyTrainingId);

  /// 标记 Feed Item 为已批阅
  Future<void> markFeedItemReviewed(String dailyTrainingId, String feedItemId);

  /// 更新视频的批阅状态
  Future<void> updateVideoReviewStatus({
    required String dailyTrainingId,
    required String exerciseTemplateId,
    required int videoIndex,
    required bool isReviewed,
  });

  /// 实时监听训练数据变化
  Stream<DailyTrainingModel> watchDailyTraining(String dailyTrainingId);

  /// 检查所有 Feed Items 是否已批阅，自动更新 dailyTraining.isReviewed
  Future<void> checkAndUpdateCompletionStatus(String dailyTrainingId);
}
