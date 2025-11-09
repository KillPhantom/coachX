/// 训练组（Set）数据模型
class TrainingSet {
  final String reps;
  final String weight;
  final bool completed;

  const TrainingSet({
    required this.reps,
    required this.weight,
    this.completed = false,
  });

  /// 创建空的 Set
  factory TrainingSet.empty() {
    return const TrainingSet(reps: '', weight: '', completed: false);
  }

  /// 从 JSON 创建
  factory TrainingSet.fromJson(Map<String, dynamic> json) {
    return TrainingSet(
      reps: json['reps'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'reps': reps, 'weight': weight, 'completed': completed};
  }

  /// 复制并修改部分字段
  TrainingSet copyWith({String? reps, String? weight, bool? completed}) {
    return TrainingSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
    );
  }

  /// 是否为空（reps 和 weight 都为空）
  bool get isEmpty => reps.isEmpty && weight.isEmpty;

  /// 是否有效（至少有 reps）
  bool get isValid => reps.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSet &&
          runtimeType == other.runtimeType &&
          reps == other.reps &&
          weight == other.weight &&
          completed == other.completed;

  @override
  int get hashCode => reps.hashCode ^ weight.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'TrainingSet(reps: $reps, weight: $weight, completed: $completed)';
  }
}
