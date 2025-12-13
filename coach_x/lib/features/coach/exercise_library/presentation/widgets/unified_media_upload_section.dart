import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/models/media_upload_state.dart';
import 'package:coach_x/core/widgets/media_upload_section.dart';
import 'package:coach_x/core/providers/media_upload_providers.dart';
import 'package:coach_x/core/services/media_upload_manager.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Unified Media Upload Section (Wrapper around MediaUploadSection)
///
/// Adapts the new MediaUploadSection to the legacy separate URL list API.
/// Integrates with MediaUploadManager for background upload handling.
class UnifiedMediaUploadSection extends ConsumerStatefulWidget {
  final List<String> initialVideoUrls;
  final List<String> initialThumbnailUrls;
  final List<String> initialImageUrls;
  final ValueChanged<List<String>> onVideoUrlsChanged;
  final ValueChanged<List<String>> onThumbnailUrlsChanged;
  final ValueChanged<List<String>> onImageUrlsChanged;

  const UnifiedMediaUploadSection({
    super.key,
    required this.initialVideoUrls,
    required this.initialThumbnailUrls,
    required this.initialImageUrls,
    required this.onVideoUrlsChanged,
    required this.onThumbnailUrlsChanged,
    required this.onImageUrlsChanged,
  });

  @override
  ConsumerState<UnifiedMediaUploadSection> createState() => _UnifiedMediaUploadSectionState();
}

class _UnifiedMediaUploadSectionState extends ConsumerState<UnifiedMediaUploadSection> {
  final List<MediaUploadState> _initialMedia = [];
  List<MediaUploadState> _localMediaList = [];
  StreamSubscription<UploadProgress>? _uploadProgressSubscription;

  /// 用于生成唯一的 taskId
  int _taskCounter = 0;

  /// taskId -> mediaIndex 映射
  final Map<String, int> _taskIdToIndex = {};

  /// 缓存 MediaUploadManager 引用（避免在回调中使用 ref）
  MediaUploadManager? _uploadManager;

  MediaUploadManager get uploadManager {
    _uploadManager ??= ref.read(mediaUploadManagerProvider);
    return _uploadManager!;
  }

