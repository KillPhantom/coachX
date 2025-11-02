import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/supplement_plan_model.dart';

/// 补剂计划仓库
class SupplementPlanRepository {
  SupplementPlanRepository();

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

  /// 创建补剂计划
  Future<String> createPlan(SupplementPlanModel plan) async {
    try {
      AppLogger.info('📝 创建补剂计划: ${plan.name}');

      final result = await CloudFunctionsService.call('supplement_plan', {
        'action': 'create',
        'planData': plan.toJson(),
      });

      if (result['status'] == 'success') {
        final planId = result['data']['planId'] as String;
        AppLogger.info('✅ 补剂计划创建成功 - ID: $planId');
        return planId;
      } else {
        throw Exception(result['message'] ?? '创建失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 创建补剂计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 更新补剂计划
  Future<void> updatePlan(SupplementPlanModel plan) async {
    try {
      if (plan.id.isEmpty) {
        throw Exception('planId 不能为空');
      }

      AppLogger.info('📝 更新补剂计划: ${plan.id}');

      final result = await CloudFunctionsService.call('supplement_plan', {
        'action': 'update',
        'planId': plan.id,
        'planData': plan.toJson(),
      });

      if (result['status'] == 'success') {
        AppLogger.info('✅ 补剂计划更新成功');
      } else {
        throw Exception(result['message'] ?? '更新失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 更新补剂计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取补剂计划详情
  Future<SupplementPlanModel?> getPlan(String planId) async {
    try {
      AppLogger.info('📖 获取补剂计划: $planId');

      final result = await CloudFunctionsService.call('supplement_plan', {
        'action': 'get',
        'planId': planId,
      });

      if (result['status'] == 'success') {
        final planData = _deepConvertMap(result['data']['plan'] as Map);

        // 安全地解析时间戳字段
        final plan = SupplementPlanModel.fromJson({
          ...planData,
          'createdAt': _parseTimestamp(planData['createdAt']),
          'updatedAt': _parseTimestamp(planData['updatedAt']),
        });

        AppLogger.info('✅ 补剂计划获取成功');
        return plan;
      } else {
        AppLogger.warning('⚠️ 补剂计划不存在: $planId');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 获取补剂计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 删除补剂计划
  Future<void> deletePlan(String planId) async {
    try {
      AppLogger.info('🗑️ 删除补剂计划: $planId');

      final result = await CloudFunctionsService.call('supplement_plan', {
        'action': 'delete',
        'planId': planId,
      });

      if (result['status'] == 'success') {
        AppLogger.info('✅ 补剂计划删除成功');
      } else {
        throw Exception(result['message'] ?? '删除失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 删除补剂计划失败', e, stackTrace);
      rethrow;
    }
  }

  /// 列出所有补剂计划
  Future<List<SupplementPlanModel>> listPlans() async {
    try {
      AppLogger.info('📋 获取补剂计划列表');

      final result = await CloudFunctionsService.call('supplement_plan', {
        'action': 'list',
      });

      if (result['status'] == 'success') {
        final plansData = result['data']['plans'] as List<dynamic>;
        final plans = plansData
            .map(
              (data) => SupplementPlanModel.fromJson(
                Map<String, dynamic>.from(data as Map),
              ),
            )
            .toList();
        AppLogger.info('✅ 获取补剂计划列表成功 - 数量: ${plans.length}');
        return plans;
      } else {
        throw Exception(result['message'] ?? '获取列表失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 获取补剂计划列表失败', e, stackTrace);
      rethrow;
    }
  }

  /// 复制补剂计划
  Future<String> copyPlan(String planId) async {
    try {
      AppLogger.info('📋 复制补剂计划: $planId');

      final result = await CloudFunctionsService.call('supplement_plan', {
        'action': 'copy',
        'planId': planId,
      });

      if (result['status'] == 'success') {
        final newPlanId = result['data']['planId'] as String;
        AppLogger.info('✅ 补剂计划复制成功 - 新ID: $newPlanId');
        return newPlanId;
      } else {
        throw Exception(result['message'] ?? '复制失败');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 复制补剂计划失败', e, stackTrace);
      rethrow;
    }
  }
}
