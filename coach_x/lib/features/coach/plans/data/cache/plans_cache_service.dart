import 'package:hive/hive.dart';
import 'package:coach_x/core/services/cache/cache_helper.dart';
import 'package:coach_x/core/services/cache/cache_metadata.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/exercise_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/supplement_plan_model.dart';

/// Plans 缓存服务
///
/// 负责管理 Plans 列表的本地缓存（不缓存详情）
/// 使用 JSON 格式缓存，避免为所有嵌套模型添加 Hive 注解
class PlansCacheService {
  PlansCacheService._();

  static const String _boxName = 'plans_cache';
  static const Duration _cacheValidity = Duration(days: 7);

  /// 获取 Box
  static Future<Box> _getBox() async {
    return await CacheHelper.openBox(_boxName);
  }

  // ==================== 训练计划列表缓存 ====================

  /// 获取缓存的训练计划列表
  static Future<List<ExercisePlanModel>?> getCachedExercisePlans() async {
    try {
      final box = await _getBox();
      const key = 'plans_list_exercise';
      const metadataKey = '${key}_metadata';

      // 检查元数据
      final metadata = box.get(metadataKey) as CacheMetadata?;
      if (!CacheHelper.isMetadataValid(metadata)) {
        AppLogger.info('❌ 训练计划列表缓存无效或不存在');
        return null;
      }

      // 读取缓存数据（JSON格式）
      final cachedData = box.get(key) as List<dynamic>?;
      if (cachedData == null) {
        AppLogger.info('❌ 训练计划列表缓存数据不存在');
        return null;
      }

      // 将 JSON 转换为 Model
      final plans = cachedData
          .map(
            (json) => ExercisePlanModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      AppLogger.info('✅ 训练计划列表缓存命中: ${plans.length} 个计划');
      return plans;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 读取训练计划列表缓存失败', e, stackTrace);
      return null;
    }
  }

  /// 缓存训练计划列表
  static Future<void> cacheExercisePlans(List<ExercisePlanModel> plans) async {
    try {
      final box = await _getBox();
      const key = 'plans_list_exercise';
      const metadataKey = '${key}_metadata';

      // 将 Model 转换为 JSON
      final jsonList = plans.map((plan) => plan.toJson()).toList();

      // 创建元数据
      final metadata = CacheHelper.createMetadata(key, _cacheValidity);

      // 写入缓存
      await box.put(key, jsonList);
      await box.put(metadataKey, metadata);

      AppLogger.info('💾 训练计划列表已缓存: ${plans.length} 个计划');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 缓存训练计划列表失败', e, stackTrace);
    }
  }

  // ==================== 饮食计划列表缓存 ====================

  /// 获取缓存的饮食计划列表
  static Future<List<DietPlanModel>?> getCachedDietPlans() async {
    try {
      final box = await _getBox();
      const key = 'plans_list_diet';
      const metadataKey = '${key}_metadata';

      // 检查元数据
      final metadata = box.get(metadataKey) as CacheMetadata?;
      if (!CacheHelper.isMetadataValid(metadata)) {
        AppLogger.info('❌ 饮食计划列表缓存无效或不存在');
        return null;
      }

      // 读取缓存数据
      final cachedData = box.get(key) as List<dynamic>?;
      if (cachedData == null) {
        AppLogger.info('❌ 饮食计划列表缓存数据不存在');
        return null;
      }

      // 将 JSON 转换为 Model
      final plans = cachedData
          .map(
            (json) =>
                DietPlanModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();

      AppLogger.info('✅ 饮食计划列表缓存命中: ${plans.length} 个计划');
      return plans;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 读取饮食计划列表缓存失败', e, stackTrace);
      return null;
    }
  }

  /// 缓存饮食计划列表
  static Future<void> cacheDietPlans(List<DietPlanModel> plans) async {
    try {
      final box = await _getBox();
      const key = 'plans_list_diet';
      const metadataKey = '${key}_metadata';

      // 将 Model 转换为 JSON
      final jsonList = plans.map((plan) => plan.toJson()).toList();

      // 创建元数据
      final metadata = CacheHelper.createMetadata(key, _cacheValidity);

      // 写入缓存
      await box.put(key, jsonList);
      await box.put(metadataKey, metadata);

      AppLogger.info('💾 饮食计划列表已缓存: ${plans.length} 个计划');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 缓存饮食计划列表失败', e, stackTrace);
    }
  }

  // ==================== 补剂计划列表缓存 ====================

  /// 获取缓存的补剂计划列表
  static Future<List<SupplementPlanModel>?> getCachedSupplementPlans() async {
    try {
      final box = await _getBox();
      const key = 'plans_list_supplement';
      const metadataKey = '${key}_metadata';

      // 检查元数据
      final metadata = box.get(metadataKey) as CacheMetadata?;
      if (!CacheHelper.isMetadataValid(metadata)) {
        AppLogger.info('❌ 补剂计划列表缓存无效或不存在');
        return null;
      }

      // 读取缓存数据
      final cachedData = box.get(key) as List<dynamic>?;
      if (cachedData == null) {
        AppLogger.info('❌ 补剂计划列表缓存数据不存在');
        return null;
      }

      // 将 JSON 转换为 Model
      final plans = cachedData
          .map(
            (json) => SupplementPlanModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      AppLogger.info('✅ 补剂计划列表缓存命中: ${plans.length} 个计划');
      return plans;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 读取补剂计划列表缓存失败', e, stackTrace);
      return null;
    }
  }

  /// 缓存补剂计划列表
  static Future<void> cacheSupplementPlans(
    List<SupplementPlanModel> plans,
  ) async {
    try {
      final box = await _getBox();
      const key = 'plans_list_supplement';
      const metadataKey = '${key}_metadata';

      // 将 Model 转换为 JSON
      final jsonList = plans.map((plan) => plan.toJson()).toList();

      // 创建元数据
      final metadata = CacheHelper.createMetadata(key, _cacheValidity);

      // 写入缓存
      await box.put(key, jsonList);
      await box.put(metadataKey, metadata);

      AppLogger.info('💾 补剂计划列表已缓存: ${plans.length} 个计划');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 缓存补剂计划列表失败', e, stackTrace);
    }
  }

  // ==================== 缓存失效 ====================

  /// 清除指定类型的列表缓存
  ///
  /// [planType] 计划类型：'exercise', 'diet', 'supplement'
  static Future<void> invalidateListCache(String planType) async {
    try {
      final box = await _getBox();
      final key = 'plans_list_$planType';
      final metadataKey = '${key}_metadata';

      await box.delete(key);
      await box.delete(metadataKey);

      AppLogger.info('🗑️ 已清除 $planType 计划列表缓存');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除计划列表缓存失败: $planType', e, stackTrace);
    }
  }

  /// 清除所有计划缓存
  static Future<void> invalidateAllPlansCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      AppLogger.info('🗑️ 已清除所有计划缓存');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除所有计划缓存失败', e, stackTrace);
    }
  }

  /// 清除过期缓存
  static Future<void> clearExpiredCache() async {
    try {
      final box = await _getBox();
      await CacheHelper.clearExpiredCache(box, _cacheValidity);
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除过期计划缓存失败', e, stackTrace);
    }
  }
}
