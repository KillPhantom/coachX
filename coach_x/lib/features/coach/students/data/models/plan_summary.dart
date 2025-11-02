import 'package:coach_x/features/coach/plans/data/models/plan_base_model.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_plan_model.dart';

/// 计划摘要模型（用于分配计划对话框）
///
/// 简化的计划信息，只包含用于选择和显示的必要字段
class PlanSummary {
  /// 计划ID
  final String id;

  /// 计划名称
  final String name;

  /// 计划描述
  final String? description;

  /// 已分配的学生数量
  final int studentCount;

  /// 计划类型: 'exercise', 'diet', 'supplement'
  final String planType;

  const PlanSummary({
    required this.id,
    required this.name,
    this.description,
    required this.studentCount,
    required this.planType,
  });

  /// 从ExercisePlanModel创建
  factory PlanSummary.fromExercisePlan(ExercisePlanModel plan) {
    return PlanSummary(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      studentCount: plan.studentIds.length,
      planType: 'exercise',
    );
  }

  /// 从DietPlanModel创建
  factory PlanSummary.fromDietPlan(DietPlanModel plan) {
    return PlanSummary(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      studentCount: plan.studentIds.length,
      planType: 'diet',
    );
  }

  /// 从SupplementPlanModel创建
  factory PlanSummary.fromSupplementPlan(SupplementPlanModel plan) {
    return PlanSummary(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      studentCount: plan.studentIds.length,
      planType: 'supplement',
    );
  }

  /// 从通用PlanBaseModel创建
  factory PlanSummary.fromPlanBase(PlanBaseModel plan) {
    return PlanSummary(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      studentCount: plan.studentIds.length,
      planType: plan.planType,
    );
  }

  /// 从JSON创建
  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    return PlanSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      studentCount: json['studentCount'] as int? ?? 0,
      planType: json['planType'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'studentCount': studentCount,
      'planType': planType,
    };
  }

  /// 获取计划类型的显示名称
  String get planTypeDisplayName {
    switch (planType) {
      case 'exercise':
        return '训练计划';
      case 'diet':
        return '饮食计划';
      case 'supplement':
        return '补剂计划';
      default:
        return '未知计划';
    }
  }

  /// 获取简要信息（用于副标题显示）
  String get briefInfo {
    final parts = <String>[];

    if (description != null && description!.isNotEmpty) {
      parts.add(description!);
    }

    parts.add('$studentCount位学生');

    return parts.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          planType == other.planType;

  @override
  int get hashCode => id.hashCode ^ planType.hashCode;

  @override
  String toString() {
    return 'PlanSummary{id: $id, name: $name, planType: $planType, studentCount: $studentCount}';
  }
}
