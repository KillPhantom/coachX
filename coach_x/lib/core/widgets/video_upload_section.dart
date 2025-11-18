import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/enums/video_source.dart';
import 'package:coach_x/core/models/video_upload_state.dart';
import 'package:coach_x/core/services/video_service.dart';
import 'package:coach_x/core/providers/video_upload_providers.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/video_thumbnail_card.dart';
import 'package:coach_x/core/widgets/video_placeholder_card.dart';
import 'package:coach_x/core/widgets/video_player_dialog.dart';

/// 通用视频上传组件
///
/// 自管理状态，支持多视频上传，包含完整上传流程
class VideoUploadSection extends ConsumerStatefulWidget {
  /// Storage 路径前缀（如: "exercise_videos/{coachId}/"）
  final String storagePathPrefix;

  /// 最大视频数量
  final int maxVideos;

  /// 最大视频时长（秒）
  final int maxSeconds;

  /// 压缩阈值（MB）
  final int compressionThresholdMB;

  /// 视频源选项
  final VideoSource videoSource;

  /// 初始视频状态列表（推荐使用，包含完整的视频和缩略图信息）
  final List<VideoUploadState>? initialVideos;

  /// 初始视频 URLs（用于编辑模式）
  /// @deprecated 使用 initialVideos 代替，以保留缩略图信息
  @Deprecated('Use initialVideos instead to preserve thumbnail URLs')
  final List<String>? initialVideoUrls;

  /// 视频选择回调
  final void Function(int index, File file)? onVideoSelected;

  /// 上传进度回调
  final void Function(int index, double progress)? onUploadProgress;

  /// 上传完成回调
  final void Function(int index, String videoUrl, String? thumbnailUrl)?
  onUploadCompleted;

  /// 上传失败回调
  final void Function(int index, String error)? onUploadFailed;

  /// 视频删除回调
  final void Function(int index)? onVideoDeleted;

  /// 卡片宽度
  final double cardWidth;

  /// 卡片高度
  final double cardHeight;

  const VideoUploadSection({
    super.key,
    required this.storagePathPrefix,
    this.maxVideos = 3,
    this.maxSeconds = 60,
    this.compressionThresholdMB = 50,
    this.videoSource = VideoSource.both,
    this.initialVideos,
    this.initialVideoUrls,
    this.onVideoSelected,
    this.onUploadProgress,
    this.onUploadCompleted,
    this.onUploadFailed,
    this.onVideoDeleted,
    this.cardWidth = 100.0,
    this.cardHeight = 100.0,
  });

  @override
  ConsumerState<VideoUploadSection> createState() => _VideoUploadSectionState();
}

class _VideoUploadSectionState extends ConsumerState<VideoUploadSection> {
  final List<VideoUploadState> _videos = [];
  final Map<int, StreamSubscription<double>> _uploadSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  @override
  void dispose() {
    _cancelAllUploads();
    super.dispose();
  }

  /// 初始化已有视频
  void _initializeVideos() {
    // 优先使用 initialVideos（包含完整的视频状态，包括 thumbnailUrl）
    if (widget.initialVideos != null && widget.initialVideos!.isNotEmpty) {
      setState(() {
        _videos.addAll(widget.initialVideos!);
      });
      return;
    }

    // 降级支持旧的 initialVideoUrls（向后兼容，但会丢失 thumbnailUrl）
    if (widget.initialVideoUrls != null &&
        widget.initialVideoUrls!.isNotEmpty) {
      setState(() {
        _videos.addAll(
          widget.initialVideoUrls!.map(
            (url) => VideoUploadState.completed(url),
          ),
        );
      });
    }
  }

  /// 取消所有上传
  void _cancelAllUploads() {
    for (final subscription in _uploadSubscriptions.values) {
      subscription.cancel();
    }
    _uploadSubscriptions.clear();
  }

