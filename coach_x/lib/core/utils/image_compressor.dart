import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/constants/media_compression_config.dart';

/// 图片压缩工具类
class ImageCompressor {
  /// 压缩图片
  ///
  /// [imagePath] 原始图片路径
  /// [quality] 压缩质量 0-100，默认 85
  /// [maxWidth] 最大宽度，默认 1920
  /// [maxHeight] 最大高度，默认 1920
  ///
  /// Returns: 压缩后的图片路径
  static Future<String> compressImage(
    String imagePath, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      final startTime = DateTime.now();
      final originalFile = File(imagePath);
      final originalSize = await originalFile.length();

      AppLogger.info('开始压缩图片: $imagePath');
      AppLogger.info(
        '原始大小: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // 生成压缩后的文件路径
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_$timestamp.jpg';

      // 压缩图片
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        throw Exception('图片压缩失败');
      }

      final compressedSize = await compressedFile.length();
      final duration = DateTime.now().difference(startTime);
      final compressionRatio = (1 - compressedSize / originalSize) * 100;

      AppLogger.info('✅ 图片压缩完成');
      AppLogger.info(
        '压缩后大小: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      AppLogger.info('压缩率: ${compressionRatio.toStringAsFixed(1)}%');
      AppLogger.info('耗时: ${duration.inMilliseconds}ms');

      return compressedFile.path;
    } catch (e, stackTrace) {
      AppLogger.error('图片压缩失败', e, stackTrace);
      // 压缩失败时返回原始路径
      AppLogger.warning('⚠️ 使用原始图片');
      return imagePath;
    }
  }

  /// 批量压缩图片
  static Future<List<String>> compressImages(
    List<String> imagePaths, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    final compressedPaths = <String>[];

    for (final imagePath in imagePaths) {
      final compressedPath = await compressImage(
        imagePath,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      compressedPaths.add(compressedPath);
    }

    return compressedPaths;
  }

  // ==================== 便捷方法（使用统一配置） ====================

  /// 压缩图片（AI 识别用）
  ///
  /// 使用优化的参数：quality=70, size=1024
  /// 适用于：食物识别、训练动作识别等 AI 分析场景
  static Future<String> compressImageForAI(String imagePath) async {
    return compressImage(
      imagePath,
      quality: MediaCompressionConfig.aiFoodImageQuality,
      maxWidth: MediaCompressionConfig.aiFoodImageMaxSize,
      maxHeight: MediaCompressionConfig.aiFoodImageMaxSize,
    );
  }

  /// 压缩图片（用户查看用）
  ///
  /// 使用较高质量参数：quality=80, size=1280
  /// 适用于：身体测量照片、训练记录照片等用户需要查看的场景
  static Future<String> compressImageForUser(String imagePath) async {
    return compressImage(
      imagePath,
      quality: MediaCompressionConfig.userImageQuality,
      maxWidth: MediaCompressionConfig.userImageMaxSize,
      maxHeight: MediaCompressionConfig.userImageMaxSize,
    );
  }

  /// 压缩缩略图
  ///
  /// 使用最小化参数：quality=75, size=512
  /// 适用于：视频缩略图、列表预览图等
  static Future<String> compressThumbnail(String imagePath) async {
    return compressImage(
      imagePath,
      quality: MediaCompressionConfig.thumbnailQuality,
      maxWidth: MediaCompressionConfig.thumbnailMaxSize,
      maxHeight: MediaCompressionConfig.thumbnailMaxSize,
    );
  }

  /// 压缩视频帧
  ///
  /// 使用优化参数：quality=70, size=1024
  /// 适用于：训练视频关键帧提取
  static Future<String> compressVideoFrame(String imagePath) async {
    return compressImage(
      imagePath,
      quality: MediaCompressionConfig.videoFrameQuality,
      maxWidth: MediaCompressionConfig.videoFrameMaxSize,
      maxHeight: MediaCompressionConfig.videoFrameMaxSize,
    );
  }
}
