import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';

/// 只读反馈历史区域
///
/// 显示当前选中动作的最近 10 条反馈（只读模式）
/// 包含"添加反馈"按钮，点击后弹出 Bottom Sheet
class ReadOnlyFeedbackSection extends ConsumerWidget {
  final String studentId;
  final String exerciseTemplateId;
  final String? exerciseName;
  final VoidCallback onAddFeedbackTap;

  const ReadOnlyFeedbackSection({
    super.key,
    required this.studentId,
    required this.exerciseTemplateId,
    this.exerciseName,
    required this.onAddFeedbackTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final params = ExerciseFeedbackParams(
      studentId: studentId,
      exerciseTemplateId: exerciseTemplateId,
    );

    // 固定页数为 1（显示最近 10 条）
    final feedbacksAsync = ref.watch(exerciseFeedbackHistoryProvider(params));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏：标题 + "添加反馈"按钮
          Row(
            children: [
              Icon(
                CupertinoIcons.chat_bubble_text,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.recentFeedbacks,
                  style: AppTextStyles.callout.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onAddFeedbackTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.addFeedbackButton,
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 反馈列表（动态高度：空状态时紧凑，有内容时最大 350px）
          feedbacksAsync.when(
            data: (feedbacks) {
              if (feedbacks.isEmpty) {
                // 空状态：紧凑布局，不使用 ConstrainedBox
                return _EmptyState(
                    exerciseName: exerciseName ?? '');
              }

              // 有反馈：限制最大高度 350px，内部可滚动
              final displayFeedbacks = feedbacks.take(10).toList();

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: displayFeedbacks.length,
                  itemBuilder: (context, index) {
                    final feedback = displayFeedbacks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeedbackCard(feedback: feedback),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (error, stackTrace) => _ErrorState(error: error.toString()),
          ),
        ],
      ),
    );
  }
}

/// 空状态（紧凑版）
class _EmptyState extends StatelessWidget {
  final String exerciseName;

  const _EmptyState({required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.chat_bubble,
            size: 20,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.noFeedbackYet,
            style: AppTextStyles.subhead.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

/// 反馈卡片（简化版，复用自 ExerciseFeedbackHistorySection）
class _FeedbackCard extends StatelessWidget {
  final TrainingFeedbackModel feedback;

  const _FeedbackCard({required this.feedback});

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
        return Text(
          feedback.textContent ?? '',
          style: AppTextStyles.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      case 'voice':
        return Row(
          children: [
            Icon(
              CupertinoIcons.waveform,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${feedback.voiceDuration ?? 0}s',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case 'image':
        return Row(
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Image',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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
