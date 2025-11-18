import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/video_utils.dart';

/// 视频处理服务
///
/// 提供视频压缩功能，封装 video_compress package
class VideoService {
  VideoService._(); // 私有构造函数，防止实例化

  /// 判断视频是否需要压缩
  ///
  /// [videoFile] 视频文件
  /// [thresholdMB] 压缩阈值（MB），默认50MB
  /// 返回是否需要压缩
  static Future<bool> shouldCompress(
    File videoFile, {
    int thresholdMB = 50,
  }) async {
    try {
      final sizeMB = await VideoUtils.getVideoSizeMB(videoFile.path);
      AppLogger.info('视频大小: ${sizeMB.toStringAsFixed(2)} MB');
      return sizeMB >= thresholdMB;
    } catch (e) {
      AppLogger.error('获取视频大小失败', e);
      return false; // 失败时不压缩
    }
  }

  /// 压缩视频
  ///
  /// [videoFile] 视频文件
  /// [quality] 压缩质量（默认 MediumQuality）
  /// 返回压缩后的文件
  /// 如果压缩失败，抛出异常
  static Future<File> compressVideo(
    File videoFile, {
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    try {
      AppLogger.info('开始压缩视频: ${videoFile.path}');

      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false, // 不删除原文件
        includeAudio: true, // 保留音频
      );

      if (info == null || info.file == null) {
        throw Exception('视频压缩返回空结果');
      }

      final compressedFile = info.file!;
      final originalSizeMB = await VideoUtils.getVideoSizeMB(videoFile.path);
      final compressedSizeMB = await VideoUtils.getVideoSizeMB(
        compressedFile.path,
      );

      AppLogger.info(
        '压缩完成: ${originalSizeMB.toStringAsFixed(2)} MB → ${compressedSizeMB.toStringAsFixed(2)} MB '
        '(压缩率: ${((1 - compressedSizeMB / originalSizeMB) * 100).toStringAsFixed(1)}%)',
      );

      return compressedFile;
    } catch (e, stackTrace) {
      AppLogger.error('视频压缩失败', e, stackTrace);
      rethrow;
    }
  }

  /// 取消所有压缩任务（可选）
  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }

  /// 删除缓存（可选，用于清理临时文件）
  static Future<void> deleteAllCache() async {
    await VideoCompress.deleteAllCache();
  }
}
