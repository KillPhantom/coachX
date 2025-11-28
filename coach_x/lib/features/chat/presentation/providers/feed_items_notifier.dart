import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/training_feed_item.dart';
import '../../data/models/feed_item_type.dart';
import '../../data/repositories/training_feed_repository.dart';

/// Feed Items 状态
class FeedItemsState {
  final List<TrainingFeedItem> items;
  final bool isLoading;
  final String? error;

  const FeedItemsState({
    required this.items,
    this.isLoading = false,
    this.error,
  });

  FeedItemsState copyWith({
    List<TrainingFeedItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FeedItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 获取未批阅的 Feed Items 数量（排除 Completion Item）
  int get pendingCount {
    return items
        .where((item) => !item.type.isCompletion && !item.isReviewed)
        .length;
  }

  /// 获取总的内容 Feed Items 数量（排除 Completion Item）
  int get totalContentCount {
    return items.where((item) => item.type.isContentItem).length;
  }

  /// 获取已批阅的 Feed Items 数量
  int get reviewedCount {
    return totalContentCount - pendingCount;
  }

  /// 是否所有内容都已批阅
  bool get isAllReviewed {
    return totalContentCount > 0 && pendingCount == 0;
  }
}

/// Feed Items Notifier
class FeedItemsNotifier extends StateNotifier<FeedItemsState> {
  final TrainingFeedRepository _repository;
  final String _dailyTrainingId;

  FeedItemsNotifier(this._repository, this._dailyTrainingId)
      : super(const FeedItemsState(items: [])) {
    _loadFeedItems();
  }

  /// 加载 Feed Items
  Future<void> _loadFeedItems() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final items = await _repository.generateFeedItems(_dailyTrainingId);

      AppLogger.info(
        '📊 [FeedItemsNotifier] Loaded ${items.length} feed items',
      );

      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [FeedItemsNotifier] Failed to load feed items',
        e,
        stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 标记 Feed Item 为已批阅
  Future<void> markItemReviewed(String feedItemId) async {
    try {
      // 查找对应的 Feed Item
      final itemIndex = state.items.indexWhere((item) => item.id == feedItemId);

      if (itemIndex == -1) {
        AppLogger.warning(
          '⚠️ [FeedItemsNotifier] Feed item not found: $feedItemId',
        );
        return;
      }

      final item = state.items[itemIndex];

      // 如果已经批阅过，跳过
      if (item.isReviewed) {
        AppLogger.info(
          '✅ [FeedItemsNotifier] Feed item already reviewed: $feedItemId',
        );
        return;
      }

      // 更新状态：标记为已批阅
      final updatedItems = List<TrainingFeedItem>.from(state.items);
      updatedItems[itemIndex] = item.copyWith(isReviewed: true);

      state = state.copyWith(items: updatedItems);

      AppLogger.info(
        '✅ [FeedItemsNotifier] Marked feed item as reviewed: $feedItemId (${state.reviewedCount}/${state.totalContentCount})',
      );

      // 检查是否所有 Feed Items 已批阅
      await _checkAndUpdateCompletion();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [FeedItemsNotifier] Failed to mark item reviewed: $feedItemId',
        e,
        stackTrace,
      );
    }
  }

  /// 检查并更新完成状态
  Future<void> _checkAndUpdateCompletion() async {
    if (!state.isAllReviewed) {
      AppLogger.info(
        '🔍 [FeedItemsNotifier] Not all items reviewed yet (${state.reviewedCount}/${state.totalContentCount})',
      );
      return;
    }

    try {
      // 所有 Feed Items 已批阅 → 更新 Firestore
      await FirebaseFirestore.instance
          .collection('dailyTrainings')
          .doc(_dailyTrainingId)
          .update({'isReviewed': true});

      AppLogger.info(
        '🎉 [FeedItemsNotifier] All feed items reviewed! Updated dailyTraining.isReviewed = true',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [FeedItemsNotifier] Failed to update dailyTraining.isReviewed',
        e,
        stackTrace,
      );
    }
  }

  /// 刷新 Feed Items
  Future<void> refresh() async {
    await _loadFeedItems();
  }
}
