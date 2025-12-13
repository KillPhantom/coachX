import 'dart:io';
import 'dart:async';
import 'package:coach_x/core/models/media_upload_state.dart';
import 'package:coach_x/core/services/media_upload_service.dart';
import 'package:coach_x/core/services/video_service.dart';
import 'package:coach_x/core/utils/image_compressor.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:video_compress/video_compress.dart';

/// 上传进度事件
class UploadProgress {
  /// 任务ID (格式: "exerciseIndex_mediaIndex")
  final String taskId;

  /// 上传进度 (0.0 - 1.0)
  final double progress;

  /// 上传状态
  final MediaUploadStatus status;

  /// 错误信息
  final String? error;

  /// 下载 URL（完成时）
  final String? downloadUrl;

  /// 缩略图 URL（完成时，仅视频）
  final String? thumbnailUrl;

  /// 本地缩略图路径（生成后）
  final String? thumbnailPath;

  const UploadProgress({
    required this.taskId,
    this.progress = 0.0,
    required this.status,
    this.error,
    this.downloadUrl,
    this.thumbnailUrl,
    this.thumbnailPath,
  });

  @override
  String toString() => 'UploadProgress(taskId: $taskId, progress: $progress, status: $status)';
}

/// 上传任务内部模型
class _UploadTask {
  final String taskId;
  final File file;
  final MediaType type;
  final String storagePath;

  String? thumbnailPath;
  File? compressedFile;
  StreamSubscription? compressionSubscription;
  StreamSubscription? uploadSubscription;

  _UploadTask({
    required this.taskId,
    required this.file,
    required this.type,
    required this.storagePath,
  });
}

/// 媒体上传管理器
///
/// 管理所有媒体上传任务，与 UI 生命周期解耦
class MediaUploadManager {
  final MediaUploadService _uploadService;

  /// 任务ID -> 任务对象
  final Map<String, _UploadTask> _tasks = {};

  /// 进度事件流
  final _progressController = StreamController<UploadProgress>.broadcast();
  Stream<UploadProgress> get progressStream => _progressController.stream;

  MediaUploadManager(this._uploadService);

  /// 启动上传任务
  ///
  /// [file] 要上传的文件
  /// [type] 媒体类型
  /// [storagePath] 存储路径
  /// [taskId] 任务ID（格式: "exerciseIndex_mediaIndex"）
  /// [maxVideoSeconds] 视频最大时长（仅视频）
  /// [compressionThresholdMB] 压缩阈值（仅视频）
  Future<void> startUpload({
    required File file,
    required MediaType type,
    required String storagePath,
    required String taskId,
    int? maxVideoSeconds,
    int? compressionThresholdMB,
  }) async {
    AppLogger.info('[MediaUploadManager] 启动上传任务: $taskId');

    // 检查是否已存在
    if (_tasks.containsKey(taskId)) {
      AppLogger.warning('[MediaUploadManager] 任务已存在，跳过: $taskId');
      return;
    }

    // 创建任务
    final task = _UploadTask(
      taskId: taskId,
      file: file,
      type: type,
      storagePath: storagePath,
    );
    _tasks[taskId] = task;

    // 发送开始事件
    _emitProgress(taskId, 0.0, MediaUploadStatus.pending);

    // 异步执行上传流程
    _executeUpload(task, maxVideoSeconds ?? 60, compressionThresholdMB ?? 50);
  }

