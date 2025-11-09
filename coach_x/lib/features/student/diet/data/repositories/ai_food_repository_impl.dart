import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import '../models/recognized_food.dart';
import 'ai_food_repository.dart';

/// AI食物识别Repository实现
class AIFoodRepositoryImpl implements AIFoodRepository {
  @override
  Future<List<RecognizedFood>> analyzeFoodImage({
    required String imageUrl,
    String language = '中文',
  }) async {
    try {
      AppLogger.info('🍽️ 调用AI食物分析 - URL: ${imageUrl.substring(0, 50)}...');

      // 调用Cloud Function
      final result = await CloudFunctionsService.call(
        'analyze_food_nutrition',
        {'image_url': imageUrl, 'language': language},
      );

      AppLogger.debug('AI食物分析响应: $result');

      if (result['status'] == 'success') {
        // 使用 safeMapCast 安全解析 data 对象
        final data = safeMapCast(result['data'], 'data');

        if (data == null) {
          AppLogger.warning('⚠️ AI分析返回数据为空');
          return [];
        }

        // 使用safeMapListCast安全解析foods数组
        final foodsData = safeMapListCast(data['foods'], 'foods');

        if (foodsData.isEmpty) {
          AppLogger.warning('⚠️ AI未识别到任何食物');
          return [];
        }

        final foods = foodsData
            .map((foodJson) => RecognizedFood.fromJson(foodJson))
            .toList();

        AppLogger.info('✅ AI识别成功 - ${foods.length} 种食物');
        for (var food in foods) {
          AppLogger.info('  - ${food.name} (${food.estimatedWeight})');
        }

        return foods;
      } else {
        final error = result['error'] as String? ?? '未知错误';
        AppLogger.error('❌ AI分析失败: $error');
        throw Exception('AI分析失败: $error');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ AI食物分析异常', e, stackTrace);
      rethrow;
    }
  }
}
