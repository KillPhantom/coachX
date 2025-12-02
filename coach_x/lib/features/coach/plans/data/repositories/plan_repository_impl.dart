import 'package:cloud_functions/cloud_functions.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/students/data/models/student_list_item_model.dart';
import '../models/exercise_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/supplement_plan_model.dart';
import '../cache/plans_cache_service.dart';
import 'plan_repository.dart';

/// 计划仓库实现
class PlanRepositoryImpl implements PlanRepository {
  PlanRepositoryImpl();

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

  @override
  Future<PlansData> fetchAllPlans() async {
    try {
      AppLogger.debug('📥 获取所有计划列表');

      // 1. 尝试从缓存读取三类计划列表
      final cachedExercisePlans =
          await PlansCacheService.getCachedExercisePlans();
      final cachedDietPlans = await PlansCacheService.getCachedDietPlans();
      final cachedSupplementPlans =
          await PlansCacheService.getCachedSupplementPlans();

      // 如果所有列表缓存都有效，返回缓存数据
      if (cachedExercisePlans != null &&
          cachedDietPlans != null &&
          cachedSupplementPlans != null) {
        AppLogger.debug(
          '✅ 所有计划列表缓存命中: 训练${cachedExercisePlans.length}, 饮食${cachedDietPlans.length}, 补剂${cachedSupplementPlans.length}',
        );
        return PlansData(
          exercisePlans: cachedExercisePlans,
          dietPlans: cachedDietPlans,
          supplementPlans: cachedSupplementPlans,
        );
      }

      // 2. 缓存无效，调用 Cloud Function
      final result = await CloudFunctionsService.call(
        'fetch_available_plans',
        {},
      );

      if (result['status'] != 'success') {
        throw Exception('获取计划列表失败: ${result['message']}');
      }

      final data = _deepConvertMap(result['data'] as Map);

      // 解析训练计划
      final exercisePlansJson = data['exercise_plans'] as List<dynamic>? ?? [];
      final exercisePlans = exercisePlansJson.map((json) {
        final planJson = _deepConvertMap(json as Map);
        return ExercisePlanModel.fromJson({
          ...planJson,
          'description': planJson['description'] ?? '',
          'ownerId': planJson['ownerId'] ?? '',
          'studentIds': planJson['studentIds'] ?? [],
          'createdAt': _parseTimestamp(planJson['createdAt']),
          'updatedAt': _parseTimestamp(planJson['updatedAt']),
          'cyclePattern': planJson['cyclePattern'] ?? '',
        });
      }).toList();

      // 解析饮食计划
      final dietPlansJson = data['diet_plans'] as List<dynamic>? ?? [];
      final dietPlans = dietPlansJson.map((json) {
        final planJson = _deepConvertMap(json as Map);
        return DietPlanModel.fromJson({
          ...planJson,
          'description': planJson['description'] ?? '',
          'ownerId': planJson['ownerId'] ?? '',
          'studentIds': planJson['studentIds'] ?? [],
          'createdAt': _parseTimestamp(planJson['createdAt']),
          'updatedAt': _parseTimestamp(planJson['updatedAt']),
          'cyclePattern': planJson['cyclePattern'] ?? '',
        });
      }).toList();

      // 解析补剂计划
      final supplementPlansJson =
          data['supplement_plans'] as List<dynamic>? ?? [];
      final supplementPlans = supplementPlansJson.map((json) {
        final planJson = _deepConvertMap(json as Map);
        return SupplementPlanModel.fromJson({
          ...planJson,
          'description': planJson['description'] ?? '',
          'ownerId': planJson['ownerId'] ?? '',
          'studentIds': planJson['studentIds'] ?? [],
          'createdAt': _parseTimestamp(planJson['createdAt']),
          'updatedAt': _parseTimestamp(planJson['updatedAt']),
          'cyclePattern': planJson['cyclePattern'] ?? '',
        });
      }).toList();

      AppLogger.debug(
        '✅ 获取计划成功: 训练${exercisePlans.length}, 饮食${dietPlans.length}, 补剂${supplementPlans.length}',
      );

      // 3. 写入缓存
      await PlansCacheService.cacheExercisePlans(exercisePlans);
      await PlansCacheService.cacheDietPlans(dietPlans);
      await PlansCacheService.cacheSupplementPlans(supplementPlans);

      return PlansData(
        exercisePlans: exercisePlans,
        dietPlans: dietPlans,
        supplementPlans: supplementPlans,
      );
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 获取计划列表失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 获取计划列表失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> createPlan({required ExercisePlanModel plan}) async {
    try {
      AppLogger.debug('📝 创建训练计划: ${plan.name}');

      final result = await CloudFunctionsService.createExercisePlan(
        planData: plan.toJson(),
      );

      if (result['status'] != 'success') {
        throw Exception('创建计划失败: ${result['message']}');
      }

      final planId = result['data']['planId'] as String;
      AppLogger.debug('✅ 创建训练计划成功: $planId');

      // 创建成功后清除对应类型的列表缓存
      await PlansCacheService.invalidateListCache('exercise');

      return planId;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 创建计划失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 创建计划失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePlan({required ExercisePlanModel plan}) async {
    try {
      AppLogger.debug('📝 更新训练计划: ${plan.id}');

      final result = await CloudFunctionsService.updateExercisePlan(
        planId: plan.id,
        planData: plan.toJson(),
      );

      if (result['status'] != 'success') {
        throw Exception('更新计划失败: ${result['message']}');
      }

      AppLogger.debug('✅ 更新训练计划成功');

      // 更新成功后清除详情缓存和列表缓存
      await PlansCacheService.invalidatePlanDetail(plan.id, 'exercise');
      await PlansCacheService.invalidateListCache('exercise');
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 更新计划失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 更新计划失败: $e');
      rethrow;
    }
  }

  @override
  Future<ExercisePlanModel> getPlanDetail({required String planId}) async {
    try {
      AppLogger.debug('📖 获取训练计划详情: $planId');

      // 1. 尝试从缓存读取
      final cachedPlanJson = await PlansCacheService.getCachedPlanDetail(
        planId,
        'exercise',
      );
      if (cachedPlanJson != null) {
        final plan = ExercisePlanModel.fromJson(cachedPlanJson);
        AppLogger.debug('✅ 训练计划详情从缓存加载成功');
        return plan;
      }

      // 2. 缓存无效，调用 Cloud Function
      final result = await CloudFunctionsService.getExercisePlanDetail(
        planId: planId,
      );

      AppLogger.debug('📦 Cloud Function 返回数据: ${result.runtimeType}');
      AppLogger.debug('📦 返回数据 keys: ${result.keys}');

      if (result['status'] != 'success') {
        throw Exception('获取计划详情失败: ${result['message']}');
      }

      // 使用 _deepConvertMap 进行深层次类型转换
      final planData = result['data']['plan'];
      AppLogger.debug('📦 planData 类型: ${planData.runtimeType}');

      final planJson = _deepConvertMap(planData as Map);

      // 安全地解析时间戳字段
      final normalizedJson = {
        ...planJson,
        'createdAt': _parseTimestamp(planJson['createdAt']),
        'updatedAt': _parseTimestamp(planJson['updatedAt']),
      };

      final plan = ExercisePlanModel.fromJson(normalizedJson);

      // 3. 写入缓存
      await PlansCacheService.cachePlanDetail(planId, 'exercise', normalizedJson);

      AppLogger.debug('✅ 获取训练计划详情成功');

      return plan;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 获取计划详情失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 获取计划详情失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePlan(String planId, String planType) async {
    try {
      AppLogger.debug('🗑️ 删除计划: $planType/$planId');

      final functionName = '${planType}Plan';
      final result = await CloudFunctionsService.call(functionName, {
        'action': 'delete',
        'planId': planId,
      });

      if (result['status'] != 'success') {
        throw Exception('删除计划失败: ${result['message']}');
      }

      AppLogger.debug('✅ 删除计划成功');

      // 删除成功后清除列表缓存
      await PlansCacheService.invalidateListCache(planType);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 删除计划失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 删除计划失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> copyPlan(String planId, String planType) async {
    try {
      AppLogger.debug('📋 复制计划: $planType/$planId');

      final functionName = '${planType}Plan';
      final result = await CloudFunctionsService.call(functionName, {
        'action': 'copy',
        'planId': planId,
      });

      if (result['status'] != 'success') {
        throw Exception('复制计划失败: ${result['message']}');
      }

      final newPlanId = result['data']['planId'] as String;
      AppLogger.debug('✅ 复制计划成功: $newPlanId');

      // 复制成功后清除列表缓存
      await PlansCacheService.invalidateListCache(planType);

      return newPlanId;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 复制计划失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 复制计划失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> assignPlanToStudents({
    required String planId,
    required String planType,
    required List<String> studentIds,
    required bool unassign,
  }) async {
    try {
      final action = unassign ? 'unassign' : 'assign';
      AppLogger.debug(
        '👥 ${action == 'assign' ? '分配' : '取消分配'}计划: $planType/$planId 给 ${studentIds.length} 位学生',
      );

      final result = await CloudFunctionsService.call('assign_plan', {
        'action': action,
        'planType': planType,
        'planId': planId,
        'studentIds': studentIds,
      });

      if (result['status'] != 'success') {
        throw Exception(
          '${action == 'assign' ? '分配' : '取消分配'}计划失败: ${result['message']}',
        );
      }

      AppLogger.debug('✅ ${action == 'assign' ? '分配' : '取消分配'}计划成功');

      // 分配/取消分配成功后清除列表缓存（studentIds改变）
      await PlansCacheService.invalidateListCache(planType);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 分配计划失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 分配计划失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<StudentListItemModel>> fetchStudentsForAssignment(
    String planId,
    String planType,
  ) async {
    try {
      AppLogger.debug('👥 获取学生列表（用于分配计划）');

      // 获取所有学生（限制为100个学生）
      final result = await CloudFunctionsService.call('fetch_students', {
        'pageSize': 100, // 最大页面尺寸（后端限制）
        'pageNumber': 1,
      });

      if (result['status'] != 'success') {
        throw Exception('获取学生列表失败: ${result['message']}');
      }

      final data = Map<String, dynamic>.from(result['data'] as Map);
      final studentsJson = List<dynamic>.from(data['students'] as List? ?? []);
      final students = studentsJson
          .map(
            (json) => StudentListItemModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      AppLogger.debug('✅ 获取学生列表成功: ${students.length} 位学生');

      return students;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('❌ 获取学生列表失败: ${e.code} - ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      AppLogger.error('❌ 获取学生列表失败: $e');
      rethrow;
    }
  }

  /// 处理Firebase错误
  Exception _handleFirebaseError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return Exception('请先登录');
      case 'permission-denied':
        return Exception('没有权限执行此操作');
      case 'not-found':
        return Exception('计划不存在');
      case 'already-exists':
        return Exception('计划已存在');
      case 'invalid-argument':
        return Exception('参数错误: ${e.message}');
      default:
        return Exception('操作失败: ${e.message}');
    }
  }
}
