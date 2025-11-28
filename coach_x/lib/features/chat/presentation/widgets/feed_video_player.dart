import 'package:flutter/cupertino.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'tiktok_progress_bar.dart';
import '../../../student/training/data/models/keyframe_model.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showProgressBar;
  final ValueChanged<bool>? onPauseChanged;
  final ValueChanged<Duration>? onPositionChanged;
  final List<KeyframeModel>? keyframes;
  final ValueChanged<double>? onKeyframeTap;
  final ValueChanged<VideoPlayerController>? onControllerReady;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.showProgressBar = true,
    this.onPauseChanged,
    this.onPositionChanged,
    this.keyframes,
    this.onKeyframeTap,
    this.onControllerReady,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  CachedVideoPlayerPlus? _player;
  bool _isInitialized = false;
  bool _isPaused = false;
  bool _isDragging = false;

  // Expose controller for external access
  VideoPlayerController? get videoController => _player?.controller;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _player = CachedVideoPlayerPlus.networkUrl(
      Uri.parse(widget.videoUrl),
      invalidateCacheIfOlderThan: const Duration(days: 7),
    );
    await _player!.initialize();

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });

    // 通知 controller 已准备好
    widget.onControllerReady?.call(_player!.controller);

    // 自动播放
    if (widget.autoPlay) {
      _player!.controller.play();
    }

    // 监听播放状态
    _player!.controller.addListener(() {
      if (!mounted) return;

      final isPlaying = _player!.controller.value.isPlaying;
      if (_isPaused != !isPlaying) {
        setState(() {
          _isPaused = !isPlaying;
        });
        widget.onPauseChanged?.call(_isPaused);
      }

      // 播放位置回调
      widget.onPositionChanged?.call(_player!.controller.value.position);
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_player == null) return;

    if (_player!.controller.value.isPlaying) {
      _player!.controller.pause();
    } else {
      _player!.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _player == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final controller = _player!.controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 视频播放区
        GestureDetector(
          onTap: _togglePlayPause,
          child: Align(
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        // 播放/暂停按钮（仅暂停时显示，且不在拖动时）
        if (_isPaused && !_isDragging)
          IgnorePointer(
            child: Center(
              child: Icon(
                CupertinoIcons.play_circle_fill,
                size: 80,
                color: CupertinoColors.white.withOpacity(0.8),
              ),
            ),
          ),

        // 底部：关键帧时间轴 + 进度条
        if (widget.showProgressBar)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: TikTokProgressBar(
                  controller: controller,
                  keyframes: widget.keyframes,
                  onKeyframeTap: widget.onKeyframeTap,
                  onDragStart: (_) => setState(() => _isDragging = true),
                  onDragEnd: (_) => setState(() => _isDragging = false),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
