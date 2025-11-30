/// 计划导入统计数据
///
/// 适用于所有导入方式：AI 生成、文本导入、参数生成等
class PlanImportStats {
  /// 总训练天数
  final int totalDays;

  /// 总动作数
  final int totalExercises;

  /// 复用的动作数（从动作库中匹配）
  final int reusedExercises;

  /// 新建的动作数（需要创建模板）
  final int newExercises;

  /// 复用的动作名称列表
  final List<String> reusedExerciseNames;

  /// 需要新建的动作名称列表
  final List<String> newExerciseNames;

  /// 总组数
  final int totalSets;

  const PlanImportStats({
    this.totalDays = 0,
    this.totalExercises = 0,
    this.reusedExercises = 0,
    this.newExercises = 0,
    this.reusedExerciseNames = const [],
    this.newExerciseNames = const [],
    this.totalSets = 0,
  });

  PlanImportStats copyWith({
    int? totalDays,
    int? totalExercises,
    int? reusedExercises,
    int? newExercises,
    List<String>? reusedExerciseNames,
    List<String>? newExerciseNames,
    int? totalSets,
  }) {
    return PlanImportStats(
      totalDays: totalDays ?? this.totalDays,
      totalExercises: totalExercises ?? this.totalExercises,
      reusedExercises: reusedExercises ?? this.reusedExercises,
      newExercises: newExercises ?? this.newExercises,
      reusedExerciseNames: reusedExerciseNames ?? this.reusedExerciseNames,
      newExerciseNames: newExerciseNames ?? this.newExerciseNames,
      totalSets: totalSets ?? this.totalSets,
    );
  }

  @override
  String toString() => 'PlanImportStats('
      'days: $totalDays, '
      'exercises: $totalExercises, '
      'reused: $reusedExercises, '
      'new: $newExercises)';
}
