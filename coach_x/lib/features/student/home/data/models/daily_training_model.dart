import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/diet/data/models/student_diet_record_model.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';
import 'extracted_keyframe_model.dart';

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
  final int? totalDuration; // 训练总时长（秒数），从启动计时器到最后一个 exercise 完成
  final Map<String, ExtractedKeyFrameModel> extractedKeyFrames; // 提取的关键帧数据

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
    this.totalDuration,
    this.extractedKeyFrames = const {},
  });

  /// 从JSON创建
  factory DailyTrainingModel.fromJson(Map<String, dynamic> json) {
    final planSelectionData = safeMapCast(
      json['planSelection'],
      'planSelection',
    );
    final dietData = safeMapCast(json['diet'], 'diet');

    // 解析 exercises - 支持 Map 和 List 两种格式
    List<StudentExerciseModel>? exercises;
    final exercisesRaw = json['exercises'];

    if (exercisesRaw != null) {
      if (exercisesRaw is Map) {
        // Map 格式: {"0": {...}, "1": {...}}
        final exercisesMap = safeMapCast(exercisesRaw, 'exercises');
        if (exercisesMap != null) {
          // 按键排序（"0", "1", "2" ...）
          final sortedKeys = exercisesMap.keys.toList()..sort();
          exercises = sortedKeys
              .map((key) {
                final exerciseData = safeMapCast(
                  exercisesMap[key],
                  'exercise_$key',
                );
                return exerciseData != null
                    ? StudentExerciseModel.fromJson(exerciseData)
                    : null;
              })
              .whereType<StudentExerciseModel>()
              .toList();
        }
      } else if (exercisesRaw is List) {
        // List 格式: [{...}, {...}]
        final exercisesList = safeMapListCast(exercisesRaw, 'exercises');
        exercises = exercisesList.isNotEmpty
            ? exercisesList
                  .map((e) => StudentExerciseModel.fromJson(e))
                  .toList()
            : null;
      }
    }

    // 解析 extractedKeyFrames
    final extractedKeyFramesData = safeMapCast(
      json['extractedKeyFrames'],
      'extractedKeyFrames',
    );
    Map<String, ExtractedKeyFrameModel> extractedKeyFrames = {};

    if (extractedKeyFramesData != null) {
      extractedKeyFramesData.forEach((key, value) {
        final data = safeMapCast(value, 'extractedKeyFrame_$key');
        if (data != null) {
          try {
            extractedKeyFrames[key] = ExtractedKeyFrameModel.fromJson(data);
          } catch (e) {
            AppLogger.error(
              'Failed to parse extractedKeyFrame for key $key: $e',
            );
          }
        }
      });
    }

    return DailyTrainingModel(
      id: json['id'] as String,
      studentId: json['studentID'] as String,
      coachId: json['coachID'] as String,
      date: json['date'] as String,
      planSelection: TrainingDaySelection.fromJson(planSelectionData ?? {}),
      diet: dietData != null ? StudentDietRecordModel.fromJson(dietData) : null,
      exercises: exercises,
      supplements: json['supplements'] as List<dynamic>?,
      completionStatus: json['completionStatus'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
      totalDuration: json['totalDuration'] as int?,
      extractedKeyFrames: extractedKeyFrames,
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
      'totalDuration': totalDuration,
      'extractedKeyFrames': extractedKeyFrames.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
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
      exerciseDayNumber: safeIntCast(
        json['exerciseDayNumber'],
        null,
        'exerciseDayNumber',
      ),
      dietPlanId: json['dietPlanId'] as String?,
      dietDayNumber: safeIntCast(json['dietDayNumber'], null, 'dietDayNumber'),
      supplementPlanId: json['supplementPlanId'] as String?,
      supplementDayNumber: safeIntCast(
        json['supplementDayNumber'],
        null,
        'supplementDayNumber',
      ),
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
