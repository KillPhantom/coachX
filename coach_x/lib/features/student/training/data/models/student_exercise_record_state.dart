import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';

/// 训练记录页面状态
class ExerciseRecordState {
  final List<StudentExerciseModel> exercises;
  final bool isLoading;
  final String? error;
  final String currentDate;
  final String? exercisePlanId;
  final int? exerciseDayNumber;
  final String? coachId;
  final bool isSaving;
  final DateTime? timerStartTime; // 全局计时器开始时间
  final bool isTimerRunning; // 是否正在计时
  final Map<int, DateTime> exerciseStartTimes; // 每个 exercise 的开始时间
  final DateTime? currentExerciseStartTime; // 当前 Exercise 的开始时间
  final int? currentExerciseIndex; // 当前正在计时的 Exercise 索引

  const ExerciseRecordState({
    this.exercises = const [],
    this.isLoading = false,
    this.error,
    required this.currentDate,
    this.exercisePlanId,
    this.exerciseDayNumber,
    this.coachId,
    this.isSaving = false,
    this.timerStartTime,
    this.isTimerRunning = false,
    this.exerciseStartTimes = const {},
    this.currentExerciseStartTime,
    this.currentExerciseIndex,
  });

  /// 创建初始状态
  factory ExerciseRecordState.initial(String date) {
    return ExerciseRecordState(currentDate: date);
  }

  /// 复制并修改部分字段
  ExerciseRecordState copyWith({
    List<StudentExerciseModel>? exercises,
    bool? isLoading,
    String? error,
    String? currentDate,
    String? exercisePlanId,
    int? exerciseDayNumber,
    String? coachId,
    bool? isSaving,
    DateTime? timerStartTime,
    bool? isTimerRunning,
    Map<int, DateTime>? exerciseStartTimes,
    DateTime? currentExerciseStartTime,
    int? currentExerciseIndex,
    bool clearError = false,
  }) {
    return ExerciseRecordState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentDate: currentDate ?? this.currentDate,
      exercisePlanId: exercisePlanId ?? this.exercisePlanId,
      exerciseDayNumber: exerciseDayNumber ?? this.exerciseDayNumber,
      coachId: coachId ?? this.coachId,
      isSaving: isSaving ?? this.isSaving,
      timerStartTime: timerStartTime ?? this.timerStartTime,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      exerciseStartTimes: exerciseStartTimes ?? this.exerciseStartTimes,
      currentExerciseStartTime: currentExerciseStartTime ?? this.currentExerciseStartTime,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
    );
  }

  /// 是否有任何动作
  bool get hasExercises => exercises.isNotEmpty;

  /// 是否有已完成的动作
  bool get hasCompletedExercises =>
      exercises.any((exercise) => exercise.completed);

  /// 获取计时器经过时间
  Duration get elapsedTime {
    if (timerStartTime == null) return Duration.zero;
    return DateTime.now().difference(timerStartTime!);
  }

  /// 获取当前 Exercise 经过的时间
  Duration? get currentExerciseElapsed {
    if (currentExerciseStartTime == null) return null;
    return DateTime.now().difference(currentExerciseStartTime!);
  }

  @override
  String toString() {
    return 'ExerciseRecordState(exercises: ${exercises.length}, isLoading: $isLoading, error: $error, date: $currentDate, isTimerRunning: $isTimerRunning)';
  }
}
