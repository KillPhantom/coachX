import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';

/// Diet Plan Suggestion Review Mode 状态
class DietSuggestionReviewState {
  final List<DietPlanChange> allChanges;        // 所有待确认的修改
  final int currentIndex;                        // 当前查看的索引
  final Set<String> acceptedIds;                // 已接受的修改 ID
  final Set<String> rejectedIds;                // 已拒绝的修改 ID
  final DietPlanModel originalPlan;             // 原始计划
  final DietPlanModel workingPlan;              // 工作中的计划（逐步应用修改）
  final bool isShowingAllChanges;               // 是否展开显示全部改动

  const DietSuggestionReviewState({
    required this.allChanges,
    required this.currentIndex,
    required this.acceptedIds,
    required this.rejectedIds,
    required this.originalPlan,
    required this.workingPlan,
    this.isShowingAllChanges = false,
  });

  /// 初始状态
  factory DietSuggestionReviewState.initial({
    required List<DietPlanChange> changes,
    required DietPlanModel originalPlan,
  }) {
    return DietSuggestionReviewState(
      allChanges: changes,
      currentIndex: 0,
      acceptedIds: const {},
      rejectedIds: const {},
      originalPlan: originalPlan,
      workingPlan: originalPlan,
    );
  }

  /// 当前正在查看的修改
  DietPlanChange? get currentChange {
    if (currentIndex >= 0 && currentIndex < allChanges.length) {
      return allChanges[currentIndex];
    }
    return null;
  }

  /// 是否有下一个
  bool get hasNext => currentIndex < allChanges.length - 1;

  /// 是否有上一个
  bool get hasPrevious => currentIndex > 0;

  /// 已接受的数量
  int get acceptedCount => acceptedIds.length;

  /// 已拒绝的数量
  int get rejectedCount => rejectedIds.length;

  /// 剩余待处理的数量
  int get remainingCount {
    final processed = acceptedIds.length + rejectedIds.length;
    return allChanges.length - processed;
  }

  /// 是否已完成所有审核
  bool get isComplete => currentIndex >= allChanges.length;

  /// 进度文本 (e.g., "3/10")
  String get progressText => '${currentIndex + 1}/${allChanges.length}';

  /// 复制并修改
  DietSuggestionReviewState copyWith({
    List<DietPlanChange>? allChanges,
    int? currentIndex,
    Set<String>? acceptedIds,
    Set<String>? rejectedIds,
    DietPlanModel? originalPlan,
    DietPlanModel? workingPlan,
    bool? isShowingAllChanges,
  }) {
    return DietSuggestionReviewState(
      allChanges: allChanges ?? this.allChanges,
      currentIndex: currentIndex ?? this.currentIndex,
      acceptedIds: acceptedIds ?? this.acceptedIds,
      rejectedIds: rejectedIds ?? this.rejectedIds,
      originalPlan: originalPlan ?? this.originalPlan,
      workingPlan: workingPlan ?? this.workingPlan,
      isShowingAllChanges: isShowingAllChanges ?? this.isShowingAllChanges,
    );
  }

  /// 接受当前修改并移动到下一个
  DietSuggestionReviewState acceptCurrentAndMoveNext(DietPlanModel updatedPlan) {
    if (currentChange == null) return this;

    return copyWith(
      acceptedIds: {...acceptedIds, currentChange!.id},
      workingPlan: updatedPlan,
      currentIndex: currentIndex + 1,
    );
  }

  /// 拒绝当前修改并移动到下一个
  DietSuggestionReviewState rejectCurrentAndMoveNext() {
    if (currentChange == null) return this;

    return copyWith(
      rejectedIds: {...rejectedIds, currentChange!.id},
      currentIndex: currentIndex + 1,
    );
  }

  /// 移动到下一个（不做任何决策）
  DietSuggestionReviewState moveNext() {
    if (!hasNext) return this;
    return copyWith(currentIndex: currentIndex + 1);
  }

  /// 移动到上一个
  DietSuggestionReviewState movePrevious() {
    if (!hasPrevious) return this;
    return copyWith(currentIndex: currentIndex - 1);
  }

  /// 标记所有剩余为已接受
  DietSuggestionReviewState acceptAllRemaining() {
    final allIds = allChanges.map((c) => c.id).toSet();
    return copyWith(
      acceptedIds: allIds,
      currentIndex: allChanges.length, // 移动到结束
    );
  }

  /// 标记所有剩余为已拒绝
  DietSuggestionReviewState rejectAllRemaining() {
    final remainingIds = allChanges
        .where((c) => !acceptedIds.contains(c.id))
        .map((c) => c.id)
        .toSet();
    return copyWith(
      rejectedIds: {...rejectedIds, ...remainingIds},
      currentIndex: allChanges.length, // 移动到结束
    );
  }

  @override
  String toString() {
    return 'DietSuggestionReviewState(currentIndex: $currentIndex/${allChanges.length}, accepted: $acceptedCount, rejected: $rejectedCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DietSuggestionReviewState &&
        other.allChanges == allChanges &&
        other.currentIndex == currentIndex &&
        other.acceptedIds == acceptedIds &&
        other.rejectedIds == rejectedIds &&
        other.originalPlan == originalPlan &&
        other.workingPlan == workingPlan &&
        other.isShowingAllChanges == isShowingAllChanges;
  }

  @override
  int get hashCode {
    return allChanges.hashCode ^
        currentIndex.hashCode ^
        acceptedIds.hashCode ^
        rejectedIds.hashCode ^
        originalPlan.hashCode ^
        workingPlan.hashCode ^
        isShowingAllChanges.hashCode;
  }
}