  bool get canAddMore => _videos.length < widget.maxVideos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          l10n.myRecordings,
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppDimensions.spacingS),

        // 视频列表（横向滚动）
        SizedBox(
          height: widget.cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _videos.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 显示已有视频
              if (index < _videos.length) {
                final videoState = _videos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                  child: VideoThumbnailCard(
                    uploadState: videoState,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    onTap: () => _handleVideoTap(index),
                    onDelete: () => _handleVideoDelete(index),
                    onRetry: videoState.status == VideoUploadStatus.error
                        ? () => _handleVideoRetry(index)
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
                  onTap: _showVideoSourceOptions,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 处理视频点击（播放）
  void _handleVideoTap(int index) {
    if (_videos[index].status != VideoUploadStatus.completed) return;

    // 获取所有已完成视频的URL
    final completedVideos = _videos
        .where(
          (v) =>
              v.status == VideoUploadStatus.completed && v.downloadUrl != null,
        )
        .map((v) => v.downloadUrl!)
        .toList();

    final initialIndex = completedVideos.indexOf(_videos[index].downloadUrl!);

    // 显示播放器
    VideoPlayerDialog.show(
      context,
      videoUrls: completedVideos,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  /// 处理视频删除
  void _handleVideoDelete(int index) {
    setState(() {
      // 取消上传（如果正在上传）
      _uploadSubscriptions[index]?.cancel();
      _uploadSubscriptions.remove(index);

      // 移除视频
      _videos.removeAt(index);
    });

    // 通知父组件
    widget.onVideoDeleted?.call(index);
  }

  /// 处理视频重试
  void _handleVideoRetry(int index) {
    if (_videos[index].localPath == null) return;

    AppLogger.info('重试上传视频: index=$index');

    // 重置状态为 pending
    setState(() {
      _videos[index] = _videos[index].copyWith(
        status: VideoUploadStatus.pending,
        progress: 0.0,
        error: null,
      );
    });

    // 重新启动上传
    _startUpload(index, File(_videos[index].localPath!));
  }

  /// 显示视频源选择
  void _showVideoSourceOptions() {
    AppLogger.info('显示视频源选择对话框');
    final l10n = AppLocalizations.of(context)!;

    // 根据配置显示不同选项
    final List<CupertinoActionSheetAction> actions = [];

    if (widget.videoSource == VideoSource.cameraOnly ||
        widget.videoSource == VideoSource.both) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () {
            AppLogger.info('用户选择: 相机录制');
            Navigator.pop(context);
            _handleCameraRecord();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.videocam, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                l10n.recordingVideo,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.videoSource == VideoSource.galleryOnly ||
        widget.videoSource == VideoSource.both) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () {
            AppLogger.info('用户选择: 从相册选择');
            Navigator.pop(context);
            _handleGallerySelect();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.photo, color: AppColors.textPrimary),
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
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.recordVideo),
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            AppLogger.info('用户取消了选择');
            Navigator.pop(context);
          },
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 处理相机录制
  Future<void> _handleCameraRecord() async {
    AppLogger.info('开始相机录制视频');
    final picker = ImagePicker();

    try {
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: widget.maxSeconds),
      );

      AppLogger.info(
        '相机录制结果: ${video != null ? "已录制视频 ${video.path}" : "未录制视频（用户取消）"}',
      );

      if (video != null) {
        if (!mounted) {
          AppLogger.info('⚠️ Context已卸载，但继续处理');
        }
        AppLogger.info('✅ 开始处理录制的视频: ${video.path}');
        await _processAndUploadVideo(File(video.path));
        AppLogger.info('✅ 录制视频处理完成');
      } else {
        AppLogger.info('ℹ️ 用户取消了视频录制');
      }
    } catch (e, stackTrace) {
      AppLogger.error('相机录制失败', e, stackTrace);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showErrorAlert(l10n.videoProcessingFailed);
    }
  }

  /// 处理相册选择
  Future<void> _handleGallerySelect() async {
    AppLogger.info('开始从相册选择视频（使用FilePicker）');

    try {
      AppLogger.info('调用 FilePicker.pickFiles...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      AppLogger.info(
        '相册选择结果: ${result != null && result.files.isNotEmpty ? "已选择视频 ${result.files.first.path}" : "未选择视频（用户取消）"}',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;

        if (filePath == null) {
          AppLogger.error('❌ 视频文件路径为null');
          if (mounted) {
            _showErrorAlert('视频文件无法访问');
          }
          return;
        }

        final file = File(filePath);
        final exists = await file.exists();
        AppLogger.info('视频文件是否存在: $exists (path: $filePath)');

        if (!exists) {
          AppLogger.error('❌ 视频文件不存在: $filePath');
          if (mounted) {
            _showErrorAlert('视频文件无法访问');
          }
          return;
        }

        if (!mounted) {
          AppLogger.info('⚠️ Context已卸载，但继续处理视频上传');
        }

        AppLogger.info('✅ 开始处理视频: $filePath');
        await _processAndUploadVideo(file);
        AppLogger.info('✅ 视频处理完成');
      } else {
        AppLogger.info('ℹ️ 用户取消了视频选择');
      }
    } catch (e, stackTrace) {
      AppLogger.error('相册选择失败', e, stackTrace);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _showErrorAlert(l10n.videoProcessingFailed);
    }
  }

  /// 处理视频（验证 + 压缩 + 上传）
  Future<void> _processAndUploadVideo(File videoFile) async {
    AppLogger.info('开始处理视频: ${videoFile.path}');

    try {
      // 1. 验证时长
      AppLogger.info('⏱️ 验证视频时长（最大: ${widget.maxSeconds}秒）');
      final isValid = await VideoUtils.validateVideoFile(
        videoFile,
        maxSeconds: widget.maxSeconds,
      );

      AppLogger.info('✅ 视频时长验证结果: ${isValid ? "通过" : "超时"}');

      if (!isValid) {
        AppLogger.info('❌ 视频时长超过限制');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showErrorAlert(l10n.videoTooLongMessage);
        } else {
          AppLogger.info('⚠️ Context已卸载，无法显示错误提示');
        }
        return;
      }

      // 2. 生成缩略图
      AppLogger.info('🖼️ 生成视频缩略图');
      final thumbnail = await VideoUtils.generateThumbnail(videoFile.path);
      AppLogger.info(
        '缩略图生成结果: ${thumbnail != null ? "成功 ${thumbnail.path}" : "失败"}',
      );

      // 3. 添加到列表（pending 状态）
      final videoIndex = _videos.length;
      setState(() {
        _videos.add(VideoUploadState.pending(videoFile.path, thumbnail?.path));
      });

      // 4. 通知父组件
      widget.onVideoSelected?.call(videoIndex, videoFile);

      // 5. 启动后台上传
      AppLogger.info('🚀 启动后台上传');
      await _compressAndUpload(videoIndex, videoFile);
    } catch (e, stackTrace) {
      AppLogger.error('视频处理失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorAlert(l10n.videoProcessingFailed);
      } else {
        AppLogger.info('⚠️ Context已卸载，无法显示错误对话框');
      }
    }
  }

  /// 压缩并上传视频
  Future<void> _compressAndUpload(int index, File originalFile) async {
    File finalFile = originalFile;

    try {
      // 条件压缩
      AppLogger.info('📦 检查视频是否需要压缩');
      final shouldCompress = await VideoService.shouldCompress(
        originalFile,
        thresholdMB: widget.compressionThresholdMB,
      );

      AppLogger.info('📦 压缩检查结果: ${shouldCompress ? "需要压缩" : "不需要压缩"}');

      if (shouldCompress) {
        AppLogger.info('视频超过 ${widget.compressionThresholdMB}MB，开始后台压缩');
        finalFile = await VideoService.compressVideo(
          originalFile,
          quality: VideoQuality.MediumQuality,
        );
        AppLogger.info('视频压缩完成');
      }
    } catch (e) {
      AppLogger.error('视频压缩失败，使用原文件上传', e);
    }

    // 启动上传
    _startUpload(index, finalFile);
  }

  /// 启动异步上传
  void _startUpload(int index, File videoFile) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${widget.storagePathPrefix}$timestamp.mp4';

    AppLogger.info('开始上传: $path');

    final uploadService = ref.read(videoUploadServiceProvider);

    // 监听上传进度
    final subscription = uploadService
        .uploadVideoWithProgress(videoFile, path)
        .listen(
          (progress) {
            // 实时更新进度
            if (mounted) {
              setState(() {
                if (index < _videos.length) {
                  _videos[index] = _videos[index].copyWith(
                    status: VideoUploadStatus.uploading,
                    progress: progress,
                  );
                }
              });
            }

            widget.onUploadProgress?.call(index, progress);

            if (progress.isFinite) {
              AppLogger.info('上传进度: ${(progress * 100).toInt()}%');
            } else {
              AppLogger.info('上传进度: 无效值 (NaN/Infinity)');
            }
          },
          onDone: () async {
            try {
              // 1. 上传完成，获取下载 URL
              final downloadUrl = await uploadService.getDownloadUrl(path);
              AppLogger.info('视频上传成功: $downloadUrl');

              // 2. 上传缩略图
              String? thumbnailUrl;
              if (index < _videos.length &&
                  _videos[index].thumbnailPath != null) {
                try {
                  AppLogger.info('开始上传缩略图');
                  final thumbnailPath = path
                      .replaceAll('exercise_videos/', 'exercise_thumbnails/')
                      .replaceAll('.mp4', '_thumb.jpg');
                  thumbnailUrl = await uploadService.uploadThumbnail(
                    File(_videos[index].thumbnailPath!),
                    thumbnailPath,
                  );
                  AppLogger.info('缩略图上传成功: $thumbnailUrl');
                } catch (e) {
                  AppLogger.error('缩略图上传失败，继续保存视频', e);
                }
              }

              // 3. 完成上传
              if (mounted) {
                setState(() {
                  if (index < _videos.length) {
                    _videos[index] = _videos[index].copyWith(
                      downloadUrl: downloadUrl,
                      thumbnailUrl: thumbnailUrl,
                      status: VideoUploadStatus.completed,
                      progress: 1.0,
                    );
                  }
                });
              }

              // 4. 通知父组件
              widget.onUploadCompleted?.call(index, downloadUrl, thumbnailUrl);

              AppLogger.info('视频记录保存成功');
            } catch (e) {
              AppLogger.error('视频上传流程失败', e);
              _failUpload(index, '上传失败');
            }
          },
          onError: (error) {
            AppLogger.error('视频上传失败', error);
            _failUpload(index, error.toString());
          },
        );

    _uploadSubscriptions[index] = subscription;
  }

  /// 标记上传失败
  void _failUpload(int index, String error) {
    if (mounted) {
      setState(() {
        if (index < _videos.length) {
          _videos[index] = _videos[index].copyWith(
            status: VideoUploadStatus.error,
            error: error,
          );
        }
      });
    }

    widget.onUploadFailed?.call(index, error);

    _uploadSubscriptions.remove(index);
  }

  /// 显示错误提示
  void _showErrorAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
