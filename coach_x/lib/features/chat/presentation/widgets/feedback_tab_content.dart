import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/widgets/daily_summary_tile.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_sort_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/chat/presentation/providers/feedback_providers.dart';

/// 训练反馈 Tab 内容
///
/// 完整的反馈列表页面，包含：
/// - 搜索框与排序切换
/// - 按日期分组的反馈列表 (Daily Summaries)
class FeedbackTabContent extends ConsumerStatefulWidget {
  final String conversationId;

  const FeedbackTabContent({super.key, required this.conversationId});

  @override
  ConsumerState<FeedbackTabContent> createState() => _FeedbackTabContentState();
}

class _FeedbackTabContentState extends ConsumerState<FeedbackTabContent> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final initialQuery =
        ref.read(feedbackSearchQueryProvider(widget.conversationId));
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 监听反馈流
    final feedbacksAsync =
        ref.watch(feedbacksStreamProvider(widget.conversationId));

    return Column(
      children: [
        // 搜索与排序
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: l10n.feedbackSearchPlaceholder,
                  placeholderStyle: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  style: AppTextStyles.body,
                  backgroundColor: AppColors.backgroundSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  onChanged: _onSearchChanged,
                  onSuffixTap: _clearSearch,
                ),
              ),
              const SizedBox(width: 12),
              const FeedbackSortButton(),
            ],
          ),
        ),

        // 反馈列表
        Expanded(
          child: feedbacksAsync.when(
            data: (_) => _buildFeedbackList(context),
            loading: _buildLoadingState,
            error: (error, _) => _buildErrorState(context, error),
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref
          .read(
            feedbackSearchQueryProvider(widget.conversationId).notifier,
          )
          .state = query;
    });
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) {
      return;
    }
    _searchDebounce?.cancel();
    _searchController.clear();
    ref
        .read(
          feedbackSearchQueryProvider(widget.conversationId).notifier,
        )
        .state = '';
  }

  /// 构建反馈列表
  Widget _buildFeedbackList(BuildContext context) {
    final groupedFeedbacks = ref.watch(
      groupedFeedbacksProvider(widget.conversationId),
    );

    // 检查是否为空
    if (groupedFeedbacks.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final entry = groupedFeedbacks.entries.elementAt(index);
              return DailySummaryTile(
                dateLabel: entry.key,
                feedbacks: entry.value,
              );
            },
            childCount: groupedFeedbacks.length,
          ),
        ),

        // 底部间距
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    // Fixed const expression error
    return Center(child: CupertinoActivityIndicator(radius: 16));
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, Object error) {
     return Center(
      child: Text('Error loading feedbacks: $error'),
     );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
     return const Center(
      child: Text('No feedback yet'),
     );
  }
}
