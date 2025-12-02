import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/models/media_upload_state.dart';
import 'package:coach_x/core/providers/media_upload_providers.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/media_thumbnail_card.dart';
import 'package:coach_x/core/widgets/video_placeholder_card.dart';
import 'package:coach_x/core/widgets/video_player_dialog.dart';
import 'package:coach_x/core/widgets/full_screen_image_viewer.dart';

/// 通用媒体上传组件 (图片 + 视频)
///
/// 自管理状态，支持多文件上传，包含完整上传流程
class MediaUploadSection extends ConsumerStatefulWidget {
  /// Storage 路径前缀（如: "exercise_videos/{coachId}/"）
  final String storagePathPrefix;

  /// 最大媒体数量
  final int maxCount;

  /// 最大视频时长（秒）
  final int maxVideoSeconds;

  /// 视频压缩阈值（MB）
  final int videoCompressionThresholdMB;

  /// 初始媒体状态列表
  final List<MediaUploadState>? initialMedia;

  /// 媒体选择回调
  final void Function(int index, File file, MediaType type)? onMediaSelected;

  /// 上传进度回调
  final void Function(int index, double progress)? onUploadProgress;

  /// 上传完成回调
  final void Function(int index, String url, String? thumbnailUrl, MediaType type)?
  onUploadCompleted;

  /// 上传失败回调
  final void Function(int index, String error)? onUploadFailed;

  /// 媒体删除回调
  final void Function(int index)? onMediaDeleted;

  /// 卡片宽度
  final double cardWidth;

  /// 卡片高度
  final double cardHeight;

  const MediaUploadSection({
    super.key,
    required this.storagePathPrefix,
    this.maxCount = 3,
    this.maxVideoSeconds = 60,
    this.videoCompressionThresholdMB = 50,
    this.initialMedia,
    this.onMediaSelected,
    this.onUploadProgress,
    this.onUploadCompleted,
    this.onUploadFailed,
    this.onMediaDeleted,
    this.cardWidth = 100.0,
    this.cardHeight = 100.0,
  });

  @override
  ConsumerState<MediaUploadSection> createState() => _MediaUploadSectionState();
}

class _MediaUploadSectionState extends ConsumerState<MediaUploadSection> {
  final List<MediaUploadState> _mediaList = [];
  final List<String> _mediaIds = []; // Track IDs to handle index shifting
  final Map<String, StreamSubscription<double>> _uploadSubscriptions = {};
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false; // Track if the picker is currently active/processing

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(MediaUploadSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步 Riverpod state 到本地显示
    if (widget.initialMedia != oldWidget.initialMedia) {
      _syncMediaFromProps();
    }
  }

  @override
  void dispose() {
    _cancelAllUploads();
    super.dispose();
  }

  /// 同步 props 中的媒体状态到本地列表
  void _syncMediaFromProps() {
    setState(() {
      _mediaList.clear();
      _mediaIds.clear();
      if (widget.initialMedia != null && widget.initialMedia!.isNotEmpty) {
        _mediaList.addAll(widget.initialMedia!);
        // 为同步的媒体生成 ID
        for (var i = 0; i < widget.initialMedia!.length; i++) {
          _mediaIds.add('synced_${DateTime.now().microsecondsSinceEpoch}_$i');
        }
      }
    });
  }

  /// 初始化已有媒体
  void _initializeMedia() {
    if (widget.initialMedia != null && widget.initialMedia!.isNotEmpty) {
      setState(() {
        _mediaList.addAll(widget.initialMedia!);
        // Generate IDs for initial items
        for (var i = 0; i < widget.initialMedia!.length; i++) {
          _mediaIds.add('initial_${DateTime.now().microsecondsSinceEpoch}_$i');
        }
      });
    }
  }

  /// 取消所有上传订阅
  void _cancelAllUploads() {
    for (final subscription in _uploadSubscriptions.values) {
      subscription.cancel();
    }
    _uploadSubscriptions.clear();
    // 压缩和上传任务由 MediaUploadManager 管理，不需要在此清理
  }

