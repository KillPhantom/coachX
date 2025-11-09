import 'meal.dart';
import 'macros.dart';

/// 饮食日模型
class DietDay {
  final int day;
  final String name;
  final List<Meal> meals;
  final bool completed;

  const DietDay({
    required this.day,
    required this.name,
    required this.meals,
    this.completed = false,
  });

  /// 创建空的饮食日
  factory DietDay.empty({int day = 1}) {
    return DietDay(
      day: day,
      name: 'Day $day',
      meals: const [],
      completed: false,
    );
  }

  /// 从 JSON 创建
  factory DietDay.fromJson(Map<String, dynamic> json) {
    final mealsJson = json['meals'] as List<dynamic>? ?? [];
    final meals = mealsJson
        .map((meal) => Meal.fromJson(Map<String, dynamic>.from(meal as Map)))
        .toList();

    return DietDay(
      day: json['day'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      meals: meals,
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'name': name,
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'completed': completed,
    };
  }

  /// 计算该天的总营养数据
  Macros get macros {
    return meals.fold(Macros.zero(), (sum, meal) => sum + meal.macros);
  }

  /// 复制并修改部分字段
  DietDay copyWith({
    int? day,
    String? name,
    List<Meal>? meals,
    bool? completed,
  }) {
    return DietDay(
      day: day ?? this.day,
      name: name ?? this.name,
      meals: meals ?? this.meals,
      completed: completed ?? this.completed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietDay &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          name == other.name &&
          meals == other.meals &&
          completed == other.completed;

  @override
  int get hashCode =>
      day.hashCode ^ name.hashCode ^ meals.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'DietDay(day: $day, name: $name, meals: ${meals.length}, macros: $macros)';
  }
}
