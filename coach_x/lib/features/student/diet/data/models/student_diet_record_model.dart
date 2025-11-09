import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/core/utils/json_utils.dart';

/// 学生饮食记录模型
///
/// 对应后端 dailyTraining.diet 字段
class StudentDietRecordModel {
  final Macros? macros;
  final List<Meal> meals;
  final String studentFeedback;
  final String coachFeedback;

  const StudentDietRecordModel({
    this.macros,
    required this.meals,
    this.studentFeedback = '',
    this.coachFeedback = '',
  });

  /// 创建空记录
  factory StudentDietRecordModel.empty() {
    return const StudentDietRecordModel(
      macros: null,
      meals: [],
      studentFeedback: '',
      coachFeedback: '',
    );
  }

  /// 从 JSON 创建
  factory StudentDietRecordModel.fromJson(Map<String, dynamic> json) {
    final macrosData = safeMapCast(json['macros'], 'macros');
    final mealsData = safeMapListCast(json['meals'], 'meals');

    return StudentDietRecordModel(
      macros: macrosData != null ? Macros.fromJson(macrosData) : null,
      meals: mealsData.map((meal) => Meal.fromJson(meal)).toList(),
      studentFeedback: json['studentFeedback'] as String? ?? '',
      coachFeedback: json['coachFeedback'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'macros': macros?.toJson(),
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'studentFeedback': studentFeedback,
      'coachFeedback': coachFeedback,
    };
  }

  /// 复制并修改部分字段
  StudentDietRecordModel copyWith({
    Macros? macros,
    List<Meal>? meals,
    String? studentFeedback,
    String? coachFeedback,
  }) {
    return StudentDietRecordModel(
      macros: macros ?? this.macros,
      meals: meals ?? this.meals,
      studentFeedback: studentFeedback ?? this.studentFeedback,
      coachFeedback: coachFeedback ?? this.coachFeedback,
    );
  }

  @override
  String toString() {
    return 'StudentDietRecordModel(meals: ${meals.length}, feedback: $studentFeedback)';
  }
}
