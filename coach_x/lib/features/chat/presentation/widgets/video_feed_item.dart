import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/training_feed_item.dart';
import 'feed_video_player.dart';
import 'keyframe_timeline.dart';
import 'keyframe_floating_button.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class VideoFeedItem extends ConsumerStatefulWidget {
  final TrainingFeedItem feedItem;
  final VoidCallback onCommentTap;
  final VoidCallback onDetailTap;

  const VideoFeedItem({
    super.key,
    required this.feedItem,
    required this.onCommentTap,
    required this.onDetailTap,
  });

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  bool _showTimeline = false;

  @override
  Widget build(BuildContext context) {
    final metadata = widget.feedItem.metadata!;
    final videoUrl = metadata['videoUrl'] as String;
    final videoIndex = metadata['videoIndex'] as int;
    final totalVideos = metadata['totalVideos'] as int;

    return Stack(
      children: [
        // 背景视频播放器
        FeedVideoPlayer(
          videoUrl: videoUrl,
          autoPlay: true,
          onPauseChanged: (isPaused) {
            // 视频暂停时显示时间轴
            setState(() {
              _showTimeline = isPaused;
            });
          },
        ),

        // 右侧操作栏
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 评论按钮
              _ActionButton(
                icon: CupertinoIcons.chat_bubble,
                label: '批阅',
                onTap: widget.onCommentTap,
              ),
              const SizedBox(height: 24),

              // 详情按钮
              _ActionButton(
                icon: CupertinoIcons.info_circle,
                label: '详情',
                onTap: widget.onDetailTap,
              ),
              const SizedBox(height: 24),

              // 截取关键帧按钮
              KeyframeFloatingButton(
                onTap: () {
                  // TODO: 打开关键帧编辑页面
                },
              ),
            ],
          ),
        ),

        // 底部信息栏
        Positioned(
          left: 16,
          right: 80,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 动作名称
              Text(
                widget.feedItem.exerciseName ?? '',
                style: AppTextStyles.title3.copyWith(
                  color: CupertinoColors.white,
                  shadows: [
                    Shadow(
                      color: CupertinoColors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // 视频计数
              Text(
                '视频 ${videoIndex + 1}/$totalVideos',
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.white,
                  shadows: [
                    Shadow(
                      color: CupertinoColors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

              // 批阅状态标记
              if (widget.feedItem.isReviewed)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '已批阅',
                    style: AppTextStyles.caption1.copyWith(
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 关键帧时间轴（视频暂停时显示）
        if (_showTimeline)
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: KeyframeTimeline(
              keyframes: const [], // TODO: 从 metadata 获取关键帧数据
              videoDuration: const Duration(
                seconds: 30,
              ), // TODO: 从 metadata 获取视频时长
              onKeyframeTap: (timestamp) {
                // TODO: 跳转到指定时间点
              },
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.black.withOpacity(0.5),
            ),
            child: Icon(icon, size: 28, color: CupertinoColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: CupertinoColors.white,
              shadows: [
                Shadow(
                  color: CupertinoColors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
