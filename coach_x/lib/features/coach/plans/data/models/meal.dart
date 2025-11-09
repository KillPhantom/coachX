import 'food_item.dart';
import 'macros.dart';

/// 餐次模型
class Meal {
  final String name;
  final String note;
  final List<FoodItem> items;
  final bool completed;
  final List<String> images;

  const Meal({
    required this.name,
    this.note = '',
    required this.items,
    this.completed = false,
    this.images = const [],
  });

  /// 创建空的餐次
  factory Meal.empty() {
    return const Meal(
      name: '',
      note: '',
      items: [],
      completed: false,
      images: [],
    );
  }

  /// 从 JSON 创建
  factory Meal.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map(
          (item) => FoodItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    final imagesJson = json['images'] as List<dynamic>? ?? [];
    final images = imagesJson.map((e) => e as String).toList();

    return Meal(
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      items: items,
      completed: json['completed'] as bool? ?? false,
      images: images,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
      'completed': completed,
      'images': images,
      'macros': macros.toJson(),
    };
  }

  /// 计算该餐次的总营养数据
  Macros get macros {
    return items.fold(Macros.zero(), (sum, item) => sum + item.macros);
  }

  /// 复制并修改部分字段
  Meal copyWith({
    String? name,
    String? note,
    List<FoodItem>? items,
    bool? completed,
    List<String>? images,
  }) {
    return Meal(
      name: name ?? this.name,
      note: note ?? this.note,
      items: items ?? this.items,
      completed: completed ?? this.completed,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meal &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          note == other.note &&
          items == other.items &&
          completed == other.completed &&
          images == other.images;

  @override
  int get hashCode =>
      name.hashCode ^
      note.hashCode ^
      items.hashCode ^
      completed.hashCode ^
      images.hashCode;

  @override
  String toString() {
    return 'Meal(name: $name, items: ${items.length}, macros: $macros)';
  }
}
