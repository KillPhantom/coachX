import 'package:coach_x/features/coach/students/data/models/student_list_item_model.dart';
import '../models/exercise_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/supplement_plan_model.dart';

/// 计划仓库接口
abstract class PlanRepository {
  /// 获取所有计划
  /// 返回三类计划的数据
  Future<PlansData> fetchAllPlans();

  /// 创建训练计划
  /// [plan] 计划数据
  /// 返回新计划的ID
  Future<String> createPlan({required ExercisePlanModel plan});

  /// 更新训练计划
  /// [plan] 计划数据（必须包含ID）
  Future<void> updatePlan({required ExercisePlanModel plan});

  /// 获取训练计划详情
  /// [planId] 计划ID
  Future<ExercisePlanModel> getPlanDetail({required String planId});

  /// 删除计划
  /// [planId] 计划ID
  /// [planType] 计划类型: 'exercise', 'diet', 'supplement'
  Future<void> deletePlan(String planId, String planType);

  /// 复制计划
  /// [planId] 计划ID
  /// [planType] 计划类型: 'exercise', 'diet', 'supplement'
  /// 返回新计划的ID
  Future<String> copyPlan(String planId, String planType);

  /// 分配计划给学生
  /// [planId] 计划ID
  /// [planType] 计划类型: 'exercise', 'diet', 'supplement'
  /// [studentIds] 学生ID列表
  /// [unassign] 是否为取消分配（true为取消分配，false为分配）
  Future<void> assignPlanToStudents({
    required String planId,
    required String planType,
    required List<String> studentIds,
    required bool unassign,
  });

  /// 获取学生列表（用于分配计划弹窗）
  /// [planId] 计划ID（用于标记已分配的学生）
  /// [planType] 计划类型（用于检测同类计划冲突）
  Future<List<StudentListItemModel>> fetchStudentsForAssignment(
    String planId,
    String planType,
  );
}

/// 计划数据（所有类型计划的集合）
class PlansData {
  final List<ExercisePlanModel> exercisePlans;
  final List<DietPlanModel> dietPlans;
  final List<SupplementPlanModel> supplementPlans;

  const PlansData({
    required this.exercisePlans,
    required this.dietPlans,
    required this.supplementPlans,
  });

  /// 空数据
  factory PlansData.empty() {
    return const PlansData(
      exercisePlans: [],
      dietPlans: [],
      supplementPlans: [],
    );
  }
}
