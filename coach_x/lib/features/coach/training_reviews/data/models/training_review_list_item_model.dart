import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';

/// 训练审核列表项模型
///
/// 组合 DailyTrainingModel 和学生信息，用于列表显示
class TrainingReviewListItemModel {
  final String dailyTrainingId;
  final String studentId;
  final String studentName;
  final String? studentAvatarUrl;
  final String date; // 格式: "yyyy-MM-dd"
  final bool isReviewed;
  final DateTime createdAt; // 用于排序
  final String? planName; // 训练计划名称
  final String? dietPlanName; // 饮食计划名称
  final List<StudentExerciseModel>? exercises; // 运动列表
  final int mealCount; // 餐食数量

  const TrainingReviewListItemModel({
    required this.dailyTrainingId,
    required this.studentId,
    required this.studentName,
    this.studentAvatarUrl,
    required this.date,
    required this.isReviewed,
    required this.createdAt,
    this.planName,
    this.dietPlanName,
    this.exercises,
    this.mealCount = 0,
  });

  /// 从JSON创建
  factory TrainingReviewListItemModel.fromJson(Map<String, dynamic> json) {
    final exercisesData = safeMapListCast(json['exercises'], 'exercises');

    return TrainingReviewListItemModel(
      dailyTrainingId: json['dailyTrainingId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentAvatarUrl: json['studentAvatarUrl'] as String?,
      date: json['date'] as String? ?? '',
      isReviewed: json['isReviewed'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              safeIntCast(json['createdAt'], 0, 'createdAt') ?? 0,
            )
          : DateTime.now(),
      planName: json['planName'] as String?,
      dietPlanName: json['dietPlanName'] as String?,
      exercises: exercisesData.isNotEmpty
          ? exercisesData.map((e) => StudentExerciseModel.fromJson(e)).toList()
          : null,
      mealCount: safeIntCast(json['mealCount'], 0, 'mealCount') ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dailyTrainingId': dailyTrainingId,
      'studentId': studentId,
      'studentName': studentName,
      'studentAvatarUrl': studentAvatarUrl,
      'date': date,
      'isReviewed': isReviewed,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'planName': planName,
      'dietPlanName': dietPlanName,
      'exercises': exercises?.map((e) => e.toJson()).toList(),
      'mealCount': mealCount,
    };
  }

  /// 复制并修改部分字段
  TrainingReviewListItemModel copyWith({
    String? dailyTrainingId,
    String? studentId,
    String? studentName,
    String? studentAvatarUrl,
    String? date,
    bool? isReviewed,
    DateTime? createdAt,
    String? planName,
    String? dietPlanName,
    List<StudentExerciseModel>? exercises,
    int? mealCount,
  }) {
    return TrainingReviewListItemModel(
      dailyTrainingId: dailyTrainingId ?? this.dailyTrainingId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAvatarUrl: studentAvatarUrl ?? this.studentAvatarUrl,
      date: date ?? this.date,
      isReviewed: isReviewed ?? this.isReviewed,
      createdAt: createdAt ?? this.createdAt,
      planName: planName ?? this.planName,
      dietPlanName: dietPlanName ?? this.dietPlanName,
      exercises: exercises ?? this.exercises,
      mealCount: mealCount ?? this.mealCount,
    );
  }

  /// 获取日期的 DateTime 对象
  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingReviewListItemModel &&
          runtimeType == other.runtimeType &&
          dailyTrainingId == other.dailyTrainingId;

  @override
  int get hashCode => dailyTrainingId.hashCode;

  @override
  String toString() {
    return 'TrainingReviewListItemModel(id: $dailyTrainingId, student: $studentName, date: $date, reviewed: $isReviewed)';
  }
}
