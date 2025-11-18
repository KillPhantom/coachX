import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_feed_providers.dart';
import '../widgets/video_feed_item.dart';
import '../widgets/text_feed_item.dart';
import '../widgets/completion_feed_item.dart';
import '../widgets/feed_comment_sheet.dart';
import '../widgets/feed_detail_bottom_sheet.dart';
import '../../data/models/feed_item_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Training Feed Page - 沉浸式训练批阅流
///
/// TikTok/Reels 式全屏滑动交互
/// 支持视频项、图文项、完成项的批阅
class TrainingFeedPage extends ConsumerStatefulWidget {
  final String dailyTrainingId;
  final String studentId;
  final String studentName;

  const TrainingFeedPage({
    super.key,
    required this.dailyTrainingId,
    required this.studentId,
    required this.studentName,
  });

  @override
  ConsumerState<TrainingFeedPage> createState() => _TrainingFeedPageState();
}

class _TrainingFeedPageState extends ConsumerState<TrainingFeedPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(currentFeedIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedItemsAsync = ref.watch(feedItemsProvider(widget.dailyTrainingId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.studentName, style: AppTextStyles.navTitle),
        trailing: _buildInfoButton(),
      ),
      child: SafeArea(
        child: feedItemsAsync.when(
          data: (feedItems) {
            if (feedItems.isEmpty) {
              return Center(
                child: Text(l10n.noTrainingRecords, style: AppTextStyles.body),
              );
            }

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: feedItems.length,
              onPageChanged: (index) {
                ref.read(currentFeedIndexProvider.notifier).state = index;
              },
              itemBuilder: (context, index) {
                final feedItem = feedItems[index];

                return _buildFeedItem(feedItem);
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.error, style: AppTextStyles.title3),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    ref.invalidate(feedItemsProvider(widget.dailyTrainingId));
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(feedItem) {
    switch (feedItem.type) {
      case FeedItemType.video:
        return VideoFeedItem(
          feedItem: feedItem,
          onCommentTap: () => _showCommentSheet(feedItem),
          onDetailTap: () => _showDetailSheet(feedItem),
        );

      case FeedItemType.textCard:
        return TextFeedItem(
          feedItem: feedItem,
          onCommentTap: () => _showCommentSheet(feedItem),
          onDetailTap: () => _showDetailSheet(feedItem),
        );

      case FeedItemType.completion:
        return CompletionFeedItem(onClose: () => Navigator.of(context).pop());

      default:
        return const SizedBox();
    }
  }

  void _showCommentSheet(feedItem) {
    FeedCommentSheet.show(
      context,
      dailyTrainingId: widget.dailyTrainingId,
      studentId: widget.studentId,
      exerciseTemplateId: feedItem.exerciseTemplateId,
      exerciseName: feedItem.exerciseName,
    );
  }

  void _showDetailSheet(feedItem) {
    FeedDetailBottomSheet.show(context, feedItem: feedItem);
  }

  Widget _buildInfoButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        // TODO: 显示训练记录概览
        _showTrainingInfo();
      },
      child: const Icon(CupertinoIcons.info_circle, size: 24),
    );
  }

  void _showTrainingInfo() {
    final l10n = AppLocalizations.of(context)!;
    final dailyTrainingAsync = ref.read(
      dailyTrainingStreamProvider(widget.dailyTrainingId).future,
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.trainingInfo),
        content: FutureBuilder(
          future: dailyTrainingAsync,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final training = snapshot.data!;
              return Text(
                '${l10n.trainingDate}: ${training.date}\n'
                '${l10n.totalExercises}: ${training.exercises?.length ?? 0}',
              );
            }
            return const CupertinoActivityIndicator();
          },
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