  bool get canAddMore => _mediaList.length < widget.maxCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          l10n.myRecordings, // 可以改为更通用的 "Media" 或 "My Uploads"
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppDimensions.spacingS),

        // 媒体列表（横向滚动）
        SizedBox(
          height: widget.cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mediaList.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 显示已有媒体
              if (index < _mediaList.length) {
                final mediaState = _mediaList[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                  child: MediaThumbnailCard(
                    uploadState: mediaState,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    onTap: () => _handleMediaTap(index),
                    onDelete: () => _handleMediaDelete(index),
                    onRetry: mediaState.status == MediaUploadStatus.error
                        ? () => _handleMediaRetry(index)
                        : null,
                  ),
                );
              }

              // 显示添加按钮
              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                child: VideoPlaceholderCard(
                  width: widget.cardWidth,
                  height: widget.cardHeight,
                  onTap: _isPicking ? () {} : _showMediaSourceOptions, // Disable tap while picking
                  // Show spinner if picking, otherwise camera icon
                  child: _isPicking 
                      ? const Center(child: CupertinoActivityIndicator()) 
                      : null,
                  icon: _isPicking ? null : CupertinoIcons.camera_fill, 
                  text: _isPicking ? null : 'Add',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 处理媒体点击（查看/播放）
  void _handleMediaTap(int index) {
    final media = _mediaList[index];
    if (media.status != MediaUploadStatus.completed) return;

    if (media.type == MediaType.video) {
        // 播放视频
        final completedVideos = _mediaList
            .where((m) => m.type == MediaType.video && m.status == MediaUploadStatus.completed && m.downloadUrl != null)
            .map((m) => m.downloadUrl!)
            .toList();
        
        final initialIndex = completedVideos.indexOf(media.downloadUrl!);
        
        VideoPlayerDialog.show(
            context,
            videoUrls: completedVideos,
            initialIndex: initialIndex >= 0 ? initialIndex : 0,
        );
    } else {
        // 查看图片
        if (media.downloadUrl != null) {
            FullScreenImageViewer.show(context, media.downloadUrl!);
        }
    }
  }

  /// 处理媒体删除
  void _handleMediaDelete(int index) {
    setState(() {
      final id = _mediaIds[index];

      // 取消上传订阅（如果存在）
      _uploadSubscriptions[id]?.cancel();
      _uploadSubscriptions.remove(id);

      // 移除媒体
      _mediaList.removeAt(index);
      _mediaIds.removeAt(index);
    });

    // 通知父组件（会取消 MediaUploadManager 的任务）
    widget.onMediaDeleted?.call(index);
  }

  /// 处理媒体重试
  void _handleMediaRetry(int index) {
    if (_mediaList[index].localPath == null) return;

    AppLogger.info('重试上传: index=$index');

    // 通知父组件重新上传，由 MediaUploadManager 处理
    final media = _mediaList[index];
    widget.onMediaSelected?.call(index, File(media.localPath!), media.type);
  }

  /// 显示媒体源选择
  void _showMediaSourceOptions() {
    AppLogger.info('显示媒体源选择对话框');
    final l10n = AppLocalizations.of(context)!;

    final List<CupertinoActionSheetAction> actions = [];

    // 选项 1: 录制视频
    actions.add(
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          _handleCameraRecord();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.videocam, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              l10n.recordVideo,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    // 选项 2: 从相册选择 (图片或视频)
    actions.add(
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          _handleGallerySelect();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.photo_on_rectangle, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              l10n.selectFromGallery,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
    
    // 选项 3: 拍照
    actions.add(
      CupertinoActionSheetAction(
        onPressed: () {
            Navigator.pop(context);
            _handleCameraPhoto();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(CupertinoIcons.camera, color: AppColors.textPrimary),
             const SizedBox(width: 8),
             Text(
              l10n.takePhoto,
               style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
               ),
             ),
          ],
        ),
      ),
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(l10n.cancel, style: AppTextStyles.body),
        ),
      ),
    );
  }

  /// 处理相机录制 (仅视频)
  Future<void> _handleCameraRecord() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: widget.maxVideoSeconds),
      );

      if (video != null) {
        await _processAndUploadMedia(File(video.path), MediaType.video);
      }
    } catch (e, stackTrace) {
      AppLogger.error('相机录制失败', e, stackTrace);
      if (mounted) _showErrorAlert('Failed to record video');
    }
  }

    /// 处理相机拍照
  Future<void> _handleCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (photo != null) {
        await _processAndUploadMedia(File(photo.path), MediaType.image);
      }
    } catch (e, stackTrace) {
      AppLogger.error('拍照失败', e, stackTrace);
      if (mounted) _showErrorAlert('Failed to take photo');
    }
  }

  /// 处理相册选择 (多选，混合)
  Future<void> _handleGallerySelect() async {
    try {
      setState(() => _isPicking = true);

      // pickMultipleMedia 支持同时选择图片和视频
      // Note: On iOS, this might take a moment to copy large files from iCloud/Gallery
      final List<XFile> medias = await _picker.pickMultipleMedia();

      if (medias.isNotEmpty) {
        for (final media in medias) {
          // 检查数量限制
          if (_mediaList.length >= widget.maxCount) {
             if (mounted) _showErrorAlert('Maximum ${_mediaList.length} media items allowed');
             break;
          }
          
          final file = File(media.path);
          // 简单的类型判断，也可以根据 mimeType
          final pathLower = media.path.toLowerCase();
          final isVideo = pathLower.endsWith('.mp4') || pathLower.endsWith('.mov') || pathLower.endsWith('.avi');
          final type = isVideo ? MediaType.video : MediaType.image;

          // Don't await here so the UI updates immediately with the placeholder
          // Also allows processing multiple files in parallel (asynchronously)
          _processAndUploadMedia(file, type);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('相册选择失败', e, stackTrace);
      if (mounted) _showErrorAlert('Failed to select media');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  /// 处理媒体文件（选择并通知父组件）
  Future<void> _processAndUploadMedia(File file, MediaType type) async {
    AppLogger.info('选择媒体: ${file.path}, 类型: $type');

    // 只通知父组件，由父组件（Notifier）负责添加到状态并启动上传
    // MediaUploadManager 会处理缩略图生成、验证、压缩和上传
    widget.onMediaSelected?.call(_mediaList.length, file, type);
  }

  /// 启动异步上传
  void _startUpload(String id, File file, MediaType type) {
    // Check if item still exists
    if (!_mediaIds.contains(id)) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = type == MediaType.video ? 'mp4' : 'jpg'; // 简化后缀处理，实际应根据文件类型
    final path = '${widget.storagePathPrefix}$timestamp.$ext';
    final contentType = type == MediaType.video ? 'video/mp4' : 'image/jpeg';

    AppLogger.info('开始上传: $path');

    final uploadService = ref.read(mediaUploadServiceProvider);

    // 监听上传进度
    final subscription = uploadService
        .uploadFileWithProgress(file, path, contentType: contentType)
        .listen(
          (progress) {
            if (mounted) {
              setState(() {
                final index = _mediaIds.indexOf(id);
                if (index != -1) {
                  // 上传进度映射到 60-100%
                  // 如果之前没有压缩（progress < 0.6），则使用原始进度
                  final currentProgress = _mediaList[index].progress;
                  final displayProgress = currentProgress < 0.6
                      ? progress  // 没有压缩阶段，直接显示上传进度
                      : 0.6 + (progress * 0.4);  // 有压缩阶段，映射到 60-100%

                  _mediaList[index] = _mediaList[index].copyWith(
                    status: MediaUploadStatus.uploading,
                    progress: displayProgress,
                  );
                  widget.onUploadProgress?.call(index, displayProgress);
                }
              });
            }
          },
          onDone: () async {
            try {
              // 2. 上传缩略图 (仅视频)
              Future<String?>? thumbnailUploadFuture;
              
              // Re-check index as async await happened
              int index = _mediaIds.indexOf(id);
              if (index != -1 && type == MediaType.video && _mediaList[index].thumbnailPath != null) {
                      final thumbPath = path.replaceAll('.$ext', '_thumb.jpg');
                  // Start thumbnail upload concurrently
                  thumbnailUploadFuture = uploadService.uploadThumbnail(
                          File(_mediaList[index].thumbnailPath!),
                          thumbPath,
                  ).then<String?>((url) => url).catchError((e) {
                      AppLogger.error('缩略图上传失败', e);
                      return null;
                  });
              }

              // 1. 获取下载 URL (Video upload is already done at this point)
              final downloadUrl = await uploadService.getDownloadUrl(path);

              // Wait for thumbnail upload to complete if it started
              final thumbnailUrl = thumbnailUploadFuture != null 
                  ? await thumbnailUploadFuture 
                  : null;

              // 3. 完成上传
              if (mounted) {
                setState(() {
                  index = _mediaIds.indexOf(id); // Re-check index
                  if (index != -1) {
                    _mediaList[index] = _mediaList[index].copyWith(
                      downloadUrl: downloadUrl,
                      thumbnailUrl: thumbnailUrl,
                      status: MediaUploadStatus.completed,
                      progress: 1.0,
                    );
                    
                    // 4. 通知父组件
                    widget.onUploadCompleted?.call(index, downloadUrl, thumbnailUrl, type);
                  }
                });
              }
              
            } catch (e) {
              AppLogger.error('上传流程失败', e);
              _failUpload(id, 'Upload failed');
            }
          },
          onError: (error) {
            AppLogger.error('上传失败', error);
            _failUpload(id, error.toString());
          },
        );

    _uploadSubscriptions[id] = subscription;
  }

  /// 标记上传失败
  void _failUpload(String id, String error) {
    if (mounted) {
      setState(() {
        final index = _mediaIds.indexOf(id);
        if (index != -1) {
          _mediaList[index] = _mediaList[index].copyWith(
            status: MediaUploadStatus.error,
            error: error,
          );
          widget.onUploadFailed?.call(index, error);
        }
      });
    }
    
    _uploadSubscriptions.remove(id);
  }

  /// 显示错误提示
  void _showErrorAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'), // TODO: l10n
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

