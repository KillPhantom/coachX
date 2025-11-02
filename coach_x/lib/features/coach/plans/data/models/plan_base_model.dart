/// 计划基础模型（抽象类）
abstract class PlanBaseModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> studentIds;
  final int createdAt;
  final int updatedAt;

  const PlanBaseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.studentIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计划类型
  String get planType;

  /// 使用该计划的学生数量
  int get studentCount => studentIds.length;

  /// 是否为训练计划
  bool get isExercisePlan => planType == 'exercise';

  /// 是否为饮食计划
  bool get isDietPlan => planType == 'diet';

  /// 是否为补剂计划
  bool get isSupplementPlan => planType == 'supplement';

  /// 计划类型显示名称
  String get planTypeDisplayName {
    switch (planType) {
      case 'exercise':
        return '训练计划';
      case 'diet':
        return '饮食计划';
      case 'supplement':
        return '补剂计划';
      default:
        return '未知类型';
    }
  }

  /// 转换为JSON（子类实现）
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanBaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

