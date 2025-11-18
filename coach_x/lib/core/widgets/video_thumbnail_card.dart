import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:coach_x/core/models/video_upload_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 视频缩略图卡片
///
/// 显示视频缩略图、播放图标、时长、删除按钮和上传状态
class VideoThumbnailCard extends StatefulWidget {
  final VideoUploadState uploadState;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRetry;
  final double width;
  final double height;

  const VideoThumbnailCard({
    super.key,
    required this.uploadState,
    required this.onTap,
    required this.onDelete,
    this.onRetry,
    this.width = 100,
    this.height = 100,
  });

  @override
  State<VideoThumbnailCard> createState() => _VideoThumbnailCardState();
}

class _VideoThumbnailCardState extends State<VideoThumbnailCard> {
  File? _thumbnailFile;
  Duration? _duration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnailAndDuration();
  }

  @override
  void didUpdateWidget(VideoThumbnailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果视频状态变化，重新加载
    if (oldWidget.uploadState.downloadUrl != widget.uploadState.downloadUrl ||
        oldWidget.uploadState.thumbnailPath !=
            widget.uploadState.thumbnailPath ||
        oldWidget.uploadState.thumbnailUrl != widget.uploadState.thumbnailUrl) {
      _loadThumbnailAndDuration();
    }
  }

  Future<void> _loadThumbnailAndDuration() async {
    // 优先级1: 如果有网络缩略图URL，直接使用（无需本地生成）
    if (widget.uploadState.thumbnailUrl != null) {
      setState(() {
        _thumbnailFile = null; // 清除本地文件，使用网络URL
        _isLoading = false;
      });
      return;
    }

    // 优先级2: 如果有本地缩略图，直接使用
    if (widget.uploadState.thumbnailPath != null) {
      setState(() {
        _thumbnailFile = File(widget.uploadState.thumbnailPath!);
        _isLoading = false;
      });
      return;
    }

    // 优先级3（降级方案）: 从网络视频URL生成缩略图
    if (widget.uploadState.downloadUrl != null) {
      setState(() => _isLoading = true);
      try {
        final thumbnail = await VideoUtils.generateThumbnail(
          widget.uploadState.downloadUrl!,
        );
        final duration = await VideoUtils.getVideoDuration(
          widget.uploadState.downloadUrl!,
        );

        if (mounted) {
          setState(() {
            _thumbnailFile = thumbnail;
            _duration = duration;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            else if (widget.uploadState.thumbnailUrl != null)
              // 优先使用网络缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: CachedNetworkImage(
                  imageUrl: widget.uploadState.thumbnailUrl!,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CupertinoActivityIndicator()),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 32,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              )
            else if (_thumbnailFile != null)
              // 使用本地缩略图
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

            // 上传状态覆盖层（pending 和 uploading 都显示进度）
            if (widget.uploadState.status == VideoUploadStatus.pending ||
                widget.uploadState.status == VideoUploadStatus.uploading)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: widget.uploadState.progress.isFinite
                              ? widget.uploadState.progress.clamp(0.0, 1.0)
                              : 0.0,
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primaryColor,
                          ),
                          backgroundColor: AppColors.dividerLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.uploadState.progress.isFinite
                            ? '${(widget.uploadState.progress * 100).toInt()}%'
                            : '0%',
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.backgroundWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (widget.uploadState.status == VideoUploadStatus.error)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: 24,
                        color: CupertinoColors.systemRed,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.videoUploadFailed,
                        style: AppTextStyles.caption2.copyWith(
                          color: AppColors.backgroundWhite,
                        ),
                      ),
                      if (widget.onRetry != null) ...[
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          color: AppColors.primaryColor,
                          onPressed: widget.onRetry,
                          child: Text(
                            l10n.retryUpload,
                            style: AppTextStyles.caption2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else if (widget.uploadState.status == VideoUploadStatus.completed)
              // 播放图标叠加层（只在完成时显示）
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
