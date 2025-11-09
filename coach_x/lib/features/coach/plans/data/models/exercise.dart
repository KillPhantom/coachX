import 'package:coach_x/core/utils/json_utils.dart';
import '../../../../../../core/enums/exercise_type.dart';
import 'training_set.dart';

/// 单个运动动作数据模型
class Exercise {
  final String name;
  final String note;
  final ExerciseType type;
  final List<TrainingSet> sets;
  final bool completed;
  final String? detailGuide; // 预留：详细指导文字
  final List<String> demoVideos; // 预留：演示视频URL列表

  const Exercise({
    required this.name,
    this.note = '',
    this.type = ExerciseType.strength,
    required this.sets,
    this.completed = false,
    this.detailGuide,
    this.demoVideos = const [],
  });

  /// 创建空的 Exercise
  factory Exercise.empty() {
    return Exercise(
      name: '',
      note: '',
      type: ExerciseType.strength,
      sets: [TrainingSet.empty()],
      completed: false,
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
      note: json['note'] as String? ?? '',
      type: exerciseTypeFromString(json['type'] as String? ?? 'strength'),
      sets: sets.isNotEmpty ? sets : [TrainingSet.empty()],
      completed: json['completed'] as bool? ?? false,
      detailGuide: json['detailGuide'] as String?,
      demoVideos:
          (json['demoVideos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'note': note,
      'type': type.toJsonString(),
      'sets': sets.map((set) => set.toJson()).toList(),
      'completed': completed,
      if (detailGuide != null) 'detailGuide': detailGuide,
      'demoVideos': demoVideos,
    };
  }

  /// 复制并修改部分字段
  Exercise copyWith({
    String? name,
    String? note,
    ExerciseType? type,
    List<TrainingSet>? sets,
    bool? completed,
    String? detailGuide,
    List<String>? demoVideos,
  }) {
    return Exercise(
      name: name ?? this.name,
      note: note ?? this.note,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      completed: completed ?? this.completed,
      detailGuide: detailGuide ?? this.detailGuide,
      demoVideos: demoVideos ?? this.demoVideos,
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

  /// 切换完成状态
  Exercise toggleComplete() {
    return copyWith(completed: !completed);
  }

  /// 获取 Sets 总数
  int get totalSets => sets.length;

  /// 是否有效（name 不为空）
  bool get isValid => name.trim().isNotEmpty;

  /// 获取已完成的 Sets 数量
  int get completedSetsCount => sets.where((set) => set.completed).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          note == other.note &&
          type == other.type &&
          completed == other.completed;

  @override
  int get hashCode =>
      name.hashCode ^ note.hashCode ^ type.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'Exercise(name: $name, type: $type, sets: ${sets.length}, completed: $completed)';
  }
}
