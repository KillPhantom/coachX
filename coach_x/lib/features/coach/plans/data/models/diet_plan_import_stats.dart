/// 饮食计划导入统计数据
///
/// 用于 AI 生成、文本导入等场景的统计展示
class DietPlanImportStats {
  /// 饮食天数
  final int totalDays;

  /// 总餐次
  final int totalMeals;

  /// 基础代谢率 (kcal/day)
  final double bmr;

  /// 总能量消耗 (kcal/day)
  final double tdee;

  /// 目标热量 (kcal/day)
  final double targetCalories;

  const DietPlanImportStats({
    this.totalDays = 0,
    this.totalMeals = 0,
    this.bmr = 0.0,
    this.tdee = 0.0,
    this.targetCalories = 0.0,
  });

  DietPlanImportStats copyWith({
    int? totalDays,
    int? totalMeals,
    double? bmr,
    double? tdee,
    double? targetCalories,
  }) {
    return DietPlanImportStats(
      totalDays: totalDays ?? this.totalDays,
      totalMeals: totalMeals ?? this.totalMeals,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      targetCalories: targetCalories ?? this.targetCalories,
    );
  }

  @override
  String toString() => 'DietPlanImportStats('
      'days: $totalDays, '
      'meals: $totalMeals, '
      'bmr: ${bmr.toInt()}, '
      'tdee: ${tdee.toInt()}, '
      'target: ${targetCalories.toInt()})';
}
