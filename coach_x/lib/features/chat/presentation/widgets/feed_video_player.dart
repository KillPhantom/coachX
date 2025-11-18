import 'package:flutter/cupertino.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final ValueChanged<bool>? onPauseChanged;
  final ValueChanged<Duration>? onPositionChanged;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.onPauseChanged,
    this.onPositionChanged,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  CachedVideoPlayerPlus? _player;
  bool _isInitialized = false;
  bool _isPaused = false;

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

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频播放区
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),

          // 播放/暂停按钮（仅暂停时显示）
          if (_isPaused)
            Center(
              child: Icon(
                CupertinoIcons.play_circle_fill,
                size: 80,
                color: CupertinoColors.white.withOpacity(0.8),
              ),
            ),

          // 进度条
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _ProgressBar(player: _player!),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final CachedVideoPlayerPlus player;

  const _ProgressBar({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoSlider(
          value: player.controller.value.position.inMilliseconds.toDouble(),
          max: player.controller.value.duration.inMilliseconds.toDouble(),
          onChanged: (value) {
            player.controller.seekTo(Duration(milliseconds: value.toInt()));
          },
        ),
        Text(
          '${_formatDuration(player.controller.value.position)} / ${_formatDuration(player.controller.value.duration)}',
          style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
