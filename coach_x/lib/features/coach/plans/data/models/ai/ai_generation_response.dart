import '../../../../../../core/enums/ai_status.dart';
import '../exercise_plan_model.dart';
import '../exercise_training_day.dart';
import '../exercise.dart';
import '../training_set.dart';

/// AI 生成响应模型
class AIGenerationResponse {
  final AIGenerationStatus status;
  final ExercisePlanModel? plan; // 完整计划（full模式）
  final List<ExerciseTrainingDay>? days; // 训练日建议
  final List<Exercise>? exercises; // 动作建议
  final List<TrainingSet>? sets; // Set建议
  final String? error;

  const AIGenerationResponse({
    required this.status,
    this.plan,
    this.days,
    this.exercises,
    this.sets,
    this.error,
  });

  /// 从 JSON 创建
  factory AIGenerationResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'error';
    AIGenerationStatus status;
    
    switch (statusStr.toLowerCase()) {
      case 'success':
        status = AIGenerationStatus.success;
        break;
      case 'generating':
        status = AIGenerationStatus.generating;
        break;
      case 'error':
        status = AIGenerationStatus.error;
        break;
      default:
        status = AIGenerationStatus.idle;
    }

    // 解析计划数据
    ExercisePlanModel? plan;
    if (json['plan'] != null) {
      try {
        plan = ExercisePlanModel.fromJson(json['plan'] as Map<String, dynamic>);
      } catch (e) {
        // 解析失败，忽略
      }
    }

    // 解析训练日列表
    List<ExerciseTrainingDay>? days;
    if (json['days'] != null) {
      try {
        final daysJson = json['days'] as List<dynamic>;
        days = daysJson
            .map((dayJson) =>
                ExerciseTrainingDay.fromJson(dayJson as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // 解析失败，忽略
      }
    }

    // 解析动作列表
    List<Exercise>? exercises;
    if (json['exercises'] != null) {
      try {
        final exercisesJson = json['exercises'] as List<dynamic>;
        exercises = exercisesJson
            .map((exerciseJson) =>
                Exercise.fromJson(exerciseJson as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // 解析失败，忽略
      }
    }

    // 解析 Sets 列表
    List<TrainingSet>? sets;
    if (json['sets'] != null) {
      try {
        final setsJson = json['sets'] as List<dynamic>;
        sets = setsJson
            .map((setJson) =>
                TrainingSet.fromJson(setJson as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // 解析失败，忽略
      }
    }

    return AIGenerationResponse(
      status: status,
      plan: plan,
      days: days,
      exercises: exercises,
      sets: sets,
      error: json['error'] as String?,
    );
  }

  /// 是否成功
  bool get isSuccess => status == AIGenerationStatus.success;

  /// 是否有错误
  bool get hasError => status == AIGenerationStatus.error || error != null;

  /// 是否有数据
  bool get hasData =>
      plan != null || days != null || exercises != null || sets != null;

  /// 复制并修改部分字段
  AIGenerationResponse copyWith({
    AIGenerationStatus? status,
    ExercisePlanModel? plan,
    List<ExerciseTrainingDay>? days,
    List<Exercise>? exercises,
    List<TrainingSet>? sets,
    String? error,
  }) {
    return AIGenerationResponse(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      days: days ?? this.days,
      exercises: exercises ?? this.exercises,
      sets: sets ?? this.sets,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AIGenerationResponse(status: $status, hasData: $hasData, error: $error)';
  }
}


