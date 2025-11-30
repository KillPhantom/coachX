import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/training_feed_item.dart';
import 'feed_video_player.dart';
import 'keyframe_floating_button.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/image_preview_page.dart';
import '../../../../core/utils/logger.dart';
import '../providers/training_feed_providers.dart';
import '../../../student/home/data/models/daily_training_model.dart';
import '../../../student/training/data/models/keyframe_model.dart';

class VideoFeedItem extends ConsumerStatefulWidget {
  final TrainingFeedItem feedItem;
  final VoidCallback onCommentTap;
  final bool isSheetOpen;

  const VideoFeedItem({
    super.key,
    required this.feedItem,
    required this.onCommentTap,
    this.isSheetOpen = false,
  });

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem> {
  Duration _currentPosition = Duration.zero;
  bool _isFlashing = false;
  VideoPlayerController? _videoController;

  @override
  Widget build(BuildContext context) {
    final metadata = widget.feedItem.metadata!;
    final videoUrl = metadata['videoUrl'] as String;

    // 监听 dailyTraining 数据以获取关键帧
    final dailyTrainingAsync = ref.watch(
      dailyTrainingStreamProvider(widget.feedItem.dailyTrainingId),
    );

    AppLogger.info('📊 dailyTrainingAsync 状态: ${dailyTrainingAsync.runtimeType}');
    AppLogger.info('📊 hasValue: ${dailyTrainingAsync.hasValue}, hasError: ${dailyTrainingAsync.hasError}, isLoading: ${dailyTrainingAsync.isLoading}');

    // 获取当前 exercise 的关键帧
    final keyframes = dailyTrainingAsync.when(
      data: (dailyTraining) {
        AppLogger.info('📊 进入 data 分支，开始查找关键帧');
        return _getKeyframesForCurrentExercise(dailyTraining);
      },
      loading: () {
        AppLogger.info('📊 dailyTraining 加载中...');
        return <KeyframeModel>[];
      },
      error: (error, stackTrace) {
        AppLogger.error('📊 dailyTraining 加载错误', error, stackTrace);
        return <KeyframeModel>[];
      },
    );

    AppLogger.info('📊 最终获得的关键帧数量: ${keyframes.length}');

    return Stack(
      children: [
        // 背景视频播放器
        FeedVideoPlayer(
          videoUrl: videoUrl,
          autoPlay: true,
          showProgressBar: !widget.isSheetOpen,
          keyframes: keyframes,
          onKeyframeTap: (timestamp) => _handleKeyframeTap(timestamp, keyframes),
          onPauseChanged: (isPaused) {
            // 视频暂停时不显示时间轴
          },
          onPositionChanged: (position) {
            _currentPosition = position;
          },
          onControllerReady: (controller) {
            _videoController = controller;
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

              // 截取关键帧按钮
              KeyframeFloatingButton(onTap: _captureKeyframe),
            ],
          ),
        ),

        // Flash Effect Overlay
        if (_isFlashing)
          Positioned.fill(child: Container(color: CupertinoColors.white)),
      ],
    );
  }

