import 'supplement_timing.dart';

/// 补剂日模型
class SupplementDay {
  final int day;
  final String name;
  final List<SupplementTiming> timings;
  final bool completed;

  const SupplementDay({
    required this.day,
    required this.name,
    required this.timings,
    this.completed = false,
  });

  /// 创建空的补剂日
  factory SupplementDay.empty({int day = 1}) {
    return SupplementDay(
      day: day,
      name: 'Day $day',
      timings: const [],
      completed: false,
    );
  }

  /// 从 JSON 创建
  factory SupplementDay.fromJson(Map<String, dynamic> json) {
    final timingsJson = json['timings'] as List<dynamic>? ?? [];
    final timings = timingsJson
        .map(
          (timing) => SupplementTiming.fromJson(
            Map<String, dynamic>.from(timing as Map),
          ),
        )
        .toList();

    return SupplementDay(
      day: json['day'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      timings: timings,
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'name': name,
      'timings': timings.map((timing) => timing.toJson()).toList(),
      'completed': completed,
    };
  }

  /// 复制并修改部分字段
  SupplementDay copyWith({
    int? day,
    String? name,
    List<SupplementTiming>? timings,
    bool? completed,
  }) {
    return SupplementDay(
      day: day ?? this.day,
      name: name ?? this.name,
      timings: timings ?? this.timings,
      completed: completed ?? this.completed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplementDay &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          name == other.name &&
          timings == other.timings &&
          completed == other.completed;

  @override
  int get hashCode =>
      day.hashCode ^ name.hashCode ^ timings.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'SupplementDay(day: $day, name: $name, timings: ${timings.length})';
  }
}