  @override
  void initState() {
    super.initState();
    _initializeMedia();
    // 延迟初始化，确保 ref 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uploadManager = ref.read(mediaUploadManagerProvider);
      _listenToUploadProgress();
    });
  }

  @override
  void dispose() {
    _uploadProgressSubscription?.cancel();
    super.dispose();
  }

  /// 订阅 MediaUploadManager 的上传进度事件
  void _listenToUploadProgress() {
    _uploadProgressSubscription = uploadManager.progressStream.listen(
      _handleUploadProgress,
    );
  }

  /// 处理上传进度事件
  void _handleUploadProgress(UploadProgress progress) {
    // 检查是否是我们的任务
    final mediaIndex = _taskIdToIndex[progress.taskId];
    if (mediaIndex == null) {
      return; // 不是我们的任务
    }

    if (mediaIndex < 0 || mediaIndex >= _localMediaList.length) {
      AppLogger.error(
        '[UnifiedMediaUploadSection] mediaIndex 越界: $mediaIndex (总数: ${_localMediaList.length})',
      );
      return;
    }

    AppLogger.info(
      '[UnifiedMediaUploadSection] 上传进度: ${progress.taskId} - ${(progress.progress * 100).toInt()}% (${progress.status})',
    );

    setState(() {
      // 创建新的 List 以触发 MediaUploadSection 的 didUpdateWidget
      final updatedList = List<MediaUploadState>.from(_localMediaList);
      updatedList[mediaIndex] = updatedList[mediaIndex].copyWith(
        status: progress.status,
        progress: progress.progress,
        error: progress.error,
        downloadUrl: progress.downloadUrl,
        thumbnailUrl: progress.thumbnailUrl,
        thumbnailPath: progress.thumbnailPath,
      );
      _localMediaList = updatedList;
    });

    // 如果完成或失败，更新父组件
    if (progress.status == MediaUploadStatus.completed) {
      AppLogger.info(
        '[UnifiedMediaUploadSection] 上传完成! downloadUrl=${progress.downloadUrl}',
      );
      _updateParent(_localMediaList);
      _taskIdToIndex.remove(progress.taskId);
    } else if (progress.status == MediaUploadStatus.error) {
      AppLogger.error(
        '[UnifiedMediaUploadSection] 上传失败: ${progress.error}',
      );
      _updateParent(_localMediaList);
    }
  }

  void _initializeMedia() {
    // Add existing videos
    for (int i = 0; i < widget.initialVideoUrls.length; i++) {
      _initialMedia.add(MediaUploadState.completed(
        downloadUrl: widget.initialVideoUrls[i],
        thumbnailUrl: i < widget.initialThumbnailUrls.length ? widget.initialThumbnailUrls[i] : null,
        type: MediaType.video,
      ));
    }

    // Add existing images
    for (int i = 0; i < widget.initialImageUrls.length; i++) {
      _initialMedia.add(MediaUploadState.completed(
        downloadUrl: widget.initialImageUrls[i],
        type: MediaType.image,
      ));
    }

    // 初始化 _localMediaList
    _localMediaList = List.from(_initialMedia);
  }

  void _updateParent(List<MediaUploadState> currentMedia) {
    final videoUrls = currentMedia
        .where((m) => m.type == MediaType.video && m.status == MediaUploadStatus.completed && m.downloadUrl != null)
        .map((m) => m.downloadUrl!)
        .toList();

    final thumbnailUrls = currentMedia
        .where((m) => m.type == MediaType.video && m.status == MediaUploadStatus.completed)
        .map((m) => m.thumbnailUrl ?? '')
        .toList();

    final imageUrls = currentMedia
        .where((m) => m.type == MediaType.image && m.status == MediaUploadStatus.completed && m.downloadUrl != null)
        .map((m) => m.downloadUrl!)
        .toList();

    widget.onVideoUrlsChanged(videoUrls);
    widget.onThumbnailUrlsChanged(thumbnailUrls);
    widget.onImageUrlsChanged(imageUrls);
  }

  /// 启动媒体上传
  void _startMediaUpload(File file, MediaType type, int mediaIndex) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = type == MediaType.video ? 'mp4' : 'jpg';
    final storagePath = 'exercise_library/$userId/$timestamp.$ext';

    // 生成唯一的 taskId
    final taskId = 'exercise_library_${_taskCounter++}';
    _taskIdToIndex[taskId] = mediaIndex;

    AppLogger.info(
      '[UnifiedMediaUploadSection] 启动上传: taskId=$taskId, mediaIndex=$mediaIndex, path=${file.path}',
    );

    uploadManager.startUpload(
      file: file,
      type: type,
      storagePath: storagePath,
      taskId: taskId,
      maxVideoSeconds: 600, // 动作库允许更长的视频
      compressionThresholdMB: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaUploadSection(
      storagePathPrefix: 'exercise_library/${FirebaseAuth.instance.currentUser?.uid ?? "unknown"}/',
      maxCount: 10,
      maxVideoSeconds: 600,
      initialMedia: _localMediaList,
      onMediaSelected: (index, file, type) {
        AppLogger.info(
          '[UnifiedMediaUploadSection] onMediaSelected: index=$index, file=${file.path}, type=$type',
        );

        // 1. 添加 pending 状态到 _localMediaList
        setState(() {
          // 创建新的 List 以触发 MediaUploadSection 的 didUpdateWidget
          final updatedList = List<MediaUploadState>.from(_localMediaList);
          if (index >= updatedList.length) {
            updatedList.add(MediaUploadState.pending(localPath: file.path, type: type));
          } else {
            updatedList[index] = MediaUploadState.pending(localPath: file.path, type: type);
          }
          _localMediaList = updatedList;
        });

        // 2. 获取实际的 mediaIndex（添加后的索引）
        final mediaIndex = index >= _localMediaList.length - 1 ? _localMediaList.length - 1 : index;

        // 3. 启动后台上传
        _startMediaUpload(file, type, mediaIndex);
      },
      onUploadCompleted: (index, url, thumb, type) {
        // MediaUploadSection 内部上传完成（如果它自己处理了上传）
        // 但我们使用 MediaUploadManager，所以这个回调可能不会被调用
        // 保留以防万一
        AppLogger.info(
          '[UnifiedMediaUploadSection] onUploadCompleted (from MediaUploadSection): index=$index',
        );
        setState(() {
          if (index < _localMediaList.length) {
            final updatedList = List<MediaUploadState>.from(_localMediaList);
            updatedList[index] = updatedList[index].copyWith(
              status: MediaUploadStatus.completed,
              downloadUrl: url,
              thumbnailUrl: thumb,
              type: type,
            );
            _localMediaList = updatedList;
          }
        });
        _updateParent(_localMediaList);
      },
      onMediaDeleted: (index) {
        AppLogger.info('[UnifiedMediaUploadSection] onMediaDeleted: index=$index');

        // 取消该索引对应的上传任务
        final taskIdToRemove = _taskIdToIndex.entries
            .where((e) => e.value == index)
            .map((e) => e.key)
            .firstOrNull;
        if (taskIdToRemove != null) {
          uploadManager.cancelTask(taskIdToRemove);
          _taskIdToIndex.remove(taskIdToRemove);
        }

        // 更新索引映射（删除后面的项索引需要减1）
        final updatedMapping = <String, int>{};
        for (final entry in _taskIdToIndex.entries) {
          if (entry.value > index) {
            updatedMapping[entry.key] = entry.value - 1;
          } else {
            updatedMapping[entry.key] = entry.value;
          }
        }
        _taskIdToIndex.clear();
        _taskIdToIndex.addAll(updatedMapping);

        setState(() {
          if (index < _localMediaList.length) {
            final updatedList = List<MediaUploadState>.from(_localMediaList);
            updatedList.removeAt(index);
            _localMediaList = updatedList;
          }
        });
        _updateParent(_localMediaList);
      },
    );
  }
}
