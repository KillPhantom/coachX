import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/suggestion_review_notifier.dart';

// ==================== 主状态 Provider ====================

/// Review Mode 开关
/// 注意：不使用 autoDispose，避免在组件销毁时清理导致其他监听者访问已销毁的状态
final isReviewModeProvider = StateProvider<bool>((ref) => false);

/// Review State Notifier Provider
/// 注意：不使用 autoDispose，避免生命周期冲突
final suggestionReviewNotifierProvider =
    StateNotifierProvider<SuggestionReviewNotifier, SuggestionReviewState?>(
  (ref) {
    return SuggestionReviewNotifier();
  },
);

// ==================== 计算 Providers ====================
// 注意：这些派生 providers 也不使用 autoDispose，与主 provider 保持一致
// 避免生命周期不匹配导致的访问错误

/// 当前正在查看的修改
final currentChangeProvider = Provider<PlanChange?>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.currentChange;
});

/// 进度文本 (e.g., "3/10")
final reviewProgressProvider = Provider<String?>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.progressText;
});

/// 是否有下一个修改
final hasNextChangeProvider = Provider<bool>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.hasNext ?? false;
});

/// 是否有上一个修改
final hasPreviousChangeProvider = Provider<bool>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.hasPrevious ?? false;
});

/// 是否已完成所有审核
final isReviewCompleteProvider = Provider<bool>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.isComplete ?? false;
});

/// 已接受的数量
final acceptedCountProvider = Provider<int>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.acceptedCount ?? 0;
});

/// 已拒绝的数量
final rejectedCountProvider = Provider<int>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.rejectedCount ?? 0;
});

/// 剩余待处理的数量
final remainingCountProvider = Provider<int>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.remainingCount ?? 0;
});

/// 是否正在显示全部改动
final isShowingAllChangesProvider = Provider<bool>((ref) {
  final state = ref.watch(suggestionReviewNotifierProvider);
  return state?.isShowingAllChanges ?? false;
});
