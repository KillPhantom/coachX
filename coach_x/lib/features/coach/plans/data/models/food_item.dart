import 'macros.dart';

/// 食物条目模型
class FoodItem {
  final String food;
  final String amount;
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final bool isCustomInput;

  const FoodItem({
    required this.food,
    required this.amount,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    this.isCustomInput = false,
  });

  /// 创建空的食物条目
  factory FoodItem.empty() {
    return const FoodItem(
      food: '',
      amount: '',
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      calories: 0.0,
      isCustomInput: true,
    );
  }

  /// 从 JSON 创建
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      food: json['food'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      isCustomInput: json['isCustomInput'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'food': food,
      'amount': amount,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
      'isCustomInput': isCustomInput,
    };
  }

  /// 获取该食物的营养数据
  Macros get macros {
    return Macros(
      protein: protein,
      carbs: carbs,
      fat: fat,
      calories: calories,
    );
  }

  /// 复制并修改部分字段
  FoodItem copyWith({
    String? food,
    String? amount,
    double? protein,
    double? carbs,
    double? fat,
    double? calories,
    bool? isCustomInput,
  }) {
    return FoodItem(
      food: food ?? this.food,
      amount: amount ?? this.amount,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      isCustomInput: isCustomInput ?? this.isCustomInput,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItem &&
          runtimeType == other.runtimeType &&
          food == other.food &&
          amount == other.amount &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          calories == other.calories &&
          isCustomInput == other.isCustomInput;

  @override
  int get hashCode =>
      food.hashCode ^
      amount.hashCode ^
      protein.hashCode ^
      carbs.hashCode ^
      fat.hashCode ^
      calories.hashCode ^
      isCustomInput.hashCode;

  @override
  String toString() {
    return 'FoodItem(food: $food, amount: $amount, macros: $macros)';
  }
}
