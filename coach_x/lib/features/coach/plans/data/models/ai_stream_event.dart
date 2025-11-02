import 'package:coach_x/features/coach/plans/data/models/exercise_training_day.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';

/// AI 流式生成事件
///
/// 用于接收后端 SSE 流式推送的生成进度
class AIStreamEvent {
  /// 事件类型
  final String type;

  /// 当前天数
  final int? day;

  /// 思考内容或消息
  final String? content;

  /// 完成的训练日数据
  final ExerciseTrainingDay? dayData;

  /// 动作索引
  final int? exerciseIndex;

  /// 动作名称
  final String? exerciseName;

  /// 完成的动作数据
  final Exercise? exerciseData;

  /// 总动作数
  final int? totalExercises;

  /// 错误信息
  final String? error;

  const AIStreamEvent({
    required this.type,
    this.day,
    this.content,
    this.dayData,
    this.exerciseIndex,
    this.exerciseName,
    this.exerciseData,
    this.totalExercises,
    this.error,
  });

  /// 从 JSON 解析
  factory AIStreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'thinking':
        return AIStreamEvent(
          type: type,
          day: json['day'] as int?,
          content: json['content'] as String?,
        );

      case 'day_start':
        return AIStreamEvent(
          type: type,
          day: json['day'] as int,
        );

      case 'exercise_start':
        return AIStreamEvent(
          type: type,
          day: json['day'] as int?,
          exerciseIndex: json['exercise_index'] as int?,
          exerciseName: json['exercise_name'] as String?,
          totalExercises: json['total_exercises'] as int?,
        );

      case 'exercise_complete':
        return AIStreamEvent(
          type: type,
          day: json['day'] as int?,
          exerciseIndex: json['exercise_index'] as int?,
          exerciseData: json['data'] != null
              ? Exercise.fromJson(json['data'] as Map<String, dynamic>)
              : null,
        );

      case 'day_complete':
        return AIStreamEvent(
          type: type,
          day: json['day'] as int,
          dayData: ExerciseTrainingDay.fromJson(
            json['data'] as Map<String, dynamic>,
          ),
        );

      case 'complete':
        return AIStreamEvent(
          type: type,
          content: json['message'] as String?,
        );

      case 'error':
        return AIStreamEvent(
          type: type,
          day: json['day'] as int?,
          error: json['error'] as String?,
        );

      default:
        return AIStreamEvent(
          type: type,
        );
    }
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
    };

    if (day != null) json['day'] = day;
    if (content != null) json['content'] = content;
    if (dayData != null) json['data'] = dayData!.toJson();
    if (exerciseIndex != null) json['exercise_index'] = exerciseIndex;
    if (exerciseName != null) json['exercise_name'] = exerciseName;
    if (exerciseData != null) json['data'] = exerciseData!.toJson();
    if (totalExercises != null) json['total_exercises'] = totalExercises;
    if (error != null) json['error'] = error;

    return json;
  }

  /// 是否为思考事件
  bool get isThinking => type == 'thinking';

  /// 是否为开始生成某天
  bool get isDayStart => type == 'day_start';

  /// 是否为动作开始事件
  bool get isExerciseStart => type == 'exercise_start';

  /// 是否为动作完成事件
  bool get isExerciseComplete => type == 'exercise_complete';

  /// 是否为某天完成
  bool get isDayComplete => type == 'day_complete';

  /// 是否为全部完成
  bool get isComplete => type == 'complete';

  /// 是否为错误
  bool get isError => type == 'error';

  @override
  String toString() {
    return 'AIStreamEvent(type: $type, day: $day, exerciseIndex: $exerciseIndex, exerciseName: $exerciseName, content: $content, error: $error)';
  }
}

