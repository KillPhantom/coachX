import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:coach_x/core/models/media_upload_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 媒体缩略图卡片
///
/// 显示视频/图片缩略图、播放图标(仅视频)、删除按钮和上传状态
class MediaThumbnailCard extends StatefulWidget {
  final MediaUploadState uploadState;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRetry;
  final double width;
  final double height;

  const MediaThumbnailCard({
    super.key,
    required this.uploadState,
    required this.onTap,
    required this.onDelete,
    this.onRetry,
    this.width = 100,
    this.height = 100,
  });

  @override
  State<MediaThumbnailCard> createState() => _MediaThumbnailCardState();
}

class _MediaThumbnailCardState extends State<MediaThumbnailCard> {
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 缩略图 / 图片
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: _buildContent(),
          ),
        ),

        // 播放图标 (仅视频)
        if (widget.uploadState.type == MediaType.video &&
            widget.uploadState.status == MediaUploadStatus.completed)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.play_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

        // 点击区域
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: widget.onTap,
            ),
          ),
        ),

        // 错误重试按钮
        if (widget.uploadState.status == MediaUploadStatus.error &&
            widget.onRetry != null)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: widget.onRetry,
                ),
              ),
            ),
          ),

        // 进度覆盖层 (Upload/Pending/Compressing)
        if (widget.uploadState.status == MediaUploadStatus.pending ||
            widget.uploadState.status == MediaUploadStatus.compressing ||
            widget.uploadState.status == MediaUploadStatus.uploading)
          _buildProgressOverlay(),

        // 删除按钮 (Moved to end to be on top of overlay)
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // 1. 本地文件（优先显示本地，响应更快）
    if (widget.uploadState.localPath != null) {
      if (widget.uploadState.type == MediaType.image) {
        return Image.file(
          File(widget.uploadState.localPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
        );
      } else {
        // Video local thumbnail
        if (widget.uploadState.thumbnailPath != null) {
          return Image.file(
            File(widget.uploadState.thumbnailPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
          );
        } else {
            // Video but no thumbnail yet -> Spinner
            return _buildLoadingPlaceholder();
        }
      }
    }

    // 2. 网络文件
    if (widget.uploadState.downloadUrl != null) {
       if (widget.uploadState.type == MediaType.image) {
         return CachedNetworkImage(
           imageUrl: widget.uploadState.downloadUrl!,
           fit: BoxFit.cover,
           placeholder: (context, url) => _buildLoadingPlaceholder(),
           errorWidget: (context, url, error) => _buildErrorPlaceholder(),
         );
       } else {
         // Video network thumbnail
         if (widget.uploadState.thumbnailUrl != null) {
           return CachedNetworkImage(
             imageUrl: widget.uploadState.thumbnailUrl!,
             fit: BoxFit.cover,
             placeholder: (context, url) => _buildLoadingPlaceholder(),
             errorWidget: (context, url, error) => _buildErrorPlaceholder(),
           );
         }
         // No thumbnail for network video -> Placeholder
         return _buildDefaultPlaceholder();
       }
    }

    // 3. 上传中/处理中 (Covered by overlays, but if no path yet)
    // This case might happen if localPath is null but status is pending/uploading?
    // Unlikely for pending/uploading created locally.
    if (widget.uploadState.status == MediaUploadStatus.pending ||
        widget.uploadState.status == MediaUploadStatus.compressing ||
        widget.uploadState.status == MediaUploadStatus.uploading) {
      return _buildLoadingPlaceholder();
    }

    // 4. 默认占位
    return _buildDefaultPlaceholder();
  }
  
  Widget _buildDefaultPlaceholder() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: Center(
        child: Icon(
          widget.uploadState.type == MediaType.video 
              ? CupertinoIcons.film 
              : CupertinoIcons.photo,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
  
  Widget _buildProgressOverlay() {
      return Positioned.fill(
        child: Container(
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
        ),
      );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
