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

enum _ActiveSheet { none, detail, comment }

class _TrainingFeedPageState extends ConsumerState<TrainingFeedPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _sheetAnimationController;
  _ActiveSheet _activeSheet = _ActiveSheet.none;
  dynamic _selectedFeedItem;
  double _sheetHeight = 0.0;
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(currentFeedIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentScrollController.dispose();
    _sheetAnimationController.dispose();
    super.dispose();
  }

  void _closeSheet() {
    _sheetAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeSheet = _ActiveSheet.none;
          _sheetHeight = 0.0;
          _selectedFeedItem = null;
        });
        if (_contentScrollController.hasClients) {
          _contentScrollController.jumpTo(0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedItemsState = ref.watch(
      feedItemsNotifierProvider(widget.dailyTrainingId),
    );
    final feedItems = feedItemsState.items;
    final currentIndex = ref.watch(currentFeedIndexProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        middle: feedItems.isEmpty || currentIndex >= feedItems.length
            ? Text(
                widget.studentName,
                style: AppTextStyles.navTitle.copyWith(
                  color: CupertinoColors.white,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.studentName,
                    style: AppTextStyles.navTitle.copyWith(
                      color: CupertinoColors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${feedItemsState.reviewedCount}/${feedItemsState.totalContentCount}',
                    style: AppTextStyles.caption1.copyWith(
                      color: CupertinoColors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;

            return Stack(
              children: [
                // Layer 1: Content (Video/Feed)
                // Shrinks to top when sheet is open
                AnimatedBuilder(
                  animation: _sheetAnimationController,
                  builder: (context, child) {
                    // Calculate the actual visible height of the sheet
                    // During animation: sheetHeight * animationValue
                    // During drag: sheetHeight (animationValue is 1.0)
                    final visibleSheetHeight =
                        _sheetHeight * _sheetAnimationController.value;

                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: visibleSheetHeight * availableHeight,
                      child: child!,
                    );
                  },
                  child: feedItemsState.isLoading
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          ),
                        )
                      : feedItemsState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.error,
                                style: AppTextStyles.title3.copyWith(
                                  color: CupertinoColors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                feedItemsState.error!,
                                style: AppTextStyles.body.copyWith(
                                  color: CupertinoColors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              CupertinoButton.filled(
                                onPressed: () {
                                  ref
                                      .read(
                                        feedItemsNotifierProvider(
                                          widget.dailyTrainingId,
                                        ).notifier,
                                      )
                                      .refresh();
                                },
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        )
                      : feedItems.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noTrainingRecords,
                            style: AppTextStyles.body.copyWith(
                              color: CupertinoColors.white,
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: feedItems.length,
                          onPageChanged: (index) {
                            // 更新当前索引
                            final previousIndex = ref.read(
                              currentFeedIndexProvider,
                            );
                            ref.read(currentFeedIndexProvider.notifier).state =
                                index;

                            // 上滑时，标记前一个 Feed Item 为已批阅
                            if (index > previousIndex &&
                                previousIndex < feedItems.length) {
                              final previousItem = feedItems[previousIndex];
                              // 只标记内容项（排除 Completion Item）
                              if (previousItem.type.isContentItem) {
                                ref
                                    .read(
                                      feedItemsNotifierProvider(
                                        widget.dailyTrainingId,
                                      ).notifier,
                                    )
                                    .markItemReviewed(previousItem.id);
                              }
                            }
                          },
                          itemBuilder: (context, index) {
                            final feedItem = feedItems[index];
                            return _buildFeedItem(feedItem);
                          },
                        ),
                ),

                // Layer 1.5: Barrier (Disable video interaction)
                if (_activeSheet != _ActiveSheet.none)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _closeSheet,
                      child: Container(color: const Color(0x00000000)),
                    ),
                  ),

                // Layer 2: Bottom Sheet
                if (_activeSheet != _ActiveSheet.none &&
                    _selectedFeedItem != null)
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _sheetAnimationController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: availableHeight * 0.7,
                        child: _activeSheet == _ActiveSheet.detail
                            ? FeedDetailSheet(
                                feedItem: _selectedFeedItem,
                                scrollController: _contentScrollController,
                                onClose: _closeSheet,
                              )
                            : FeedCommentSheetWidget(
                                dailyTrainingId: widget.dailyTrainingId,
                                studentId: widget.studentId,
                                exerciseTemplateId:
                                    _selectedFeedItem.exerciseTemplateId,
                                exerciseName: _selectedFeedItem.exerciseName,
                                scrollController: _contentScrollController,
                                onClose: _closeSheet,
                              ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
          isSheetOpen: _activeSheet != _ActiveSheet.none,
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
    setState(() {
      _activeSheet = _ActiveSheet.comment;
      _selectedFeedItem = feedItem;
      _sheetHeight = 0.7; // Set initial target height
    });
    _sheetAnimationController.forward();
  }

  void _showDetailSheet(feedItem) {
    setState(() {
      _activeSheet = _ActiveSheet.detail;
      _selectedFeedItem = feedItem;
      _sheetHeight = 0.7; // Set initial target height
    });
    _sheetAnimationController.forward();
  }
}
