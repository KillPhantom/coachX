import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:coach_x/core/utils/logger.dart';

/// 视频帧提取服务
/// 使用video_thumbnail从视频中提取帧图片
class VideoFrameExtractor {
  /// 提取视频帧
  ///
  /// [videoPath] - 本地视频文件路径
  /// [trainingId] - 训练记录ID (用于生成输出目录)
  /// [fps] - 提取帧率 (每秒帧数，默认10)
  /// [maxDuration] - 最大视频时长(秒)，默认120秒
  ///
  /// 返回包含所有帧图片路径的列表
  Future<List<String>> extractFrames(
    String videoPath,
    String trainingId, {
    int fps = 10,
    int maxDuration = 120,
  }) async {
    String? outputDir;
    try {
      AppLogger.info('Starting frame extraction for training: $trainingId');
      AppLogger.debug('Video path: $videoPath');
      AppLogger.debug('Target FPS: $fps');

      // 创建输出目录
      outputDir = await _createOutputDirectory(trainingId);
      AppLogger.debug('Output directory: $outputDir');

      // 计算时间戳列表 (毫秒)
      // 每1/fps秒提取一帧，最多提取maxDuration秒
      final interval = (1000 / fps).round(); // 毫秒间隔
      final maxFrames = maxDuration * fps;
      final timePositions = List.generate(
        maxFrames,
        (index) => index * interval,
      );

      AppLogger.info('Will attempt to extract ${timePositions.length} frames');

      // 逐个提取帧
      final framePaths = <String>[];
      for (int i = 0; i < timePositions.length; i++) {
        final timeMs = timePositions[i];
        final framePath = path.join(
          outputDir,
          'frame-${(i + 1).toString().padLeft(4, '0')}.jpg',
        );

        try {
          // 使用video_thumbnail提取单帧
          final thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: framePath,
            imageFormat: ImageFormat.JPEG,
            timeMs: timeMs,
            quality: 90,
          );

          if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
            framePaths.add(thumbnailPath);

            // 每10帧记录一次进度
            if ((i + 1) % 10 == 0) {
              AppLogger.debug(
                'Extracted ${i + 1}/${timePositions.length} frames',
              );
            }
          }
        } catch (e) {
          // 如果提取失败（可能已超过视频时长），停止提取
          AppLogger.debug('Failed to extract frame at ${timeMs}ms: $e');
          AppLogger.info('Stopped extraction (likely reached end of video)');
          break;
        }
      }

      AppLogger.info('Successfully extracted ${framePaths.length} frames');
      return framePaths;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract frames', e, stackTrace);

      // 清理失败的输出
      if (outputDir != null) {
        await cleanup(outputDir);
      }

      rethrow;
    }
  }

  /// 创建输出目录
  Future<String> _createOutputDirectory(String trainingId) async {
    final tempDir = await getTemporaryDirectory();
    final framesDir = Directory(path.join(tempDir.path, 'frames', trainingId));

    // 如果目录已存在，先删除
    if (await framesDir.exists()) {
      await framesDir.delete(recursive: true);
      AppLogger.debug('Removed existing frames directory');
    }

    // 创建新目录
    await framesDir.create(recursive: true);
    AppLogger.debug('Created frames directory: ${framesDir.path}');

    return framesDir.path;
  }

  /// 清理临时帧文件
  ///
  /// [outputDir] - 帧文件目录路径
  Future<void> cleanup(String outputDir) async {
    try {
      final dir = Directory(outputDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        AppLogger.debug('Cleaned up frames directory: $outputDir');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup frames', e, stackTrace);
      // 不重新抛出异常，因为清理失败不应该影响主流程
    }
  }

  /// 清理所有临时帧目录
  Future<void> cleanupAll() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory(path.join(tempDir.path, 'frames'));

      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
        AppLogger.info('Cleaned up all frames directories');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup all frames', e, stackTrace);
    }
  }
}
