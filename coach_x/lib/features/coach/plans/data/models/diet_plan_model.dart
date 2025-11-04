import 'package:coach_x/core/utils/json_utils.dart';
import 'plan_base_model.dart';
import 'diet_day.dart';

/// 饮食计划模型
class DietPlanModel extends PlanBaseModel {
  final List<DietDay> days;

  const DietPlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.studentIds,
    required super.createdAt,
    required super.updatedAt,
    required this.days,
  });

  @override
  String get planType => 'diet';

  /// 计算属性 - 总天数
  int get totalDays => days.length;

  /// 计算属性 - 总餐次数
  int get totalMeals =>
      days.fold(0, (sum, day) => sum + day.meals.length);

  /// 计算属性 - 总食物条目数
  int get totalFoodItems => days.fold(
        0,
        (sum, day) => sum + day.meals.fold(0, (mealSum, meal) => mealSum + meal.items.length),
      );

  /// 从JSON创建
  factory DietPlanModel.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? [];
    final days = daysJson
        .map((day) => DietDay.fromJson(Map<String, dynamic>.from(day as Map)))
        .toList();

    return DietPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      studentIds: (json['studentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: safeIntCast(json['createdAt'], 0, 'createdAt') ?? 0,
      updatedAt: safeIntCast(json['updatedAt'], 0, 'updatedAt') ?? 0,
      days: days,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'days': days.map((day) => day.toJson()).toList(),
      'ownerId': ownerId,
      'studentIds': studentIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// 复制并修改部分字段
  DietPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? studentIds,
    int? createdAt,
    int? updatedAt,
    List<DietDay>? days,
  }) {
    return DietPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
    );
  }
}

