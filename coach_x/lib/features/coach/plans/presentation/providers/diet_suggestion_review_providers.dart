import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/diet_suggestion_review_notifier.dart';

// ==================== 主状态 Provider ====================

/// Diet Plan Review Mode 开关
/// 注意：不使用 autoDispose，避免在组件销毁时清理导致其他监听者访问已销毁的状态
final isDietReviewModeProvider = StateProvider<bool>((ref) => false);

/// Diet Plan Review State Notifier Provider
/// 注意：不使用 autoDispose，避免生命周期冲突
final dietSuggestionReviewNotifierProvider =
    StateNotifierProvider<
      DietSuggestionReviewNotifier,
      DietSuggestionReviewState?
    >((ref) {
      return DietSuggestionReviewNotifier();
    });

// ==================== 计算 Providers ====================
// 注意：这些派生 providers 也不使用 autoDispose，与主 provider 保持一致
// 避免生命周期不匹配导致的访问错误

/// 当前正在查看的修改
final currentDietChangeProvider = Provider<DietPlanChange?>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.currentChange;
});

/// 进度文本 (e.g., "3/10")
final dietReviewProgressProvider = Provider<String?>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.progressText;
});

/// 是否有下一个修改
final hasNextDietChangeProvider = Provider<bool>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.hasNext ?? false;
});

/// 是否有上一个修改
final hasPreviousDietChangeProvider = Provider<bool>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.hasPrevious ?? false;
});

/// 是否已完成所有审核
final isDietReviewCompleteProvider = Provider<bool>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.isComplete ?? false;
});

/// 已接受的数量
final acceptedDietCountProvider = Provider<int>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.acceptedCount ?? 0;
});

/// 已拒绝的数量
final rejectedDietCountProvider = Provider<int>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.rejectedCount ?? 0;
});

/// 剩余待处理的数量
final remainingDietCountProvider = Provider<int>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.remainingCount ?? 0;
});

/// 是否正在显示全部改动
final isShowingAllDietChangesProvider = Provider<bool>((ref) {
  final state = ref.watch(dietSuggestionReviewNotifierProvider);
  return state?.isShowingAllChanges ?? false;
});
