/// 营养数据模型
class Macros {
  final double protein;
  final double carbs;
  final double fat;
  final double calories;

  const Macros({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });

  /// 创建零值营养数据
  factory Macros.zero() {
    return const Macros(protein: 0.0, carbs: 0.0, fat: 0.0, calories: 0.0);
  }

  /// 从 JSON 创建
  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
    };
  }

  /// 支持加法运算
  Macros operator +(Macros other) {
    return Macros(
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      calories: calories + other.calories,
    );
  }

  /// 复制并修改部分字段
  Macros copyWith({
    double? protein,
    double? carbs,
    double? fat,
    double? calories,
  }) {
    return Macros(
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Macros &&
          runtimeType == other.runtimeType &&
          protein == other.protein &&
          carbs == other.carbs &&
          fat == other.fat &&
          calories == other.calories;

  @override
  int get hashCode =>
      protein.hashCode ^ carbs.hashCode ^ fat.hashCode ^ calories.hashCode;

  @override
  String toString() {
    return 'Macros(protein: ${protein}g, carbs: ${carbs}g, fat: ${fat}g, calories: ${calories}kcal)';
  }
}