  /// 执行上传流程
  Future<void> _executeUpload(
    _UploadTask task,
    int maxVideoSeconds,
    int compressionThresholdMB,
  ) async {
    AppLogger.info('[MediaUploadManager] _executeUpload 开始: ${task.taskId}, type=${task.type}');
    try {
      if (task.type == MediaType.video) {
        // 视频处理流程
        // 1. 生成缩略图
        AppLogger.info('[MediaUploadManager] 生成缩略图: ${task.taskId}');
        await Future.delayed(const Duration(milliseconds: 300));
        final thumbnail = await VideoUtils.generateThumbnail(task.file.path);
        task.thumbnailPath = thumbnail?.path;

        if (thumbnail != null) {
          _emitProgress(
            task.taskId,
            0.0,
            MediaUploadStatus.pending,
            thumbnailPath: thumbnail.path,
          );
        }

        // 2. 验证视频时长
        AppLogger.info('[MediaUploadManager] 验证视频时长: ${task.taskId}');
        final isValid = await VideoUtils.validateVideoFile(
          task.file,
          maxSeconds: maxVideoSeconds,
        );
        if (!isValid) {
          throw Exception('视频时长超过 $maxVideoSeconds 秒');
        }

        // 3. 条件压缩
        final shouldCompress = await VideoService.shouldCompress(
          task.file,
          thresholdMB: compressionThresholdMB,
        );
        if (shouldCompress) {
          await _compressVideo(task);
        }
      } else if (task.type == MediaType.image) {
        // 图片处理流程 - 压缩图片
        AppLogger.info('[MediaUploadManager] 压缩图片: ${task.taskId}');
        _emitProgress(task.taskId, 0.1, MediaUploadStatus.compressing);

        final compressedPath = await ImageCompressor.compressImageForUser(task.file.path);
        if (compressedPath != task.file.path) {
          // 压缩成功，使用压缩后的文件
          task.compressedFile = File(compressedPath);
          AppLogger.info('[MediaUploadManager] 图片压缩完成: ${task.taskId}');
        }

        _emitProgress(task.taskId, 0.3, MediaUploadStatus.uploading);
      }

      // 4. 上传文件
      AppLogger.info('[MediaUploadManager] 准备调用 _uploadFile: ${task.taskId}');
      await _uploadFile(task);
      AppLogger.info('[MediaUploadManager] _uploadFile 完成: ${task.taskId}');
    } catch (e, stackTrace) {
      AppLogger.error('[MediaUploadManager] 上传失败: ${task.taskId}', e, stackTrace);
      _emitError(task.taskId, e.toString());
      _tasks.remove(task.taskId);
    }
  }

