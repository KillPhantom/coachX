/// 学生计划信息模型
class StudentPlanInfo {
  final String id;
  final String name;
  final String type; // 'exercise', 'diet', 'supplement'

  const StudentPlanInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  /// 从JSON创建
  factory StudentPlanInfo.fromJson(Map<String, dynamic> json) {
    return StudentPlanInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  /// 是否为训练计划
  bool get isExercisePlan => type == 'exercise';

  /// 是否为饮食计划
  bool get isDietPlan => type == 'diet';

  /// 是否为补剂计划
  bool get isSupplementPlan => type == 'supplement';
}

