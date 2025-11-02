import 'plan_base_model.dart';
import 'supplement_day.dart';

/// 补剂计划模型
class SupplementPlanModel extends PlanBaseModel {
  final String cyclePattern;
  final List<SupplementDay> days;

  const SupplementPlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.studentIds,
    required super.createdAt,
    required super.updatedAt,
    required this.cyclePattern,
    required this.days,
  });

  @override
  String get planType => 'supplement';

  /// 计算属性 - 总天数
  int get totalDays => days.length;

  /// 计算属性 - 总补剂数
  int get totalSupplements =>
      days.fold(0, (sum, day) => sum + day.timings.fold(0, (s, t) => s + t.supplements.length));

  /// 从JSON创建
  factory SupplementPlanModel.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? [];
    final days = daysJson
        .map((day) => SupplementDay.fromJson(Map<String, dynamic>.from(day as Map)))
        .toList();

    return SupplementPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      studentIds: (json['studentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      cyclePattern: json['cyclePattern'] as String? ?? '',
      days: days,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'studentIds': studentIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'cyclePattern': cyclePattern,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  /// 复制并修改部分字段
  SupplementPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? studentIds,
    int? createdAt,
    int? updatedAt,
    String? cyclePattern,
    List<SupplementDay>? days,
  }) {
    return SupplementPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cyclePattern: cyclePattern ?? this.cyclePattern,
      days: days ?? this.days,
    );
  }
}

