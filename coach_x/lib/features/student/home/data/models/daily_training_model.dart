import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/student/diet/data/models/student_diet_record_model.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';

/// 每日训练记录模型
class DailyTrainingModel {
  final String id;
  final String studentId;
  final String coachId;
  final String date; // 格式: "yyyy-MM-dd"
  final TrainingDaySelection planSelection;
  final StudentDietRecordModel? diet;
  final List<StudentExerciseModel>? exercises;
  final List<dynamic>? supplements; // TODO: 后续实现 StudentSupplement 模型
  final String? completionStatus;
  final bool isReviewed;

  const DailyTrainingModel({
    required this.id,
    required this.studentId,
    required this.coachId,
    required this.date,
    required this.planSelection,
    this.diet,
    this.exercises,
    this.supplements,
    this.completionStatus,
    this.isReviewed = false,
  });

  /// 从JSON创建
  factory DailyTrainingModel.fromJson(Map<String, dynamic> json) {
    final planSelectionData = safeMapCast(
      json['planSelection'],
      'planSelection',
    );
    final dietData = safeMapCast(json['diet'], 'diet');
    final exercisesData = safeMapListCast(json['exercises'], 'exercises');

    return DailyTrainingModel(
      id: json['id'] as String,
      studentId: json['studentID'] as String,
      coachId: json['coachID'] as String,
      date: json['date'] as String,
      planSelection: TrainingDaySelection.fromJson(planSelectionData ?? {}),
      diet: dietData != null ? StudentDietRecordModel.fromJson(dietData) : null,
      exercises: exercisesData.isNotEmpty
          ? exercisesData.map((e) => StudentExerciseModel.fromJson(e)).toList()
          : null,
      supplements: json['supplements'] as List<dynamic>?,
      completionStatus: json['completionStatus'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentID': studentId,
      'coachID': coachId,
      'date': date,
      'planSelection': planSelection.toJson(),
      'diet': diet?.toJson(),
      'exercises': exercises?.map((e) => e.toJson()).toList(),
      'supplements': supplements,
      'completionStatus': completionStatus,
      'isReviewed': isReviewed,
    };
  }

  @override
  String toString() {
    return 'DailyTrainingModel(id: $id, date: $date, planSelection: $planSelection)';
  }
}

/// 训练日选择模型
///
/// 记录当天执行的是哪个计划的第几天
class TrainingDaySelection {
  final String? exercisePlanId;
  final int? exerciseDayNumber;
  final String? dietPlanId;
  final int? dietDayNumber;
  final String? supplementPlanId;
  final int? supplementDayNumber;

  const TrainingDaySelection({
    this.exercisePlanId,
    this.exerciseDayNumber,
    this.dietPlanId,
    this.dietDayNumber,
    this.supplementPlanId,
    this.supplementDayNumber,
  });

  /// 从JSON创建
  factory TrainingDaySelection.fromJson(Map<String, dynamic> json) {
    return TrainingDaySelection(
      exercisePlanId: json['exercisePlanId'] as String?,
      exerciseDayNumber: json['exerciseDayNumber'] as int?,
      dietPlanId: json['dietPlanId'] as String?,
      dietDayNumber: json['dietDayNumber'] as int?,
      supplementPlanId: json['supplementPlanId'] as String?,
      supplementDayNumber: json['supplementDayNumber'] as int?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'exercisePlanId': exercisePlanId,
      'exerciseDayNumber': exerciseDayNumber,
      'dietPlanId': dietPlanId,
      'dietDayNumber': dietDayNumber,
      'supplementPlanId': supplementPlanId,
      'supplementDayNumber': supplementDayNumber,
    };
  }

  @override
  String toString() {
    return 'TrainingDaySelection(exercise: Day $exerciseDayNumber, diet: Day $dietDayNumber, supplement: Day $supplementDayNumber)';
  }
}
