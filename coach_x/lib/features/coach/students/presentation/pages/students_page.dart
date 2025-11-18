import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/empty_state.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import '../providers/students_providers.dart';
import '../widgets/student_card.dart';
import '../widgets/student_list_header.dart';
import '../widgets/invitation_code_dialog.dart';
import '../widgets/student_action_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';

/// 学生列表页面
class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentsStateProvider.notifier).loadStudents();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 监听滚动，实现无限滚动
  void _onScroll() {
    if (_isNearBottom) {
      final state = ref.read(studentsStateProvider);
      if (!state.isLoadingMore && state.hasMore) {
        ref.read(studentsStateProvider.notifier).loadMore();
      }
    }
  }

  /// 是否接近底部（90%）
  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(studentsStateProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // 顶部固定区域：搜索筛选栏
            StudentListHeader(
              totalCount: state.totalCount,
              onSearchTap: _toggleSearch,
              onFilterTap: _showFilterSheet,
              onAddTap: () => InvitationCodeDialog.show(context),
              hasFilter: state.hasFilter,
              isSearching: _isSearchExpanded,
            ),

            // 搜索输入框（从右向左滑入）
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isSearchExpanded ? 56 : 0,
              child: _isSearchExpanded
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingL,
                      ),
                      color: AppColors.backgroundLight,
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              placeholder: l10n.searchStudentPlaceholder,
                              clearButtonMode: OverlayVisibilityMode.editing,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingM,
                                vertical: AppDimensions.spacingM,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  _performSearch(value.trim());
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final query = _searchController.text.trim();
                              if (query.isNotEmpty) {
                                _performSearch(query);
                              }
                            },
                            child: Text(l10n.search),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _cancelSearch,
                            child: Text(l10n.cancel),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // 学生列表
            Expanded(
              child: DismissKeyboardOnScroll(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 下拉刷新
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await ref
                            .read(studentsStateProvider.notifier)
                            .refresh();
                      },
                    ),

                    // 内容区域
                    _buildContent(context, state),

                    // 加载更多指示器
                    if (state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.spacingL),
                          child: Center(child: CupertinoActivityIndicator()),
                        ),
                      ),

                    // 底部间距（避免被TabBar遮挡）
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppDimensions.spacingXXXL),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(BuildContext context, state) {
    final l10n = AppLocalizations.of(context)!;
    // 加载中
    if (state.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: LoadingIndicator()),
      );
    }

    // 错误状态
    if (state.error != null) {
      return SliverFillRemaining(
        child: ErrorView(
          error: state.error!,
          onRetry: () =>
              ref.read(studentsStateProvider.notifier).loadStudents(),
        ),
      );
    }

    // 空状态
    if (state.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: CupertinoIcons.person_2,
          title: state.hasFilter ? l10n.noStudentsFound : l10n.noStudents,
          message: state.hasFilter
              ? l10n.tryAdjustFilters
              : l10n.inviteStudentsTip,
          actionText: state.hasFilter ? l10n.clearFilters : l10n.inviteStudents,
          onAction: state.hasFilter
              ? () => ref.read(studentsStateProvider.notifier).clearFilter()
              : () => InvitationCodeDialog.show(context),
        ),
      );
    }

    // 学生列表
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = state.students[index];
          return StudentCard(
            student: student,
            onTap: () => _onStudentTap(student.id),
            onMoreTap: () => _showActionSheet(student),
          );
        }, childCount: state.students.length),
      ),
    );
  }

  /// 点击学生卡片
  void _onStudentTap(String studentId) {
    context.push('/student-detail/$studentId');
  }

  /// 显示操作菜单
  void _showActionSheet(student) {
    StudentActionSheet.show(
      context,
      student: student,
      onDelete: () => _deleteStudent(student.id),
      onRefresh: () => ref.read(studentsStateProvider.notifier).refresh(),
    );
  }

  /// 删除学生
  Future<void> _deleteStudent(String studentId) async {
    try {
      await ref.read(studentsStateProvider.notifier).deleteStudent(studentId);

      // 显示成功提示
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('成功'),
            content: const Text('学生已删除'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('错误'),
            content: Text('删除失败: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 切换搜索框显示
  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        // 展开时聚焦输入框
        Future.delayed(const Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        // 收起时清空搜索
        _cancelSearch();
      }
    });
  }

  /// 执行搜索
  void _performSearch(String query) {
    ref.read(studentsStateProvider.notifier).search(query);
    // unfocus 已通过 DismissKeyboardOnScroll 自动处理
  }

  /// 取消搜索
  void _cancelSearch() {
    setState(() {
      _isSearchExpanded = false;
      _searchController.clear();
    });
    // unfocus 已通过 DismissKeyboardOnScroll 自动处理

    // 如果有搜索条件，清除它
    final state = ref.read(studentsStateProvider);
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
      ref.read(studentsStateProvider.notifier).clearFilter();
    }
  }

  /// 显示筛选菜单
  void _showFilterSheet() {
    FilterBottomSheet.show(
      context,
      ref: ref,
      onFilter: (planId) {
        ref.read(studentsStateProvider.notifier).filter(planId);
      },
    );
  }
}
