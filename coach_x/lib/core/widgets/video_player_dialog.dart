import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/core/providers/cache_providers.dart';

/// 视频播放对话框（全屏）
///
/// 支持单个或多个视频播放，多个视频时支持横向滑动切换
/// 使用 CachedVideoPlayerPlus 实现视频缓存，提升重复播放速度
class VideoPlayerDialog extends ConsumerStatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;
  final String? dailyTrainingId;
  final int? exerciseIndex;
  final String? exerciseName;

  const VideoPlayerDialog({
    super.key,
    required this.videoUrls,
    this.initialIndex = 0,
    this.dailyTrainingId,
    this.exerciseIndex,
    this.exerciseName,
  });

  /// 显示视频播放对话框
  static Future<void> show(
    BuildContext context, {
    required List<String> videoUrls,
    int initialIndex = 0,
    String? dailyTrainingId,
    int? exerciseIndex,
    String? exerciseName,
  }) {
    return showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VideoPlayerDialog(
        videoUrls: videoUrls,
        initialIndex: initialIndex,
        dailyTrainingId: dailyTrainingId,
        exerciseIndex: exerciseIndex,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  ConsumerState<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends ConsumerState<VideoPlayerDialog> {
  late PageController _pageController;
  int _currentPage = 0;
  List<CachedVideoPlayerPlus?> _controllers = [];
  List<bool> _initialized = [];
  List<bool> _hasError = [];

  // 手动截帧相关状态
  String? _downloadedVideoPath;
  bool _isPredownloading = false;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeControllersList();
    _initializeVideo(_currentPage);

    // 如果有截帧参数，预下载视频
    if (widget.dailyTrainingId != null && widget.exerciseIndex != null) {
      _predownloadVideoForExtraction();
    }
  }

  void _initializeControllersList() {
    _controllers = List.filled(widget.videoUrls.length, null);
    _initialized = List.filled(widget.videoUrls.length, false);
    _hasError = List.filled(widget.videoUrls.length, false);
  }

  Future<void> _initializeVideo(int index) async {
    if (index < 0 || index >= widget.videoUrls.length) return;
    if (_initialized[index] || _controllers[index] != null) return;

    try {
      AppLogger.info('开始初始化视频 $index: ${widget.videoUrls[index]}');

      final player = CachedVideoPlayerPlus.networkUrl(
        Uri.parse(widget.videoUrls[index]),
        invalidateCacheIfOlderThan: const Duration(days: 7),
      );

      _controllers[index] = player;

      await player.initialize();

      if (mounted) {
        setState(() {
          _initialized[index] = true;
          _hasError[index] = false;
        });

        // 添加监听器以实时更新UI
        player.controller.addListener(() {
          if (mounted) setState(() {});
        });

        // 自动播放
        player.controller.play();
        AppLogger.info('视频 $index 初始化成功');
      }
    } catch (e, stackTrace) {
      AppLogger.error('视频 $index 初始化失败', e, stackTrace);
      if (mounted) {
        setState(() {
          _hasError[index] = true;
          _initialized[index] = false;
        });
      }
    }
  }

  /// 后台预下载视频（不阻塞播放）
  Future<void> _predownloadVideoForExtraction() async {
    if (_isPredownloading) return;

    setState(() => _isPredownloading = true);
    try {
      final videoUrl = widget.videoUrls[_currentPage];
      AppLogger.info('Pre-downloading video for manual extraction');

      final downloader = ref.read(videoDownloaderProvider);
      _downloadedVideoPath = await downloader.downloadVideo(
        videoUrl,
        widget.dailyTrainingId!,
      );

      AppLogger.info('Video pre-downloaded: $_downloadedVideoPath');
    } catch (e) {
      AppLogger.warning('Failed to pre-download video: $e');
      // 静默失败，点击截帧时会重试
    } finally {
      if (mounted) {
        setState(() => _isPredownloading = false);
      }
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      // 暂停当前视频
      if (_currentPage >= 0 &&
          _currentPage < _controllers.length &&
          _controllers[_currentPage] != null) {
        _controllers[_currentPage]?.controller.pause();
      }
      _currentPage = page;
    });

    // 初始化并播放新视频
    if (!_initialized[page]) {
      _initializeVideo(page);
    } else if (_controllers[page] != null) {
      _controllers[page]?.controller.play();
    }

    // 切换视频时预下载新视频
    if (widget.dailyTrainingId != null && widget.exerciseIndex != null) {
      _downloadedVideoPath = null; // 清空旧的
      _predownloadVideoForExtraction(); // 下载新的
    }
  }

  void _retryVideo(int index) {
    setState(() {
      _controllers[index]?.dispose();
      _controllers[index] = null;
      _initialized[index] = false;
      _hasError[index] = false;
    });
    _initializeVideo(index);
  }

  /// 处理手动提取关键帧
  Future<void> _handleManualExtract() async {
    if (_isExtracting) return;

    setState(() => _isExtracting = true);

    try {
      final controller = _controllers[_currentPage]!.controller;
      final position = controller.value.position;
      final videoUrl = widget.videoUrls[_currentPage];

      // 1. 确保视频已下载
      String? videoPath = _downloadedVideoPath;
      if (videoPath == null) {
        AppLogger.info('Video not pre-downloaded, downloading now...');
        final downloader = ref.read(videoDownloaderProvider);
        videoPath = await downloader.downloadVideo(
          videoUrl,
          widget.dailyTrainingId!,
        );
      }

      // 2. 截取当前帧
      final timestamp = position.inSeconds.toDouble();
      final framePath = await _extractFrame(videoPath, position.inMilliseconds);

      // 3. 保存到 Firestore
      await _saveManualKeyframe(
        framePath,
        timestamp,
        widget.dailyTrainingId!,
        widget.exerciseIndex!,
        widget.exerciseName ?? 'Unknown Exercise',
      );

      // 4. 显示成功提示
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessToast(l10n.frameExtracted);
      }

      AppLogger.info('Manual keyframe extracted at ${timestamp}s');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract manual keyframe', e, stackTrace);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(l10n.extractionFailed, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isExtracting = false);
      }
    }
  }

  /// 截取指定时间的视频帧
  Future<String> _extractFrame(String videoPath, int timeMs) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final framePath = path.join(
      tempDir.path,
      'manual_keyframes',
      'frame_${widget.dailyTrainingId}_${widget.exerciseIndex}_$timestamp.jpg',
    );

    // 确保目录存在
    final frameDir = Directory(path.dirname(framePath));
    if (!await frameDir.exists()) {
      await frameDir.create(recursive: true);
    }

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: framePath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      quality: 90,
    );

    if (thumbnailPath == null || thumbnailPath.isEmpty) {
      throw Exception('Failed to generate thumbnail');
    }

    return thumbnailPath;
  }

  /// 保存手动关键帧到 Firestore
  Future<void> _saveManualKeyframe(
    String framePath,
    double timestamp,
    String trainingId,
    int exerciseIndex,
    String exerciseName,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('dailyTrainings')
        .doc(trainingId);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      throw Exception('Training document not found');
    }

    final data = docSnapshot.data()!;
    final extractedKeyFrames = Map<String, dynamic>.from(
      data['extractedKeyFrames'] ?? {},
    );

    final exerciseKey = exerciseIndex.toString();
    final exerciseData = safeMapCast(
      extractedKeyFrames[exerciseKey],
      'exerciseData',
    );

    // 获取现有关键帧
    final existingKeyframes = exerciseData != null
        ? safeMapListCast(exerciseData['keyframes'], 'keyframes')
        : <Map<String, dynamic>>[];

    // 添加新关键帧
    final newKeyframe = {
      'localPath': framePath,
      'url': null,
      'timestamp': timestamp,
      'uploadStatus': 'pending',
    };

    existingKeyframes.add(newKeyframe);

    // 按 timestamp 排序
    existingKeyframes.sort((a, b) {
      final timestampA = (a['timestamp'] as num?)?.toDouble() ?? 0.0;
      final timestampB = (b['timestamp'] as num?)?.toDouble() ?? 0.0;
      return timestampA.compareTo(timestampB);
    });

    // 更新 Firestore
    extractedKeyFrames[exerciseKey] = {
      'exerciseName': exerciseName,
      'keyframes': existingKeyframes,
      'extractedAt': FieldValue.serverTimestamp(),
      'method': 'manual', // 标记为手动提取
    };

    await docRef.update({'extractedKeyFrames': extractedKeyFrames});

    // 后台上传到 Storage
    _uploadKeyframeInBackground(
      trainingId,
      exerciseIndex,
      framePath,
      existingKeyframes.length - 1,
    );
  }

  /// 后台上传关键帧
  void _uploadKeyframeInBackground(
    String trainingId,
    int exerciseIndex,
    String framePath,
    int frameIndex,
  ) {
    unawaited(
      _performBackgroundUpload(
        trainingId,
        exerciseIndex,
        framePath,
        frameIndex,
      ),
    );
  }

  Future<void> _performBackgroundUpload(
    String trainingId,
    int exerciseIndex,
    String framePath,
    int frameIndex,
  ) async {
    try {
      AppLogger.info('Uploading manual keyframe to Storage...');

      final storagePath =
          'training_keyframes/$trainingId/ex${exerciseIndex}_manual_frame$frameIndex.jpg';
      final file = File(framePath);
      final url = await StorageService.uploadFile(file, storagePath);

      // 更新 Firestore URL
      await _updateKeyframeUrl(trainingId, exerciseIndex, frameIndex, url);

      AppLogger.info('Manual keyframe uploaded: $url');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload manual keyframe', e, stackTrace);
    }
  }

  Future<void> _updateKeyframeUrl(
    String trainingId,
    int exerciseIndex,
    int frameIndex,
    String url,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('dailyTrainings')
          .doc(trainingId);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data()!;
      final extractedKeyFrames = Map<String, dynamic>.from(
        data['extractedKeyFrames'] ?? {},
      );

      final exerciseKey = exerciseIndex.toString();
      final exerciseData = safeMapCast(
        extractedKeyFrames[exerciseKey],
        'exerciseData',
      );

      if (exerciseData != null) {
        final keyframes = safeMapListCast(
          exerciseData['keyframes'],
          'keyframes',
        );

        if (frameIndex < keyframes.length) {
          keyframes[frameIndex]['url'] = url;
          keyframes[frameIndex]['uploadStatus'] = 'uploaded';
          exerciseData['keyframes'] = keyframes;
          extractedKeyFrames[exerciseKey] = exerciseData;

          await docRef.update({'extractedKeyFrames': extractedKeyFrames});
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update keyframe URL', e, stackTrace);
    }
  }

  /// 显示成功提示
  void _showSuccessToast(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(message, style: AppTextStyles.body)),
          ],
        ),
      ),
    );

    // 2秒后自动关闭
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  /// 显示错误对话框
  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller?.dispose();
    }
    _pageController.dispose();

    // 清理预下载的视频文件
    if (_downloadedVideoPath != null) {
      _cleanupDownloadedVideo();
    }

    super.dispose();
  }

  /// 清理预下载的视频文件
  Future<void> _cleanupDownloadedVideo() async {
    try {
      final file = File(_downloadedVideoPath!);
      if (await file.exists()) {
        await file.delete();
        AppLogger.debug('Cleaned up downloaded video');
      }
    } catch (e) {
      AppLogger.warning('Failed to cleanup video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // 主内容区域
            Column(
              children: [
                // 顶部占位（为关闭按钮留空间）
                const SizedBox(height: 60),

                // 视频播放区域
                Expanded(
                  child: widget.videoUrls.length == 1
                      ? _buildSingleVideo()
                      : _buildMultipleVideos(),
                ),

                // 底部控制栏
                if (_initialized[_currentPage] && !_hasError[_currentPage])
                  _VideoControlBar(
                    controller: _controllers[_currentPage]!.controller,
                    onPlayPause: () {
                      final controller = _controllers[_currentPage]!.controller;
                      setState(() {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      });
                    },
                    showExtractButton:
                        widget.dailyTrainingId != null &&
                        widget.exerciseIndex != null,
                    isExtracting: _isExtracting,
                    onExtract: _handleManualExtract,
                  ),

                // 页面指示器（多视频时显示）
                if (widget.videoUrls.length > 1) ...[
                  const SizedBox(height: AppDimensions.spacingS),
                  _buildPageIndicator(),
                  const SizedBox(height: AppDimensions.spacingM),
                ],
              ],
            ),

            // 右上角关闭按钮
            Positioned(
              top: 8,
              right: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleVideo() {
    return _buildVideoPlayer(0);
  }

  Widget _buildMultipleVideos() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.videoUrls.length,
      itemBuilder: (context, index) {
        return _buildVideoPlayer(index);
      },
    );
  }

  Widget _buildVideoPlayer(int index) {
    final l10n = AppLocalizations.of(context)!;

    // 加载中
    if (!_initialized[index] && !_hasError[index]) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(
              radius: 20,
              color: CupertinoColors.white,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.loading,
              style: AppTextStyles.body.copyWith(color: CupertinoColors.white),
            ),
          ],
        ),
      );
    }

    // 错误状态
    if (_hasError[index]) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.videoLoadFailed,
              style: AppTextStyles.body.copyWith(color: CupertinoColors.white),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            CupertinoButton(
              onPressed: () => _retryVideo(index),
              color: AppColors.primaryColor,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final controller = _controllers[index]!.controller;

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              // 播放/暂停图标（仅在暂停时显示）
              if (!controller.value.isPlaying)
                Icon(
                  CupertinoIcons.play_circle_fill,
                  size: 64,
                  color: CupertinoColors.white.withValues(alpha: 0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.videoUrls.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppColors.primaryColor
                : CupertinoColors.systemGrey,
          ),
        ),
      ),
    );
  }
}

