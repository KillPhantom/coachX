import '../models/recognized_food.dart';

/// AI食物识别Repository接口
abstract class AIFoodRepository {
  /// 分析食物图片并返回营养估算
  ///
  /// [imageUrl] Firebase Storage的图片URL
  /// [language] 输出语言（默认"中文"）
  /// 返回识别的食物列表
  Future<List<RecognizedFood>> analyzeFoodImage({
    required String imageUrl,
    String language = '中文',
  });
}
