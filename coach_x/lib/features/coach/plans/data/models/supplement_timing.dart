import 'supplement.dart';

/// 补剂时间段模型（类似于 Meal）
class SupplementTiming {
  final String name;
  final String note;
  final List<Supplement> supplements;
  final bool completed;

  const SupplementTiming({
    required this.name,
    this.note = '',
    required this.supplements,
    this.completed = false,
  });

  /// 创建空的时间段
  factory SupplementTiming.empty({String? name}) {
    return SupplementTiming(
      name: name ?? '',
      note: '',
      supplements: const [],
      completed: false,
    );
  }

  /// 从 JSON 创建
  factory SupplementTiming.fromJson(Map<String, dynamic> json) {
    final supplementsJson = json['supplements'] as List<dynamic>? ?? [];
    final supplements = supplementsJson
        .map(
          (supplement) =>
              Supplement.fromJson(Map<String, dynamic>.from(supplement as Map)),
        )
        .toList();

    return SupplementTiming(
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      supplements: supplements,
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'note': note,
      'supplements': supplements
          .map((supplement) => supplement.toJson())
          .toList(),
      'completed': completed,
    };
  }

  /// 复制并修改部分字段
  SupplementTiming copyWith({
    String? name,
    String? note,
    List<Supplement>? supplements,
    bool? completed,
  }) {
    return SupplementTiming(
      name: name ?? this.name,
      note: note ?? this.note,
      supplements: supplements ?? this.supplements,
      completed: completed ?? this.completed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplementTiming &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          note == other.note &&
          supplements == other.supplements &&
          completed == other.completed;

  @override
  int get hashCode =>
      name.hashCode ^ note.hashCode ^ supplements.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'SupplementTiming(name: $name, supplements: ${supplements.length})';
  }
}