  /// 压缩视频
  Future<void> _compressVideo(_UploadTask task) async {
    AppLogger.info('[MediaUploadManager] 开始压缩视频: ${task.taskId}');

    final compressionStream = VideoService.compressVideo(
      task.file,
      quality: VideoQuality.MediumQuality,
    );

    final completer = Completer<void>();

    final subscription = compressionStream.listen(
      (compressProgress) {
        // 压缩进度映射到 0-60%
        final displayProgress = compressProgress.progress * 0.6;
        _emitProgress(task.taskId, displayProgress, MediaUploadStatus.compressing);

        // 压缩完成
        if (compressProgress.file != null) {
          task.compressedFile = compressProgress.file;
          AppLogger.info('[MediaUploadManager] 压缩完成: ${task.taskId}');
          completer.complete();
        }
      },
      onError: (error, stackTrace) {
        AppLogger.error('[MediaUploadManager] 压缩失败: ${task.taskId}', error, stackTrace);
        completer.completeError(error, stackTrace);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    task.compressionSubscription = subscription;

    try {
      await completer.future;
    } finally {
      subscription.cancel();
      task.compressionSubscription = null;
    }
  }

  /// 上传文件
  Future<void> _uploadFile(_UploadTask task) async {
    final fileToUpload = task.compressedFile ?? task.file;
    final contentType = task.type == MediaType.video ? 'video/mp4' : 'image/jpeg';

    AppLogger.info('[MediaUploadManager] 开始上传文件: ${task.taskId}');

    final uploadStream = _uploadService.uploadFileWithProgress(
      fileToUpload,
      task.storagePath,
      contentType: contentType,
    );

    final completer = Completer<void>();

    final subscription = uploadStream.listen(
      (progress) {
        // 上传进度映射到 60-100% 或 0-100%
        final baseProgress = task.compressedFile != null ? 0.6 : 0.0;
        final range = task.compressedFile != null ? 0.4 : 1.0;
        final displayProgress = baseProgress + (progress * range);
        _emitProgress(task.taskId, displayProgress, MediaUploadStatus.uploading);
      },
      onDone: () async {
        AppLogger.info('[MediaUploadManager] onDone 回调触发: ${task.taskId}');
        try {
          // 获取下载 URL
          final downloadUrl = await _uploadService.getDownloadUrl(task.storagePath);
          AppLogger.info('[MediaUploadManager] 获取下载URL成功: ${task.taskId}, url=$downloadUrl');

          // 上传缩略图（仅视频）
          String? thumbnailUrl;
          if (task.type == MediaType.video && task.thumbnailPath != null) {
            final thumbPath = task.storagePath.replaceAll('.mp4', '_thumb.jpg');
            try {
              thumbnailUrl = await _uploadService.uploadThumbnail(
                File(task.thumbnailPath!),
                thumbPath,
              );
              AppLogger.info('[MediaUploadManager] 缩略图上传成功: ${task.taskId}');
            } catch (e) {
              AppLogger.error('[MediaUploadManager] 缩略图上传失败: ${task.taskId}', e);
              // 不阻塞主流程
            }
          }

          // 发送完成事件
          AppLogger.info('[MediaUploadManager] 发送完成事件: ${task.taskId}');
          _emitCompleted(task.taskId, downloadUrl, thumbnailUrl);
          _tasks.remove(task.taskId);
          completer.complete();
        } catch (e, stackTrace) {
          AppLogger.error('[MediaUploadManager] 获取URL失败: ${task.taskId}', e, stackTrace);
          completer.completeError(e, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        AppLogger.error('[MediaUploadManager] 上传失败: ${task.taskId}', error, stackTrace);
        completer.completeError(error, stackTrace);
      },
    );

    task.uploadSubscription = subscription;

    try {
      await completer.future;
    } catch (e) {
      _emitError(task.taskId, 'Upload failed: $e');
      _tasks.remove(task.taskId);
      rethrow;
    } finally {
      subscription.cancel();
      task.uploadSubscription = null;
    }
  }

  /// 发送进度事件
  void _emitProgress(
    String taskId,
    double progress,
    MediaUploadStatus status, {
    String? thumbnailPath,
  }) {
    if (!_progressController.isClosed) {
      _progressController.add(UploadProgress(
        taskId: taskId,
        progress: progress,
        status: status,
        thumbnailPath: thumbnailPath,
      ));
    }
  }

  /// 发送完成事件
  void _emitCompleted(String taskId, String downloadUrl, String? thumbnailUrl) {
    if (!_progressController.isClosed) {
      _progressController.add(UploadProgress(
        taskId: taskId,
        progress: 1.0,
        status: MediaUploadStatus.completed,
        downloadUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
      ));
    }
  }

  /// 发送错误事件
  void _emitError(String taskId, String error) {
    if (!_progressController.isClosed) {
      _progressController.add(UploadProgress(
        taskId: taskId,
        status: MediaUploadStatus.error,
        error: error,
      ));
    }
  }

  /// 取消任务
  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task != null) {
      AppLogger.info('[MediaUploadManager] 取消任务: $taskId');
      task.compressionSubscription?.cancel();
      task.uploadSubscription?.cancel();
      _tasks.remove(taskId);
    }
  }

  /// 获取任务状态
  bool hasTask(String taskId) {
    return _tasks.containsKey(taskId);
  }

  /// 清理所有任务
  void dispose() {
    AppLogger.info('[MediaUploadManager] 清理所有任务');
    for (var task in _tasks.values) {
      task.compressionSubscription?.cancel();
      task.uploadSubscription?.cancel();
    }
    _tasks.clear();
    _progressController.close();
  }
}
