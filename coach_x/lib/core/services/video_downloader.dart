import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/video_cache_service.dart';
import 'package:coach_x/core/models/video_cache_metadata.dart';

/// 视频下载服务
/// 用于从Firebase Storage下载视频到本地临时目录
class VideoDownloader {
  final Dio _dio;
  final VideoCacheService? _cacheService;

  VideoDownloader({Dio? dio, VideoCacheService? cacheService})
    : _dio = dio ?? Dio(),
      _cacheService = cacheService;

  /// 下载视频到本地
  ///
  /// [videoUrl] - Firebase Storage视频URL
  /// [trainingId] - 训练记录ID (用于生成唯一文件名)
  ///
  /// 返回本地视频文件路径
  Future<String> downloadVideo(String videoUrl, String trainingId) async {
    try {
      AppLogger.info('Starting video download for training: $trainingId');

      // 1. 检查缓存
      if (_cacheService != null) {
        final cachedPath = await _cacheService.getCachedVideoPath(
          videoUrl,
          trainingId,
        );
        if (cachedPath != null) {
          // 缓存命中，验证文件存在
          final file = File(cachedPath);
          if (await file.exists()) {
            AppLogger.info('✅ 缓存命中: $trainingId');
            return cachedPath;
          } else {
            AppLogger.warning('缓存文件不存在，重新下载: $cachedPath');
          }
        } else {
          AppLogger.debug('❌ 缓存未命中，开始下载: $trainingId');
        }
      }

      // 2. 获取本地路径
      final localPath = await getLocalPath(trainingId);

      // 3. 如果文件已存在（但缓存未命中，说明过期），删除旧文件
      final file = File(localPath);
      if (await file.exists()) {
        AppLogger.debug('删除过期缓存文件: $localPath');
        await file.delete();
      }

      // 4. 下载视频
      AppLogger.debug('Downloading from: $videoUrl');
      AppLogger.debug('Saving to: $localPath');

      await _dio.download(videoUrl, localPath);

      // 5. 获取文件大小
      final fileSize = await file.length();

      // 6. 保存缓存元数据
      if (_cacheService != null) {
        final metadata = VideoCacheMetadata.create(
          videoUrl: videoUrl,
          localPath: localPath,
          trainingId: trainingId,
          fileSize: fileSize,
        );
        await _cacheService.saveCacheMetadata(metadata);
        AppLogger.debug('缓存元数据已保存: $trainingId');
      }

      AppLogger.info('Video download completed: $localPath');
      return localPath;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to download video', e, stackTrace);
      rethrow;
    }
  }

  /// 生成本地临时路径
  ///
  /// [trainingId] - 训练记录ID
  ///
  /// 返回完整的本地文件路径
  Future<String> getLocalPath(String trainingId) async {
    try {
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();

      // 创建training_videos子目录
      final videoDir = Directory(path.join(tempDir.path, 'training_videos'));
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
        AppLogger.debug('Created video directory: ${videoDir.path}');
      }

      // 生成视频文件路径
      final videoPath = path.join(videoDir.path, '$trainingId.mp4');

      return videoPath;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get local path', e, stackTrace);
      rethrow;
    }
  }

  /// 删除下载的视频文件
  ///
  /// [videoPath] - 视频文件路径
  Future<void> deleteVideo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.debug('Deleted video file: $videoPath');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete video', e, stackTrace);
      // 不重新抛出异常，因为清理失败不应该影响主流程
    }
  }

  /// 清理所有临时视频文件
  Future<void> cleanupAll() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoDir = Directory(path.join(tempDir.path, 'training_videos'));

      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
        AppLogger.info('Cleaned up all temporary videos');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup all videos', e, stackTrace);
    }
  }
}
