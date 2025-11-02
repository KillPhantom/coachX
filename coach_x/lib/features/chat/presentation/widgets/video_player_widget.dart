import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 视频播放器组件
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _controller!.initialize();

    _controller!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      _isPlaying = _controller!.value.isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildThumbnail();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        width: 200,
        height: 200,
        color: CupertinoColors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 视频画面
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),

            // 播放/暂停按钮
            if (_showControls || !_isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_arrow_solid,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建缩略图
  Widget _buildThumbnail() {
    if (widget.thumbnailUrl != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: widget.thumbnailUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.play_arrow_solid,
              color: CupertinoColors.white,
              size: 28,
            ),
          ),
        ],
      );
    }

    return Container(
      width: 200,
      height: 200,
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: Icon(
          CupertinoIcons.videocam,
          color: AppColors.textTertiary,
          size: 48,
        ),
      ),
    );
  }
}