  Future<void> _captureKeyframe() async {
    if (widget.feedItem.exerciseTemplateId == null) {
      AppLogger.warning('Cannot capture keyframe: exerciseTemplateId is null');
      return;
    }

    // 1. Trigger Flash Effect
    setState(() {
      _isFlashing = true;
    });

    // 2. Wait for flash duration
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _isFlashing = false;
    });

    try {
      final metadata = widget.feedItem.metadata!;
      final videoUrl = metadata['videoUrl'] as String;

      // 3. Capture Frame
      final fileName = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        timeMs: _currentPosition.inMilliseconds,
        quality: 100,
        imageFormat: ImageFormat.JPEG,
      );

      if (fileName == null) {
        throw Exception('Failed to generate thumbnail');
      }

      if (!mounted) return;

      // 4. Navigate to ImagePreviewPage for editing
      final videoIndex = widget.feedItem.metadata?['videoIndex'] as int?;

      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ImagePreviewPage(
            localPath: fileName,
            dailyTrainingId: widget.feedItem.dailyTrainingId,
            exerciseTemplateId: widget.feedItem.exerciseTemplateId,
            videoIndex: videoIndex,
            timestamp:
                _currentPosition.inMilliseconds / 1000.0, // Convert to seconds
            showEditButton: true,
          ),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to capture keyframe', e, stackTrace);
      // TODO: Show error toast
    }
  }

  /// 根据 exerciseTemplateId 或 exerciseName 查找 exercise 在列表中的索引
  int? _findExerciseIndex(
    DailyTrainingModel dailyTraining,
    String? exerciseTemplateId,
  ) {
    if (dailyTraining.exercises == null) {
      AppLogger.warning('❌ exercises 为 null');
      return null;
    }

    AppLogger.info('🔍 正在查找 - exerciseTemplateId: $exerciseTemplateId, exerciseName: ${widget.feedItem.exerciseName}');

    // 方法1：通过 exerciseTemplateId 匹配
    if (exerciseTemplateId != null) {
      for (var i = 0; i < dailyTraining.exercises!.length; i++) {
        final exercise = dailyTraining.exercises![i];
        AppLogger.info('  - 索引 $i: exerciseTemplateId = ${exercise.exerciseTemplateId}, name = ${exercise.name}');
        if (exercise.exerciseTemplateId == exerciseTemplateId) {
          AppLogger.info('✅ 通过 exerciseTemplateId 找到匹配，索引: $i');
          return i;
        }
      }
    }

    // 方法2：通过 exerciseName 匹配（fallback）
    if (widget.feedItem.exerciseName != null) {
      for (var i = 0; i < dailyTraining.exercises!.length; i++) {
        final exercise = dailyTraining.exercises![i];
        if (exercise.name == widget.feedItem.exerciseName) {
          AppLogger.info('✅ 通过 exerciseName 找到匹配，索引: $i');
          return i;
        }
      }
    }

    AppLogger.warning('❌ 未找到匹配的 exercise');
    return null;
  }

  /// 获取当前 exercise 和 video 的关键帧列表
  List<KeyframeModel> _getKeyframesForCurrentExercise(
    DailyTrainingModel dailyTraining,
  ) {
    // 1. 获取 exerciseIndex
    final exerciseIndex = _findExerciseIndex(
      dailyTraining,
      widget.feedItem.exerciseTemplateId,
    );

    AppLogger.info('🔍 找到的 exerciseIndex: $exerciseIndex');

    if (exerciseIndex == null) {
      AppLogger.warning('❌ exerciseIndex 为 null，无法获取关键帧');
      return [];
    }

    // 2. 获取 videoIndex
    final metadata = widget.feedItem.metadata;
    if (metadata == null) {
      AppLogger.warning('❌ metadata 为 null，无法获取 videoIndex');
      return [];
    }

    final videoIndex = metadata['videoIndex'] as int?;
    if (videoIndex == null) {
      AppLogger.warning('❌ videoIndex 为 null，无法获取关键帧');
      return [];
    }

    AppLogger.info('🔍 找到的 videoIndex: $videoIndex');

    // 3. 使用双层 key 查询
    final exerciseKey = exerciseIndex.toString();
    final videoKey = videoIndex.toString();

    final exerciseLevel = dailyTraining.extractedKeyFrames[exerciseKey];
    if (exerciseLevel == null) {
      AppLogger.info('📊 没有找到 exercise 层级数据 (exerciseKey=$exerciseKey)');
      return [];
    }

    final videoLevel = exerciseLevel[videoKey];
    if (videoLevel == null) {
      AppLogger.info('📊 没有找到 video 层级数据 (videoKey=$videoKey)');
      return [];
    }

    final keyframes = videoLevel.keyframes;
    AppLogger.info('✅ 成功获取关键帧: exerciseIndex=$exerciseIndex, videoIndex=$videoIndex, 数量=${keyframes.length}');

    return keyframes;
  }

  /// 处理关键帧点击事件
  void _handleKeyframeTap(double timestamp, List<KeyframeModel> keyframes) {
    // 1. 获取 video controller
    if (_videoController == null) {
      AppLogger.warning('Video controller is null, cannot handle keyframe tap');
      return;
    }

    // 2. 暂停视频
    _videoController!.pause();

    // 3. 跳转到时间点
    _videoController!.seekTo(Duration(seconds: timestamp.toInt()));

    // 4. 找到被点击的关键帧
    final clickedKeyframe = keyframes.firstWhere(
      (kf) => kf.timestamp == timestamp,
      orElse: () => keyframes.first,
    );

    // 5. 打开 ImagePreviewPage
    if (clickedKeyframe.url != null) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ImagePreviewPage(
            imageUrl: clickedKeyframe.url,
            dailyTrainingId: widget.feedItem.dailyTrainingId,
            exerciseTemplateId: widget.feedItem.exerciseTemplateId,
            timestamp: timestamp,
            showEditButton: true,
          ),
        ),
      );
    }
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
