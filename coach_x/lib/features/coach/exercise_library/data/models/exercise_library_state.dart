import 'package:equatable/equatable.dart';
import 'exercise_template_model.dart';
import 'exercise_tag_model.dart';

/// Exercise Library State - 动作库状态
///
/// 管理动作模板列表、标签、搜索和筛选状态
class ExerciseLibraryState extends Equatable {
  /// 所有动作模板
  final List<ExerciseTemplateModel> templates;

  /// 所有标签
  final List<ExerciseTagModel> tags;

  /// 搜索关键词
  final String searchQuery;

  /// 选中的标签（用于筛选）
  final List<String> selectedTags;

  /// 加载状态
  final LoadingStatus loadingStatus;

  /// 错误信息
  final String? error;

  /// 最后同步时间
  final DateTime? lastSyncTime;

  /// 是否还有更多数据（分页）
  final bool hasMoreData;

  /// 是否正在加载更多（分页）
  final bool isLoadingMore;

  const ExerciseLibraryState({
    this.templates = const [],
    this.tags = const [],
    this.searchQuery = '',
    this.selectedTags = const [],
    this.loadingStatus = LoadingStatus.initial,
    this.error,
    this.lastSyncTime,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  /// 初始状态
  factory ExerciseLibraryState.initial() => const ExerciseLibraryState();

  /// 获取过滤后的动作模板
  ///
  /// 同时应用搜索和标签筛选
  List<ExerciseTemplateModel> getFilteredTemplates() {
    var result = templates;

    // 应用标签筛选（OR 逻辑）
    if (selectedTags.isNotEmpty) {
      result = result.where((template) {
        // 只要有一个标签匹配就显示
        return template.tags.any((tag) => selectedTags.contains(tag));
      }).toList();
    }

    // 应用搜索筛选（忽略大小写）
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((template) {
        return template.name.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  /// 检查缓存是否过期（30分钟）
  bool get isCacheExpired {
    if (lastSyncTime == null) return true;
    final diff = DateTime.now().difference(lastSyncTime!);
    return diff.inMinutes >= 30;
  }

  /// 创建副本
  ExerciseLibraryState copyWith({
    List<ExerciseTemplateModel>? templates,
    List<ExerciseTagModel>? tags,
    String? searchQuery,
    List<String>? selectedTags,
    LoadingStatus? loadingStatus,
    String? error,
    DateTime? lastSyncTime,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return ExerciseLibraryState(
      templates: templates ?? this.templates,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      loadingStatus: loadingStatus ?? this.loadingStatus,
      error: error ?? this.error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    templates,
    tags,
    searchQuery,
    selectedTags,
    loadingStatus,
    error,
    lastSyncTime,
    hasMoreData,
    isLoadingMore,
  ];
}

/// 加载状态枚举
enum LoadingStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 加载成功
  success,

  /// 加载失败
  error,

  /// 刷新中（下拉刷新）
  refreshing,
}
