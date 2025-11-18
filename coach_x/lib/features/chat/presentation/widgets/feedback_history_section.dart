import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/audio_player_widget.dart';
import 'package:coach_x/core/widgets/image_preview_page.dart';

/// 反馈历史区域
///
/// 显示该训练的所有反馈记录（新格式）
class FeedbackHistorySection extends ConsumerWidget {
  final String dailyTrainingId;

  const FeedbackHistorySection({super.key, required this.dailyTrainingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackHistoryAsync = ref.watch(
      feedbackHistoryStreamProvider(dailyTrainingId),
    );

    return feedbackHistoryAsync.when(
      data: (feedbacks) {
        if (feedbacks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题暂时省略，等国际化完成后添加
              const SizedBox(height: 8),
              // 反馈列表
              ...feedbacks.map(
                (feedback) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeedbackBubble(feedback: feedback),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CupertinoActivityIndicator(),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 单个反馈气泡
class _FeedbackBubble extends StatelessWidget {
  final TrainingFeedbackModel feedback;

  const _FeedbackBubble({required this.feedback});

  @override
  Widget build(BuildContext context) {
    // 根据 feedbackType 渲染不同类型
    switch (feedback.feedbackType) {
      case 'text':
        return _TextBubble(
          content: feedback.textContent ?? '',
          createdAt: feedback.createdAt,
        );
      case 'voice':
        return _VoiceBubble(
          voiceUrl: feedback.voiceUrl ?? '',
          duration: feedback.voiceDuration ?? 0,
          createdAt: feedback.createdAt,
        );
      case 'image':
        return _ImageBubble(
          imageUrl: feedback.imageUrl ?? '',
          createdAt: feedback.createdAt,
          feedbackId: feedback.id,
          dailyTrainingId: feedback.dailyTrainingId,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 文字气泡
class _TextBubble extends StatelessWidget {
  final String content;
  final int createdAt;

  const _TextBubble({required this.content, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end, // 教练的反馈靠右
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary, // 使用主题色
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) => Text(
                    _formatTime(createdAt, context),
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int timestamp, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      final l10n = AppLocalizations.of(context)!;
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

/// 语音气泡
class _VoiceBubble extends StatelessWidget {
  final String voiceUrl;
  final int duration;
  final int createdAt;

  const _VoiceBubble({
    required this.voiceUrl,
    required this.duration,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AudioPlayerWidget(
                  audioUrl: voiceUrl,
                  duration: duration,
                  isMine: true, // 教练的反馈
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) => Text(
                    _formatTime(createdAt, context),
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int timestamp, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      final l10n = AppLocalizations.of(context)!;
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

/// 图片气泡
class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final int createdAt;
  final String feedbackId;
  final String dailyTrainingId;

  const _ImageBubble({
    required this.imageUrl,
    required this.createdAt,
    required this.feedbackId,
    required this.dailyTrainingId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: AppColors.backgroundSecondary,
                          child: const Icon(
                            CupertinoIcons.photo,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) => Text(
                    _formatTime(createdAt, context),
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => ImagePreviewPage(
          imageUrl: imageUrl,
          showEditButton: false, // Feedback history images are read-only
        ),
      ),
    );
  }

  String _formatTime(int timestamp, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      final l10n = AppLocalizations.of(context)!;
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