/// 底部视频控制栏
class _VideoControlBar extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  final bool showExtractButton;
  final bool isExtracting;
  final VoidCallback? onExtract;

  const _VideoControlBar({
    required this.controller,
    required this.onPlayPause,
    this.showExtractButton = false,
    this.isExtracting = false,
    this.onExtract,
  });

  @override
  Widget build(BuildContext context) {
    final position = controller.value.position;
    final duration = controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      color: CupertinoColors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          Row(
            children: [
              // 当前时间
              Text(
                VideoUtils.formatDuration(position),
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),

              // 进度条
              Expanded(
                child: CupertinoSlider(
                  value: progress.clamp(0.0, 1.0),
                  activeColor: AppColors.primaryColor,
                  thumbColor: CupertinoColors.white,
                  onChanged: (value) {
                    final newPosition = duration * value;
                    controller.seekTo(newPosition);
                  },
                ),
              ),

              const SizedBox(width: AppDimensions.spacingS),

              // 总时长
              Text(
                VideoUtils.formatDuration(duration),
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingS),

          // 播放/暂停按钮 + 提取关键帧按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 播放/暂停按钮
              CupertinoButton(
                onPressed: onPlayPause,
                padding: EdgeInsets.zero,
                child: Icon(
                  controller.value.isPlaying
                      ? CupertinoIcons.pause_circle
                      : CupertinoIcons.play_circle,
                  size: 44,
                  color: CupertinoColors.white,
                ),
              ),

              // 提取关键帧按钮（仅暂停时显示）
              if (showExtractButton && !controller.value.isPlaying) ...[
                const SizedBox(width: 24),
                _ExtractKeyframeButton(
                  isExtracting: isExtracting,
                  onPressed: onExtract,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 提取关键帧按钮
class _ExtractKeyframeButton extends StatelessWidget {
  final bool isExtracting;
  final VoidCallback? onPressed;

  const _ExtractKeyframeButton({required this.isExtracting, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      onPressed: isExtracting ? null : onPressed,
      child: isExtracting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(color: CupertinoColors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.camera,
                  size: 18,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.extractCurrentFrame,
                  style: AppTextStyles.caption1.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
