import 'dart:io';
import 'dart:async';
import 'package:video_compress/video_compress.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/video_utils.dart';

/// 压缩进度数据
class CompressProgress {
  /// 压缩进度 (0.0 - 1.0)
  final double progress;

  /// 压缩完成后的文件（仅在完成时非空）
  final File? file;

  const CompressProgress({
    required this.progress,
    this.file,
  });
}

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

  /// 压缩视频（支持进度监听）
  ///
  /// [videoFile] 视频文件
  /// [quality] 压缩质量（默认 MediumQuality）
  /// 返回压缩进度 Stream，最后一个事件包含压缩后的文件
  /// 如果压缩失败，Stream 会发出错误
  static Stream<CompressProgress> compressVideo(
    File videoFile, {
    VideoQuality quality = VideoQuality.MediumQuality,
  }) {
    final controller = StreamController<CompressProgress>();
    dynamic progressSubscription;  // video_compress subscription type

    // 启动压缩任务
    () async {
      try {
        AppLogger.info('开始压缩视频: ${videoFile.path}');

        // 订阅压缩进度（0.0 - 100.0）
        progressSubscription = VideoCompress.compressProgress$.subscribe((progress) {
          if (!controller.isClosed) {
            // 将 0-100 转换为 0.0-1.0
            final normalizedProgress = (progress / 100.0).clamp(0.0, 1.0);
            controller.add(CompressProgress(progress: normalizedProgress));
          }
        });

        // 执行压缩
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

        // 发送最终结果
        if (!controller.isClosed) {
          controller.add(CompressProgress(progress: 1.0, file: compressedFile));
        }
      } catch (e, stackTrace) {
        AppLogger.error('视频压缩失败', e, stackTrace);
        if (!controller.isClosed) {
          controller.addError(e, stackTrace);
        }
      } finally {
        // 清理订阅
        progressSubscription?.unsubscribe();
        if (!controller.isClosed) {
          controller.close();
        }
      }
    }();

    return controller.stream;
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
