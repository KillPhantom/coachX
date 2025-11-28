/// AI 流式生成统计数据
class AIStreamingStats {
  /// 总训练天数
  final int totalDays;

  /// 总动作数
  final int totalExercises;

  /// 复用的动作数（从动作库中匹配）
  final int reusedExercises;

  /// 新建的动作数（需要创建模板）
  final int newExercises;

  /// 需要新建的动作名称列表
  final List<String> newExerciseNames;

  /// 总组数
  final int totalSets;

  const AIStreamingStats({
    this.totalDays = 0,
    this.totalExercises = 0,
    this.reusedExercises = 0,
    this.newExercises = 0,
    this.newExerciseNames = const [],
    this.totalSets = 0,
  });

  AIStreamingStats copyWith({
    int? totalDays,
    int? totalExercises,
    int? reusedExercises,
    int? newExercises,
    List<String>? newExerciseNames,
    int? totalSets,
  }) {
    return AIStreamingStats(
      totalDays: totalDays ?? this.totalDays,
      totalExercises: totalExercises ?? this.totalExercises,
      reusedExercises: reusedExercises ?? this.reusedExercises,
      newExercises: newExercises ?? this.newExercises,
      newExerciseNames: newExerciseNames ?? this.newExerciseNames,
      totalSets: totalSets ?? this.totalSets,
    );
  }

  @override
  String toString() => 'AIStreamingStats('
      'days: $totalDays, '
      'exercises: $totalExercises, '
      'reused: $reusedExercises, '
      'new: $newExercises)';
}
