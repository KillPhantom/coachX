import 'package:coach_x/core/utils/json_utils.dart';
import '../../../../../../core/enums/exercise_type.dart';
import 'training_set.dart';

/// 单个运动动作数据模型
class Exercise {
  final String name;
  final ExerciseType type;
  final List<TrainingSet> sets;
  final String? exerciseTemplateId; // 关联的动作模板 ID

  const Exercise({
    required this.name,
    this.type = ExerciseType.strength,
    required this.sets,
    this.exerciseTemplateId,
  });

  /// 创建空的 Exercise
  factory Exercise.empty() {
    return Exercise(
      name: '',
      type: ExerciseType.strength,
      sets: [TrainingSet.empty()],
    );
  }

  /// 从 JSON 创建
  factory Exercise.fromJson(Map<String, dynamic> json) {
    final setsData = safeMapListCast(json['sets'], 'sets');
    final sets = setsData
        .map((setJson) => TrainingSet.fromJson(setJson))
        .toList();

    return Exercise(
      name: json['name'] as String? ?? '',
      type: exerciseTypeFromString(json['type'] as String? ?? 'strength'),
      sets: sets.isNotEmpty ? sets : [TrainingSet.empty()],
      exerciseTemplateId: json['exerciseTemplateId'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toJsonString(),
      'sets': sets.map((set) => set.toJson()).toList(),
      if (exerciseTemplateId != null) 'exerciseTemplateId': exerciseTemplateId,
    };
  }

  /// 复制并修改部分字段
  Exercise copyWith({
    String? name,
    ExerciseType? type,
    List<TrainingSet>? sets,
    String? exerciseTemplateId,
  }) {
    return Exercise(
      name: name ?? this.name,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
    );
  }

  /// 添加 Set
  Exercise addSet(TrainingSet set) {
    return copyWith(sets: [...sets, set]);
  }

  /// 删除 Set
  Exercise removeSet(int index) {
    if (index < 0 || index >= sets.length) return this;
    final newSets = List<TrainingSet>.from(sets);
    newSets.removeAt(index);
    // 至少保留一个 Set
    return copyWith(sets: newSets.isEmpty ? [TrainingSet.empty()] : newSets);
  }

  /// 更新 Set
  Exercise updateSet(int index, TrainingSet set) {
    if (index < 0 || index >= sets.length) return this;
    final newSets = List<TrainingSet>.from(sets);
    newSets[index] = set;
    return copyWith(sets: newSets);
  }

  /// 获取 Sets 总数
  int get totalSets => sets.length;

  /// 是否有效（name 不为空）
  bool get isValid => name.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'Exercise(name: $name, type: $type, sets: ${sets.length})';
  }
}
