import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/audio_player_widget.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 动作反馈历史Section
///
/// 显示当前选中动作的所有历史反馈（跨训练记录）
/// 支持分页加载
class ExerciseFeedbackHistorySection extends ConsumerWidget {
  final String studentId;
  final String exerciseTemplateId;
  final ScrollController? scrollController;
  final double maxHeight;
  final bool showLoadMoreButton;
  final bool showHeader;

  const ExerciseFeedbackHistorySection({
    super.key,
    required this.studentId,
    required this.exerciseTemplateId,
    this.scrollController,
    this.maxHeight = 200,
    this.showLoadMoreButton = true,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = ExerciseFeedbackParams(
      studentId: studentId,
      exerciseTemplateId: exerciseTemplateId,
    );
    final feedbacksAsync = ref.watch(exerciseFeedbackHistoryProvider(params));

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          border: Border(
            top: BorderSide(color: AppColors.dividerLight, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题（可选）
            if (showHeader) ...[
              Row(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_text,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.exerciseFeedbackHistory(''),
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 反馈列表（可滚动）
            Expanded(
              child: feedbacksAsync.when(
                data: (feedbacks) {
                  if (feedbacks.isEmpty) {
                    return const _EmptyState();
                  }

                  // 是否显示"加载更多"按钮
                  final shouldShowLoadMore =
                      showLoadMoreButton && feedbacks.length >= 10;

                  return ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: feedbacks.length + (shouldShowLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 加载更多按钮
                      if (index == feedbacks.length) {
                        return const _LoadMoreButton();
                      }

                      // 反馈卡片
                      final feedback = feedbacks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExerciseFeedbackCard(feedback: feedback),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (error, stackTrace) =>
                    _ErrorState(error: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.chat_bubble,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noFeedbackYet,
              style: AppTextStyles.subhead.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 错误状态
class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '${l10n.failedToSave}: $error',
          style: AppTextStyles.caption1.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

/// 加载更多按钮
class _LoadMoreButton extends ConsumerWidget {
  const _LoadMoreButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        final currentPage = ref.read(exerciseFeedbackPageProvider);
        ref.read(exerciseFeedbackPageProvider.notifier).state = currentPage + 1;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            l10n.loadMore,
            style: AppTextStyles.callout.copyWith(
              color: AppColors.primaryAction,
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个反馈卡片（Reddit-style）
class _ExerciseFeedbackCard extends StatelessWidget {
  final TrainingFeedbackModel feedback;

  const _ExerciseFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dividerLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 元信息（日期）
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                feedback.trainingDate,
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _formatRelativeTime(feedback.createdAt, context),
                style: AppTextStyles.caption2.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 反馈内容
          _buildFeedbackContent(),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent() {
    // 根据 feedbackType 渲染不同类型的反馈
    switch (feedback.feedbackType) {
      case 'text':
        return Text(feedback.textContent ?? '', style: AppTextStyles.body);
      case 'voice':
        return AudioPlayerWidget(
          audioUrl: feedback.voiceUrl ?? '',
          duration: feedback.voiceDuration ?? 0,
          isMine: true,
        );
      case 'image':
        return GestureDetector(
          onTap: () => _showFullImage(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              feedback.imageUrl ?? '',
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 150,
                  color: AppColors.backgroundSecondary,
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showFullImage() {
    // TODO: 实现全屏图片查看
    AppLogger.info('显示全屏图片: ${feedback.imageUrl}');
  }

  String _formatRelativeTime(int timestamp, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) {
      return l10n.justNow;
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
