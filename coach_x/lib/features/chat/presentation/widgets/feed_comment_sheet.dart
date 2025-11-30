import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Needed for Colors
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/app/providers.dart'; // For feedbackRepositoryProvider
import 'package:coach_x/features/chat/presentation/widgets/audio_player_widget.dart';
import 'package:coach_x/features/chat/presentation/widgets/exercise_feedback_history_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_input_bar.dart';
import 'package:coach_x/features/chat/presentation/widgets/shake_widget.dart';

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
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Header
                SliverToBoxAdapter(
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

                // Content
                SliverToBoxAdapter(
                  child: isVideoItem
                      ? ExerciseFeedbackHistorySection(
                          studentId: studentId,
                          exerciseTemplateId: exerciseTemplateId!,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          maxHeight: double.infinity,
                        )
                      : _DailyTrainingFeedbackSection(
                          dailyTrainingId: dailyTrainingId,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                        ),
                ),

                // Spacer for input bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),

          // Input Bar (Pinned at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FeedbackInputBar(
              dailyTrainingId: dailyTrainingId,
              exerciseTemplateId: exerciseTemplateId,
              exerciseName: exerciseName,
            ),
          ),
        ],
      ),
    );
  }
}

/// 图文项反馈区域（整体反馈）
class _DailyTrainingFeedbackSection extends ConsumerStatefulWidget {
  final String dailyTrainingId;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const _DailyTrainingFeedbackSection({
    required this.dailyTrainingId,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  ConsumerState<_DailyTrainingFeedbackSection> createState() =>
      _DailyTrainingFeedbackSectionState();
}

class _DailyTrainingFeedbackSectionState
    extends ConsumerState<_DailyTrainingFeedbackSection> {
  bool _isEditing = false;

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _stopEditing() {
    if (_isEditing) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedbacksAsync =
        ref.watch(dailyTrainingFeedbacksProvider(widget.dailyTrainingId));

    return GestureDetector(
      onTap: _stopEditing, // 点击空白处退出编辑模式
      behavior: HitTestBehavior.opaque,
      child: feedbacksAsync.when(
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
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            shrinkWrap: widget.shrinkWrap,
            physics: widget.physics,
            itemCount: feedbacks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              return _DailyTrainingFeedbackCard(
                feedback: feedback,
                isEditing: _isEditing,
                onLongPress: () {
                  if (!_isEditing) {
                    _toggleEditing();
                  }
                },
                onDelete: () => _handleDelete(feedback),
              );
            },
          );
        },
      ),
    );
  }

  void _handleDelete(TrainingFeedbackModel feedback) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('删除反馈'), // TODO: Localize
        content: Text('确定要删除这条反馈吗？此操作无法撤销。'), // TODO: Localize
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repository = ref.read(feedbackRepositoryProvider);
                await repository.deleteFeedback(feedback.id, feedback);
                // 如果删除的是最后一个，自动退出编辑模式
                // 这里简单处理，不额外检查数量，保留编辑模式体验更连贯
              } catch (e, stackTrace) {
                AppLogger.error('删除反馈失败', e, stackTrace);
                // Show error toast/dialog
              }
            },
            child: Text(l10n.delete, style: AppTextStyles.body),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}

/// Daily Training 反馈卡片
class _DailyTrainingFeedbackCard extends StatelessWidget {
  final TrainingFeedbackModel feedback;
  final bool isEditing;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const _DailyTrainingFeedbackCard({
    required this.feedback,
    this.isEditing = false,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ShakeWidget(
          isEnabled: isEditing,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
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
            ),
          ),
        ),
        
        // 删除按钮 (Badged)
        if (isEditing)
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundWhite, // White background for circle
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2), // Small border effect
                child: const Icon(
                  CupertinoIcons.minus_circle_fill,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
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
      case 'video':
        // 简单显示视频缩略图
         return GestureDetector(
          // onTap: () => _playVideo(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  feedback.videoThumbnailUrl ?? '',
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
                      color: AppColors.backgroundSecondary,
                      child: Icon(
                        CupertinoIcons.videocam,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    CupertinoIcons.play_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
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
