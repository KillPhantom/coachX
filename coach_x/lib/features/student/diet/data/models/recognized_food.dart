import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/core/utils/json_utils.dart';

/// AI识别的食物模型
class RecognizedFood {
  final String name;
  final String estimatedWeight;
  final Macros macros;

  const RecognizedFood({
    required this.name,
    required this.estimatedWeight,
    required this.macros,
  });

  /// 从 JSON 创建
  factory RecognizedFood.fromJson(Map<String, dynamic> json) {
    // 使用 safeMapCast 安全解析 macros 对象
    final macrosData = safeMapCast(json['macros'], 'macros');

    return RecognizedFood(
      name: json['name'] as String? ?? '',
      estimatedWeight: json['estimated_weight'] as String? ?? '0g',
      macros: macrosData != null ? Macros.fromJson(macrosData) : Macros.zero(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'estimated_weight': estimatedWeight,
      'macros': macros.toJson(),
    };
  }

  /// 复制并修改部分字段
  RecognizedFood copyWith({
    String? name,
    String? estimatedWeight,
    Macros? macros,
  }) {
    return RecognizedFood(
      name: name ?? this.name,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
      macros: macros ?? this.macros,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecognizedFood &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          estimatedWeight == other.estimatedWeight &&
          macros == other.macros;

  @override
  int get hashCode =>
      name.hashCode ^ estimatedWeight.hashCode ^ macros.hashCode;

  @override
  String toString() {
    return 'RecognizedFood(name: $name, weight: $estimatedWeight, macros: $macros)';
  }
}
