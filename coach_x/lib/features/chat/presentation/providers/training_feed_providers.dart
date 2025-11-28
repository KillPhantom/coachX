import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/training_feed_repository.dart';
import '../../data/repositories/training_feed_repository_impl.dart';
import '../../data/models/training_feed_item.dart';
import '../../../student/home/data/models/daily_training_model.dart';
import 'feed_items_notifier.dart';

/// Repository Provider
final trainingFeedRepositoryProvider = Provider<TrainingFeedRepository>((ref) {
  return TrainingFeedRepositoryImpl();
});

/// Feed Items Notifier Provider
final feedItemsNotifierProvider = StateNotifierProvider.family<
    FeedItemsNotifier,
    FeedItemsState,
    String>((ref, dailyTrainingId) {
  final repository = ref.watch(trainingFeedRepositoryProvider);
  return FeedItemsNotifier(repository, dailyTrainingId);
});

/// Feed Items Provider (computed from notifier state)
final feedItemsProvider = Provider.family<List<TrainingFeedItem>, String>(
  (ref, dailyTrainingId) {
    final state = ref.watch(feedItemsNotifierProvider(dailyTrainingId));
    return state.items;
  },
);

/// 当前 Feed 索引 Provider
final currentFeedIndexProvider = StateProvider<int>((ref) => 0);

/// 评论区打开状态 Provider
final isCommentSheetOpenProvider = StateProvider<bool>((ref) => false);

/// 详情弹窗打开状态 Provider
final isDetailSheetOpenProvider = StateProvider<bool>((ref) => false);

/// 选中的关键帧时间戳 Provider
final selectedKeyframeTimestampProvider = StateProvider<double?>((ref) => null);

/// Daily Training Stream Provider
final dailyTrainingStreamProvider =
    StreamProvider.family<DailyTrainingModel, String>((ref, dailyTrainingId) {
      final repository = ref.watch(trainingFeedRepositoryProvider);
      return repository.watchDailyTraining(dailyTrainingId);
    });
