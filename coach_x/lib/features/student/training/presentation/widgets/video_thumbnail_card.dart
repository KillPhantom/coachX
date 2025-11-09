import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 视频缩略图卡片
///
/// 显示视频缩略图、播放图标、时长和删除按钮
class VideoThumbnailCard extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final double width;
  final double height;

  const VideoThumbnailCard({
    super.key,
    required this.videoUrl,
    required this.onTap,
    required this.onDelete,
    this.width = 100,
    this.height = 100,
  });

  @override
  State<VideoThumbnailCard> createState() => _VideoThumbnailCardState();
}

class _VideoThumbnailCardState extends State<VideoThumbnailCard> {
  File? _thumbnailFile;
  Duration? _duration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnailAndDuration();
  }

  Future<void> _loadThumbnailAndDuration() async {
    try {
      final thumbnail = await VideoUtils.generateThumbnail(widget.videoUrl);
      final duration = await VideoUtils.getVideoDuration(widget.videoUrl);

      if (mounted) {
        setState(() {
          _thumbnailFile = thumbnail;
          _duration = duration;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载视频缩略图失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Stack(
          children: [
            // 缩略图背景
            if (_isLoading)
              const Center(child: CupertinoActivityIndicator())
            else if (_thumbnailFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Image.file(
                  _thumbnailFile!,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                ),
              )
            else
              // 备用：显示占位图标
              const Center(
                child: Icon(
                  CupertinoIcons.film,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
              ),

            // 播放图标叠加层
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.play_fill,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
            ),

            // 右下角时长标签
            if (_duration != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    VideoUtils.formatDuration(_duration!),
                    style: AppTextStyles.caption2.copyWith(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),

            // 右上角删除按钮
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
