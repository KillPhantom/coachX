import '../models/training_review_list_item_model.dart';

/// 训练审核Repository接口
abstract class TrainingReviewRepository {
  /// 监听教练的训练审核列表
  ///
  /// [coachId] 教练ID
  /// 返回训练审核列表的Stream
  Stream<List<TrainingReviewListItemModel>> watchTrainingReviews(
    String coachId,
  );
}
