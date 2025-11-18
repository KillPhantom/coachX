import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_plan_model.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 学生计划模型
///
/// 包含学生所有可见的计划（教练分配 + 自己创建）
class StudentPlansModel {
  final List<ExercisePlanModel> exercisePlans;
  final List<DietPlanModel> dietPlans;
  final List<SupplementPlanModel> supplementPlans;

  const StudentPlansModel({
    this.exercisePlans = const [],
    this.dietPlans = const [],
    this.supplementPlans = const [],
  });

  /// 从JSON创建
  factory StudentPlansModel.fromJson(Map<String, dynamic> json) {
    // 支持两种格式：
    // 1. 新格式（单数）: { exercise_plan: {...}, diet_plan: {...}, ... }
    // 2. 旧格式（复数）: { exercise_plans: [...], diet_plans: [...], ... }

    List<ExercisePlanModel> exercisePlans = [];
    List<DietPlanModel> dietPlans = [];
    List<SupplementPlanModel> supplementPlans = [];

    // 解析 exercise_plan(s)
    try {
      if (json['exercise_plan'] != null) {
        // 新格式：单个对象
        final data = safeMapCast(json['exercise_plan'], 'exercise_plan');
        if (data != null) {
          exercisePlans = [ExercisePlanModel.fromJson(data)];
        }
      } else if (json['exercise_plans'] != null) {
        // 旧格式：数组
        final plansData = safeMapListCast(
          json['exercise_plans'],
          'exercise_plans',
        );
        exercisePlans = plansData
            .map((data) => ExercisePlanModel.fromJson(data))
            .toList();
      }
    } catch (e) {
      AppLogger.error('Error parsing exercise plans', e);
    }

    // 解析 diet_plan(s)
    try {
      if (json['diet_plan'] != null) {
        // 新格式：单个对象
        final data = safeMapCast(json['diet_plan'], 'diet_plan');
        if (data != null) {
          dietPlans = [DietPlanModel.fromJson(data)];
        }
      } else if (json['diet_plans'] != null) {
        // 旧格式：数组
        final plansData = safeMapListCast(json['diet_plans'], 'diet_plans');
        dietPlans = plansData
            .map((data) => DietPlanModel.fromJson(data))
            .toList();
      }
    } catch (e) {
      AppLogger.error('Error parsing diet plans', e);
    }

    // 解析 supplement_plan(s)
    try {
      if (json['supplement_plan'] != null) {
        // 新格式：单个对象
        final data = safeMapCast(json['supplement_plan'], 'supplement_plan');
        if (data != null) {
          supplementPlans = [SupplementPlanModel.fromJson(data)];
        }
      } else if (json['supplement_plans'] != null) {
        // 旧格式：数组
        final plansData = safeMapListCast(
          json['supplement_plans'],
          'supplement_plans',
        );
        supplementPlans = plansData
            .map((data) => SupplementPlanModel.fromJson(data))
            .toList();
      }
    } catch (e) {
      AppLogger.error('Error parsing supplement plans', e);
    }

    return StudentPlansModel(
      exercisePlans: exercisePlans,
      dietPlans: dietPlans,
      supplementPlans: supplementPlans,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'exercise_plans': exercisePlans.map((plan) => plan.toJson()).toList(),
      'diet_plans': dietPlans.map((plan) => plan.toJson()).toList(),
      'supplement_plans': supplementPlans.map((plan) => plan.toJson()).toList(),
    };
  }

  /// 创建空的计划模型
  factory StudentPlansModel.empty() {
    return const StudentPlansModel();
  }

  /// 根据 ID 获取激活的训练计划
  ExercisePlanModel? getActiveExercisePlan(String? activePlanId) {
    if (activePlanId == null || activePlanId.isEmpty) return null;
    try {
      return exercisePlans.firstWhere((plan) => plan.id == activePlanId);
    } catch (e) {
      return null;
    }
  }

  /// 根据 ID 获取激活的饮食计划
  DietPlanModel? getActiveDietPlan(String? activePlanId) {
    if (activePlanId == null || activePlanId.isEmpty) return null;
    try {
      return dietPlans.firstWhere((plan) => plan.id == activePlanId);
    } catch (e) {
      return null;
    }
  }

  /// 根据 ID 获取激活的补剂计划
  SupplementPlanModel? getActiveSupplementPlan(String? activePlanId) {
    if (activePlanId == null || activePlanId.isEmpty) return null;
    try {
      return supplementPlans.firstWhere((plan) => plan.id == activePlanId);
    } catch (e) {
      return null;
    }
  }

  /// 是否有任何计划
  bool get hasAnyPlan =>
      exercisePlans.isNotEmpty ||
      dietPlans.isNotEmpty ||
      supplementPlans.isNotEmpty;

  /// 是否完全没有计划
  bool get hasNoPlan => !hasAnyPlan;

  /// 便捷 getter: 获取第一个训练计划（用于向后兼容）
  /// TODO: 未来应该使用 getActiveExercisePlan(activePlanId)
  ExercisePlanModel? get exercisePlan =>
      exercisePlans.isNotEmpty ? exercisePlans.first : null;

  /// 便捷 getter: 获取第一个饮食计划（用于向后兼容）
  /// TODO: 未来应该使用 getActiveDietPlan(activePlanId)
  DietPlanModel? get dietPlan => dietPlans.isNotEmpty ? dietPlans.first : null;

  /// 便捷 getter: 获取第一个补剂计划（用于向后兼容）
  /// TODO: 未来应该使用 getActiveSupplementPlan(activePlanId)
  SupplementPlanModel? get supplementPlan =>
      supplementPlans.isNotEmpty ? supplementPlans.first : null;

  @override
  String toString() {
    return 'StudentPlansModel(exercise: ${exercisePlans.length}, diet: ${dietPlans.length}, supplement: ${supplementPlans.length})';
  }
}
