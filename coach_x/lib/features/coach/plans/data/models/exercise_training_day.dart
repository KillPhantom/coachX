import 'package:coach_x/core/utils/json_utils.dart';
import 'exercise.dart';

/// 训练日数据模型
class ExerciseTrainingDay {
  final int day;
  final String name; // 训练日名称
  final String note; // 备注（可选）
  final List<Exercise> exercises;
  final bool completed;

  const ExerciseTrainingDay({
    required this.day,
    required this.name,
    this.note = '',
    required this.exercises,
    this.completed = false,
  });

  /// 创建空的训练日
  factory ExerciseTrainingDay.empty(int day) {
    return ExerciseTrainingDay(
      day: day,
      name: 'Day $day',
      note: '',
      exercises: [], // 空的动作列表，动作将通过流式生成逐个添加
      completed: false,
    );
  }

  /// 从 JSON 创建
  factory ExerciseTrainingDay.fromJson(Map<String, dynamic> json) {
    final exercisesData = safeMapListCast(json['exercises'], 'exercises');
    final exercises = exercisesData
        .map((exerciseJson) => Exercise.fromJson(exerciseJson))
        .toList();

    return ExerciseTrainingDay(
      day: json['day'] as int? ?? 1,
      name: json['name'] as String? ?? 'Day ${json['day'] ?? 1}',
      note: json['note'] as String? ?? '',
      exercises: exercises.isNotEmpty ? exercises : [Exercise.empty()],
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'name': name,
      'note': note,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'completed': completed,
    };
  }

  /// 复制并修改部分字段
  ExerciseTrainingDay copyWith({
    int? day,
    String? name,
    String? note,
    List<Exercise>? exercises,
    bool? completed,
  }) {
    return ExerciseTrainingDay(
      day: day ?? this.day,
      name: name ?? this.name,
      note: note ?? this.note,
      exercises: exercises ?? this.exercises,
      completed: completed ?? this.completed,
    );
  }

  /// 添加 Exercise
  ExerciseTrainingDay addExercise(Exercise exercise) {
    return copyWith(exercises: [...exercises, exercise]);
  }

  /// 删除 Exercise
  ExerciseTrainingDay removeExercise(int index) {
    if (index < 0 || index >= exercises.length) return this;
    final newExercises = List<Exercise>.from(exercises);
    newExercises.removeAt(index);
    // 至少保留一个 Exercise
    return copyWith(
      exercises: newExercises.isEmpty ? [Exercise.empty()] : newExercises,
    );
  }

  /// 更新 Exercise
  ExerciseTrainingDay updateExercise(int index, Exercise exercise) {
    if (index < 0 || index >= exercises.length) return this;
    final newExercises = List<Exercise>.from(exercises);
    newExercises[index] = exercise;
    return copyWith(exercises: newExercises);
  }

  /// 切换完成状态
  ExerciseTrainingDay toggleComplete() {
    return copyWith(completed: !completed);
  }

  /// 获取 Exercises 总数
  int get totalExercises => exercises.length;

  /// 获取已完成的 Exercises 数量
  int get completedExercisesCount =>
      exercises.where((exercise) => exercise.completed).length;

  /// 是否有效（至少有一个有效的 Exercise）
  bool get isValid =>
      exercises.isNotEmpty && exercises.any((exercise) => exercise.isValid);

  /// 获取所有 Sets 总数
  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTrainingDay &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          name == other.name &&
          note == other.note &&
          completed == other.completed;

  @override
  int get hashCode =>
      day.hashCode ^ name.hashCode ^ note.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'ExerciseTrainingDay(day: $day, name: $name, note: $note, exercises: ${exercises.length}, completed: $completed)';
  }
}
