import 'package:coach_x/core/utils/logger.dart';
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

/// 视频处理工具类
///
/// 提供视频缩略图生成、时长获取、格式化等功能
class VideoUtils {
  VideoUtils._(); // 私有构造函数，防止实例化

  /// 生成视频缩略图
  ///
  /// [videoPath] 视频文件路径（本地路径或网络 URL）
  /// 返回缩略图文件，如果失败返回 null
  static Future<File?> generateThumbnail(String videoPath) async {
    try {
      AppLogger.debug('🖼️ [VideoUtils] 开始生成缩略图: $videoPath');
      final tempDir = await getTemporaryDirectory();
      AppLogger.debug('🖼️ [VideoUtils] 临时目录: ${tempDir.path}');

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );

      if (thumbnailPath != null) {
        AppLogger.debug('✅ [VideoUtils] 缩略图生成成功: $thumbnailPath');
        return File(thumbnailPath);
      } else {
        AppLogger.debug('⚠️ [VideoUtils] 缩略图生成返回null');
      }
    } catch (e, stackTrace) {
      AppLogger.debug('❌ [VideoUtils] 生成视频缩略图失败: $e');
      AppLogger.debug('Stack trace: $stackTrace');
    }
    return null;
  }

  /// 获取视频时长
  ///
  /// [videoPath] 视频文件路径（本地路径或网络 URL）
  /// 返回视频时长，如果失败返回 Duration.zero
  static Future<Duration> getVideoDuration(String videoPath) async {
    VideoPlayerController? controller;
    try {
      AppLogger.debug('⏱️ [VideoUtils] 开始获取视频时长: $videoPath');
      // 根据路径类型创建不同的 controller
      if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
        AppLogger.debug('⏱️ [VideoUtils] 使用网络视频控制器');
        controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        AppLogger.debug('⏱️ [VideoUtils] 使用本地文件控制器');
        controller = VideoPlayerController.file(File(videoPath));
      }

      AppLogger.debug('⏱️ [VideoUtils] 初始化视频控制器...');
      await controller.initialize();
      final duration = controller.value.duration;
      AppLogger.debug('✅ [VideoUtils] 视频时长: ${duration.inSeconds}秒');
      return duration;
    } catch (e, stackTrace) {
      AppLogger.debug('❌ [VideoUtils] 获取视频时长失败: $e');
      AppLogger.debug('Stack trace: $stackTrace');
      return Duration.zero;
    } finally {
      controller?.dispose();
    }
  }

  /// 格式化时长为 "分:秒" 格式
  ///
  /// 例如: Duration(seconds: 45) -> "0:45"
  ///      Duration(seconds: 125) -> "2:05"
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 检查视频时长是否在允许范围内
  ///
  /// [duration] 视频时长
  /// [maxSeconds] 最大允许秒数
  static bool isVideoDurationValid(Duration duration, int maxSeconds) {
    return duration.inSeconds > 0 && duration.inSeconds <= maxSeconds;
  }

  /// 验证视频文件的时长
  ///
  /// [videoFile] 视频文件
  /// [maxSeconds] 最大允许秒数（默认60秒）
  /// 返回是否有效
  static Future<bool> validateVideoFile(
    File videoFile, {
    int maxSeconds = 60,
  }) async {
    AppLogger.debug('🔍 [VideoUtils] 验证视频文件: ${videoFile.path}');
    AppLogger.debug('🔍 [VideoUtils] 最大允许时长: $maxSeconds秒');

    final duration = await getVideoDuration(videoFile.path);
    final isValid = isVideoDurationValid(duration, maxSeconds);

    AppLogger.debug(
      '🔍 [VideoUtils] 验证结果: ${isValid ? "✅ 通过" : "❌ 超时"} (实际时长: ${duration.inSeconds}秒)',
    );
    return isValid;
  }

  /// 获取视频文件大小（MB）
  static Future<double> getVideoSizeMB(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // 转换为 MB
      }
    } catch (e) {
      AppLogger.debug('获取视频大小失败: $e');
    }
    return 0.0;
  }
}
