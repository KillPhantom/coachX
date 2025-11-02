import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/diet_plan_model.dart';

/// 饮食计划仓库
class DietPlanRepository {
  DietPlanRepository();

  /// 深度转换 Map，将所有嵌套的 Map 转换为 `Map<String, dynamic>`
  Map<String, dynamic> _deepConvertMap(Map map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _deepConvertMap(value);
      } else if (value is List) {
        result[key.toString()] = _deepConvertList(value);
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  /// 深度转换 List，将列表中的所有 Map 转换为 `Map<String, dynamic>`
  List<dynamic> _deepConvertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _deepConvertMap(item);
      } else if (item is List) {
        return _deepConvertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// 安全地解析时间戳，支持 int、String 或 null
  int _parseTimestamp(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// 创建饮食计划
  Future<String> createPlan(DietPlanModel plan) async {
    try {
      AppLogger.info('📝 创建饮食计划: ${plan.name}');

      final result = await CloudFunctionsService.call('diet_plan', {
        'action': 'create',
        'planData': plan.toJson(),
      });

      if (result['status'] == 'success') {
        final planId = result['data']['planId'] as String;
        AppLogger.info('✅ 饮食计划创建成功 - ID: $planId');
        return planId;
      } else {
        throw Exception(result['message'] ?? '创建失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 创建饮食计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 更新饮食计划
  Future<void> updatePlan(DietPlanModel plan) async {
    try {
      if (plan.id.isEmpty) {
        throw Exception('planId 不能为空');
      }

      AppLogger.info('📝 更新饮食计划: ${plan.id}');

      final result = await CloudFunctionsService.call('diet_plan', {
        'action': 'update',
        'planId': plan.id,
        'planData': plan.toJson(),
      });

      if (result['status'] == 'success') {
        AppLogger.info('✅ 饮食计划更新成功');
      } else {
        throw Exception(result['message'] ?? '更新失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 更新饮食计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取饮食计划详情
  Future<DietPlanModel?> getPlan(String planId) async {
    try {
      AppLogger.info('📖 获取饮食计划: $planId');

      final result = await CloudFunctionsService.call('diet_plan', {
        'action': 'get',
        'planId': planId,
      });

      if (result['status'] == 'success') {
        final planData = _deepConvertMap(result['data']['plan'] as Map);

        // 安全地解析时间戳字段
        final plan = DietPlanModel.fromJson({
          ...planData,
          'createdAt': _parseTimestamp(planData['createdAt']),
          'updatedAt': _parseTimestamp(planData['updatedAt']),
        });

        AppLogger.info('✅ 饮食计划获取成功');
        return plan;
      } else {
        AppLogger.warning('⚠️ 饮食计划不存在: $planId');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 获取饮食计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 删除饮食计划
  Future<void> deletePlan(String planId) async {
    try {
      AppLogger.info('🗑️ 删除饮食计划: $planId');

      final result = await CloudFunctionsService.call('diet_plan', {
        'action': 'delete',
        'planId': planId,
      });

      if (result['status'] == 'success') {
        AppLogger.info('✅ 饮食计划删除成功');
      } else {
        throw Exception(result['message'] ?? '删除失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 删除饮食计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 列出所有饮食计划
  Future<List<DietPlanModel>> listPlans() async {
    try {
      AppLogger.info('📋 获取饮食计划列表');

      final result = await CloudFunctionsService.call('diet_plan', {
        'action': 'list',
      });

      if (result['status'] == 'success') {
        final plansData = result['data']['plans'] as List<dynamic>;
        final plans = plansData
            .map(
              (data) => DietPlanModel.fromJson(
                Map<String, dynamic>.from(data as Map),
              ),
            )
            .toList();
        AppLogger.info('✅ 获取饮食计划列表成功 - 数量: ${plans.length}');
        return plans;
      } else {
        throw Exception(result['message'] ?? '获取列表失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 获取饮食计划列表失败', e, stackTrace);
      rethrow;
    }
  }

  /// 复制饮食计划
  Future<String> copyPlan(String planId) async {
    try {
      AppLogger.info('📋 复制饮食计划: $planId');

      final result = await CloudFunctionsService.call('diet_plan', {
        'action': 'copy',
        'planId': planId,
      });

      if (result['status'] == 'success') {
        final newPlanId = result['data']['planId'] as String;
        AppLogger.info('✅ 饮食计划复制成功 - 新ID: $newPlanId');
        return newPlanId;
      } else {
        throw Exception(result['message'] ?? '复制失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 复制饮食计划失败', e, stackTrace);
      rethrow;
    }
  }
}
