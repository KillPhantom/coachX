import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:coach_x/core/utils/logger.dart';

/// OCR 服务
///
/// 使用 Google ML Kit 进行本地文字识别
/// 支持中文和英文
class OCRService {
  /// 从图片提取文字
  ///
  /// [imageFile] 图片文件
  /// 返回提取的文字内容
  ///
  /// 抛出异常：
  /// - 文件不存在
  /// - OCR 识别失败
  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      AppLogger.info('📷 开始 OCR 文字提取');
      AppLogger.info('图片路径: ${imageFile.path}');

      // 检查文件是否存在
      if (!await imageFile.exists()) {
        throw Exception('图片文件不存在');
      }

      // 创建 InputImage
      final inputImage = InputImage.fromFile(imageFile);

      // 创建文字识别器（支持中文）
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.chinese,
      );

      try {
        // 执行 OCR
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        final extractedText = recognizedText.text;

        AppLogger.info('✅ OCR 提取成功');
        AppLogger.info('文字长度: ${extractedText.length} 字符');
        AppLogger.info('文字块数量: ${recognizedText.blocks.length}');

        // 记录前100个字符用于调试
        if (extractedText.length > 100) {
          AppLogger.debug('提取内容预览: ${extractedText.substring(0, 100)}...');
        } else {
          AppLogger.debug('提取内容: $extractedText');
        }

        return extractedText;
      } finally {
        // 确保释放资源
        textRecognizer.close();
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ OCR 文字提取失败', e, stackTrace);
      throw Exception('文字识别失败: $e');
    }
  }

  /// 从图片提取文字（支持自定义脚本）
  ///
  /// [imageFile] 图片文件
  /// [script] 识别脚本类型（默认中文）
  static Future<String> extractTextFromImageWithScript(
    File imageFile, {
    TextRecognitionScript script = TextRecognitionScript.chinese,
  }) async {
    try {
      AppLogger.info('📷 开始 OCR 文字提取 (脚本: $script)');

      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: script);

      try {
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        AppLogger.info('✅ OCR 提取成功: ${recognizedText.text.length} 字符');
        return recognizedText.text;
      } finally {
        textRecognizer.close();
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ OCR 提取失败', e, stackTrace);
      throw Exception('文字识别失败: $e');
    }
  }
}
