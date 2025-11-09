import '../models/student_list_item_model.dart';
import '../models/plan_summary.dart';

/// 学生列表查询结果
class StudentsPageResult {
  final List<StudentListItemModel> students;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
  final int totalPages;

  const StudentsPageResult({
    required this.students,
    required this.totalCount,
    required this.hasMore,
    required this.currentPage,
    required this.totalPages,
  });
}

/// 学生Repository接口
abstract class StudentRepository {
  /// 获取学生列表
  Future<StudentsPageResult> fetchStudents({
    required int pageSize,
    required int pageNumber,
    String? searchName,
    String? filterPlanId,
    bool includePlans = true, // 是否包含计划信息，默认true保持向后兼容
  });

  /// 删除学生
  Future<void> deleteStudent(String studentId);

  /// 获取可用计划列表（原始格式）
  Future<Map<String, List<Map<String, String>>>> fetchAvailablePlans();

  /// 获取可用计划摘要列表（用于分配计划对话框）
  ///
  /// 返回三类计划的PlanSummary列表
  /// [maxPerType] 每类计划的最大数量，默认100
  Future<Map<String, List<PlanSummary>>> fetchAvailablePlansSummary({
    int maxPerType = 100,
  });
}
