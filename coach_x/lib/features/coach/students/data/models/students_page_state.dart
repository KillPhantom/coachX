import 'student_list_item_model.dart';

/// 学生列表页面状态
class StudentsPageState {
  final List<StudentListItemModel> students;
  final int totalCount;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? searchQuery;
  final String? filterPlanId;

  const StudentsPageState({
    required this.students,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery,
    this.filterPlanId,
  });

  /// 初始状态
  factory StudentsPageState.initial() {
    return const StudentsPageState(
      students: [],
      totalCount: 0,
      currentPage: 1,
      hasMore: false,
      isLoading: false, // 修改为 false，允许首次加载
    );
  }

  /// 是否为空列表
  bool get isEmpty => students.isEmpty && !isLoading;

  /// 是否有筛选条件
  bool get hasFilter =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      (filterPlanId != null && filterPlanId!.isNotEmpty);

  /// 复制并修改
  StudentsPageState copyWith({
    List<StudentListItemModel>? students,
    int? totalCount,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? searchQuery,
    String? filterPlanId,
    bool clearError = false,
    bool clearSearch = false,
    bool clearFilter = false,
  }) {
    return StudentsPageState(
      students: students ?? this.students,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      filterPlanId: clearFilter ? null : (filterPlanId ?? this.filterPlanId),
    );
  }
}
