import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/providers/feedback_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_card.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_date_filter.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_group_header.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_search_bar.dart';

/// 训练反馈 Tab 内容
///
/// 完整的反馈列表页面，包含：
/// - 搜索栏
/// - 日期筛选
/// - 按日期分组的反馈列表
class FeedbackTabContent extends ConsumerWidget {
  final String conversationId;

  const FeedbackTabContent({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听反馈流
    final feedbacksAsync = ref.watch(feedbacksStreamProvider(conversationId));

    return Column(
      children: [
        // 搜索栏
        const FeedbackSearchBar(),

        // 日期筛选器
        const FeedbackDateFilter(),

        // 反馈列表
        Expanded(
          child: feedbacksAsync.when(
            data: (feedbacks) => _buildFeedbackList(context, ref),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(context, ref, error),
          ),
        ),
      ],
    );
  }

  /// 构建反馈列表
  Widget _buildFeedbackList(BuildContext context, WidgetRef ref) {
    final groupedFeedbacks = ref.watch(
      groupedFeedbacksProvider(conversationId),
    );

    // 检查是否为空
    if (groupedFeedbacks.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        // 遍历每个日期分组
        for (final entry in groupedFeedbacks.entries) ...[
          // 日期分组标题
          SliverToBoxAdapter(child: FeedbackGroupHeader(dateLabel: entry.key)),

          // 该日期下的所有反馈卡片
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final feedback = entry.value[index];
              return FeedbackCard(feedback: feedback);
            }, childCount: entry.value.length),
          ),
        ],

        // 底部间距
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(child: CupertinoActivityIndicator(radius: 16));
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load feedback',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                // 重新加载
                ref.invalidate(feedbacksStreamProvider(conversationId));
              },
              child: Text(
                'Retry',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.tray,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No feedback yet',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Training feedback will appear here',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
