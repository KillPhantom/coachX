import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/audio_player_widget.dart';
import 'package:coach_x/features/chat/presentation/widgets/exercise_feedback_history_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_input_bar.dart';

/// Feed 评论区 Bottom Sheet
///
/// 支持视频项和图文项的批阅
/// - 视频项：显示该 exercise 的历史反馈（基于 exerciseTemplateId）
/// - 图文项：显示该 dailyTraining 的整体反馈（基于 dailyTrainingId）
/// Feed 评论区 Sheet (Inline)
class FeedCommentSheetWidget extends ConsumerWidget {
  final String dailyTrainingId;
  final String studentId;
  final String? exerciseTemplateId; // 视频项有值，图文项为 null
  final String? exerciseName;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const FeedCommentSheetWidget({
    super.key,
    required this.dailyTrainingId,
    required this.studentId,
    this.exerciseTemplateId,
    this.exerciseName,
    required this.scrollController,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isVideoItem = exerciseTemplateId != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Draggable Header
          SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),

                // 标题
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isVideoItem
                              ? l10n.exerciseFeedbackHistory(exerciseName ?? '')
                              : l10n.dailyTrainingFeedback,
                          style: AppTextStyles.title3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: onClose,
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // Scrollable Content (Independent)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: isVideoItem
                      ? ExerciseFeedbackHistorySection(
                          studentId: studentId,
                          exerciseTemplateId: exerciseTemplateId!,
                          shrinkWrap:
                              false, // Allow it to expand and scroll internally
                          // physics: const BouncingScrollPhysics(), // Default physics is fine
                          maxHeight: double.infinity,
                        )
                      : _DailyTrainingFeedbackSection(
                          dailyTrainingId: dailyTrainingId,
                          scrollController: null,
                        ),
                ),

                // 输入栏
                FeedbackInputBar(
                  dailyTrainingId: dailyTrainingId,
                  exerciseTemplateId: exerciseTemplateId,
                  exerciseName: exerciseName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 图文项反馈区域（整体反馈）
class _DailyTrainingFeedbackSection extends ConsumerWidget {
  final String dailyTrainingId;
  final ScrollController? scrollController;

  const _DailyTrainingFeedbackSection({
    required this.dailyTrainingId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feedbacksAsync = ref.watch(dailyTrainingFeedbacksProvider(dailyTrainingId));

    return feedbacksAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 100,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l10n.feedbackLoadError}: $error',
              style: AppTextStyles.caption1.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (feedbacks) {
        if (feedbacks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l10n.noDailyTrainingFeedbackYet,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          itemCount: feedbacks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            return _DailyTrainingFeedbackCard(feedback: feedback);
          },
        );
      },
    );
  }
}

/// Daily Training 反馈卡片
class _DailyTrainingFeedbackCard extends StatelessWidget {
  final TrainingFeedbackModel feedback;

  const _DailyTrainingFeedbackCard({required this.feedback});

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
