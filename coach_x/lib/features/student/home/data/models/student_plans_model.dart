import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_plan_model.dart';
import 'package:coach_x/core/utils/json_utils.dart';

/// 学生计划模型
///
/// 包含分配给学生的三类计划（训练、饮食、补剂）
class StudentPlansModel {
  final ExercisePlanModel? exercisePlan;
  final DietPlanModel? dietPlan;
  final SupplementPlanModel? supplementPlan;

  const StudentPlansModel({
    this.exercisePlan,
    this.dietPlan,
    this.supplementPlan,
  });

  /// 从JSON创建
  factory StudentPlansModel.fromJson(Map<String, dynamic> json) {
    final exercisePlanData = safeMapCast(json['exercise_plan'], 'exercise_plan');
    final dietPlanData = safeMapCast(json['diet_plan'], 'diet_plan');
    final supplementPlanData = safeMapCast(json['supplement_plan'], 'supplement_plan');

    return StudentPlansModel(
      exercisePlan: exercisePlanData != null
          ? ExercisePlanModel.fromJson(exercisePlanData)
          : null,
      dietPlan: dietPlanData != null
          ? DietPlanModel.fromJson(dietPlanData)
          : null,
      supplementPlan: supplementPlanData != null
          ? SupplementPlanModel.fromJson(supplementPlanData)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'exercise_plan': exercisePlan?.toJson(),
      'diet_plan': dietPlan?.toJson(),
      'supplement_plan': supplementPlan?.toJson(),
    };
  }

  /// 创建空的计划模型
  factory StudentPlansModel.empty() {
    return const StudentPlansModel();
  }

  /// 是否有任何计划
  bool get hasAnyPlan => exercisePlan != null || dietPlan != null || supplementPlan != null;

  /// 是否完全没有计划
  bool get hasNoPlan => !hasAnyPlan;

  @override
  String toString() {
    return 'StudentPlansModel(exercise: ${exercisePlan != null}, diet: ${dietPlan != null}, supplement: ${supplementPlan != null})';
  }
}
