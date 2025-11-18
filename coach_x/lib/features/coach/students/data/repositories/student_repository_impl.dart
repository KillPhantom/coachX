import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/student_list_item_model.dart';
import '../models/plan_summary.dart';
import '../cache/students_cache_service.dart';
import 'student_repository.dart';

/// 学生Repository实现
class StudentRepositoryImpl implements StudentRepository {
  @override
  Future<StudentsPageResult> fetchStudents({
    required int pageSize,
    required int pageNumber,
    String? searchName,
    String? filterPlanId,
    bool includePlans = true,
  }) async {
    try {
      // 1. 尝试从缓存读取
      final cachedStudents = await StudentsCacheService.getCachedStudents(
        pageNumber,
        searchName,
        filterPlanId,
      );

      if (cachedStudents != null) {
        // 缓存命中，返回缓存数据
        // 注意：从缓存返回时，无法获取 totalCount/hasMore 等分页信息
        // 这些信息需要从服务器获取，所以使用默认值
        return StudentsPageResult(
          students: cachedStudents,
          totalCount: cachedStudents.length,
          hasMore: false,
          currentPage: pageNumber,
          totalPages: 1,
        );
      }

      // 2. 缓存无效，调用 Cloud Function
      final params = <String, dynamic>{
        'page_size': pageSize,
        'page_number': pageNumber,
        'include_plans': includePlans,
      };

      if (searchName != null && searchName.isNotEmpty) {
        params['search_name'] = searchName;
      }

      if (filterPlanId != null && filterPlanId.isNotEmpty) {
        params['filter_plan_id'] = filterPlanId;
      }

      AppLogger.info('调用fetch_students: $params');

      final response = await CloudFunctionsService.call(
        'fetch_students',
        params,
      );
      final data = Map<String, dynamic>.from(response['data'] as Map);

      // 解析学生列表
      final studentsList = List<dynamic>.from(data['students'] as List);
      final students = studentsList
          .map(
            (json) => StudentListItemModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      final result = StudentsPageResult(
        students: students,
        totalCount: data['total_count'] as int,
        hasMore: data['has_more'] as bool,
        currentPage: data['current_page'] as int,
        totalPages: data['total_pages'] as int,
      );

      AppLogger.info('fetch_students成功: ${students.length}个学生');

      // 3. 写入缓存
      await StudentsCacheService.cacheStudents(
        students,
        pageNumber,
        searchName,
        filterPlanId,
      );

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('获取学生列表失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    try {
      AppLogger.info('调用delete_student: $studentId');

      await CloudFunctionsService.call('delete_student', {
        'student_id': studentId,
      });

      AppLogger.info('delete_student成功');

      // 删除成功后清除缓存
      await StudentsCacheService.invalidateCache();
    } catch (e, stackTrace) {
      AppLogger.error('删除学生失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, List<Map<String, String>>>> fetchAvailablePlans() async {
    try {
      AppLogger.info('调用fetch_available_plans');

      final response = await CloudFunctionsService.call(
        'fetch_available_plans',
      );
      final data = Map<String, dynamic>.from(response['data'] as Map);

      // 转换为需要的格式
      final result = <String, List<Map<String, String>>>{
        'exercise_plans': _parseplansList(data['exercise_plans']),
        'diet_plans': _parseplansList(data['diet_plans']),
        'supplement_plans': _parseplansList(data['supplement_plans']),
      };

      AppLogger.info('fetch_available_plans成功');

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('获取可用计划失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, List<PlanSummary>>> fetchAvailablePlansSummary({
    int maxPerType = 100,
  }) async {
    try {
      AppLogger.info('调用fetch_available_plans（获取摘要）');

      final response = await CloudFunctionsService.call(
        'fetch_available_plans',
      );
      final data = Map<String, dynamic>.from(response['data'] as Map);

      // 解析三类计划为PlanSummary列表
      final exercisePlans = _parsePlansSummaryList(
        data['exercise_plans'],
        'exercise',
        maxPerType,
      );
      final dietPlans = _parsePlansSummaryList(
        data['diet_plans'],
        'diet',
        maxPerType,
      );
      final supplementPlans = _parsePlansSummaryList(
        data['supplement_plans'],
        'supplement',
        maxPerType,
      );

      final result = <String, List<PlanSummary>>{
        'exercise': exercisePlans,
        'diet': dietPlans,
        'supplement': supplementPlans,
      };

      AppLogger.info(
        'fetch_available_plans_summary成功: '
        '训练${exercisePlans.length}个, '
        '饮食${dietPlans.length}个, '
        '补剂${supplementPlans.length}个',
      );

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('获取可用计划摘要失败', e, stackTrace);
      rethrow;
    }
  }

  /// 解析计划列表
  List<Map<String, String>> _parseplansList(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];

    return data.map((item) {
      if (item is! Map) return <String, String>{};
      final itemMap = Map<String, dynamic>.from(item);
      return <String, String>{
        'id': itemMap['id'] as String? ?? '',
        'name': itemMap['name'] as String? ?? '',
      };
    }).toList();
  }

  /// 解析计划摘要列表
  List<PlanSummary> _parsePlansSummaryList(
    dynamic data,
    String planType,
    int maxCount,
  ) {
    if (data == null) return [];
    if (data is! List) return [];

    final plans = data
        .map((item) {
          if (item is! Map) return null;
          try {
            final itemMap = Map<String, dynamic>.from(item);
            return PlanSummary(
              id: itemMap['id'] as String? ?? '',
              name: itemMap['name'] as String? ?? '',
              description: itemMap['description'] as String?,
              studentCount:
                  itemMap['studentCount'] as int? ??
                  (itemMap['student_count'] as int? ?? 0),
              planType: planType,
            );
          } catch (e) {
            AppLogger.error('解析计划摘要失败: $e');
            return null;
          }
        })
        .whereType<PlanSummary>()
        .take(maxCount)
        .toList();

    return plans;
  }
}
