import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/core/utils/json_utils.dart';

/// 学生饮食记录模型
///
/// 对应后端 dailyTraining.diet 字段
class StudentDietRecordModel {
  final List<Meal> meals;

  const StudentDietRecordModel({required this.meals});

  /// 计算总营养数据（从所有 meals 累加）
  Macros get macros {
    return meals.fold(Macros.zero(), (sum, meal) => sum + meal.macros);
  }

  /// 创建空记录
  factory StudentDietRecordModel.empty() {
    return const StudentDietRecordModel(meals: []);
  }

  /// 从 JSON 创建
  factory StudentDietRecordModel.fromJson(Map<String, dynamic> json) {
    final mealsData = safeMapListCast(json['meals'], 'meals');

    return StudentDietRecordModel(
      meals: mealsData.map((meal) => Meal.fromJson(meal)).toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'meals': meals.map((meal) => meal.toJson()).toList()};
  }

  /// 复制并修改部分字段
  StudentDietRecordModel copyWith({List<Meal>? meals}) {
    return StudentDietRecordModel(meals: meals ?? this.meals);
  }

  @override
  String toString() {
    return 'StudentDietRecordModel(meals: ${meals.length})';
  }
}
