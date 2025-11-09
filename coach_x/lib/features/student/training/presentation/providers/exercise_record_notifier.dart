import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_record_state.dart';
import 'package:coach_x/features/student/training/data/repositories/training_record_repository.dart';

/// 训练记录 Notifier
class ExerciseRecordNotifier extends StateNotifier<ExerciseRecordState> {
  final TrainingRecordRepository _repository;
  Timer? _debounceTimer;

  ExerciseRecordNotifier(this._repository, String initialDate)
      : super(ExerciseRecordState.initial(initialDate));

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 加载今日训练
  ///
  /// [exercisePlanDay] - 计划中的训练日数据（用于预填充）
  Future<void> loadExercisesForToday({
    required String coachId,
    String? exercisePlanId,
    int? exerciseDayNumber,
    List<Exercise>? exercisePlanDay,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // 尝试从服务器获取已保存的记录
      final training = await _repository.fetchTodayTraining(state.currentDate);

      if (training != null && training.exercises != null && training.exercises!.isNotEmpty) {
        // 有已保存的记录，加载它
        AppLogger.info('加载已保存的训练记录');
        state = state.copyWith(
          exercises: training.exercises!,
          isLoading: false,
          coachId: training.coachId,
          exercisePlanId: training.planSelection.exercisePlanId,
          exerciseDayNumber: training.planSelection.exerciseDayNumber,
        );
      } else if (exercisePlanDay != null && exercisePlanDay.isNotEmpty) {
        // 没有记录，从计划预填充
        AppLogger.info('从计划预填充训练记录');
        final studentExercises = exercisePlanDay.map((planExercise) {
          return StudentExerciseModel(
            name: planExercise.name,
            note: planExercise.note,
            type: planExercise.type,
            sets: planExercise.sets,
            completed: false,
            videos: const [],
            voiceFeedbacks: const [],
          );
        }).toList();

        state = state.copyWith(
          exercises: studentExercises,
          isLoading: false,
          coachId: coachId,
          exercisePlanId: exercisePlanId,
          exerciseDayNumber: exerciseDayNumber,
        );
      } else {
        // 既没有记录也没有计划，显示空列表
        AppLogger.info('无训练记录且无计划数据');
        state = state.copyWith(
          isLoading: false,
          coachId: coachId,
          exercisePlanId: exercisePlanId,
          exerciseDayNumber: exerciseDayNumber,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('加载训练记录失败', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 更新某个 exercise
  void updateExercise(int index, StudentExerciseModel exercise) {
    if (index < 0 || index >= state.exercises.length) return;

    final newExercises = List<StudentExerciseModel>.from(state.exercises);
    newExercises[index] = exercise;
    state = state.copyWith(exercises: newExercises);
  }

  /// 添加自定义 exercise
  void addCustomExercise(StudentExerciseModel exercise) {
    state = state.copyWith(
      exercises: [...state.exercises, exercise],
    );
  }

  /// 删除 exercise
  void removeExercise(int index) {
    if (index < 0 || index >= state.exercises.length) return;

    final newExercises = List<StudentExerciseModel>.from(state.exercises);
    newExercises.removeAt(index);
    state = state.copyWith(exercises: newExercises);
  }

  /// 快捷完成某个 exercise（标记为完成并保存）
  Future<void> quickComplete(int index) async {
    if (index < 0 || index >= state.exercises.length) return;

    try {
      final exercise = state.exercises[index];

      // 计算耗时
      final timeSpent = _calculateExerciseTimeSpent(index);

      // 将所有 Sets 标记为完成，并填充 placeholder 数据
      final completedSets = exercise.sets.map((set) {
        return set.copyWith(completed: true);
      }).toList();

      // 标记为完成
      final completedExercise = exercise.copyWith(
        completed: true,
        sets: completedSets,
        timeSpent: timeSpent,
      );
      updateExercise(index, completedExercise);

      // 立即保存
      await saveRecord();

      AppLogger.info('快捷完成成功: ${exercise.name}, 耗时: $timeSpent 秒');

      // 重置计时器到下一个未完成的 exercise
      _resetTimerToNextIncomplete(index);
    } catch (e, stackTrace) {
      AppLogger.error('快捷完成失败', e, stackTrace);
      state = state.copyWith(error: '快捷完成失败: ${e.toString()}');
    }
  }

  /// 保存训练记录
  Future<void> saveRecord() async {
    try {
      state = state.copyWith(isSaving: true, clearError: true);

      if (state.coachId == null) {
        throw Exception('缺少教练ID');
      }

      // 获取当前用户ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      // 构建 DailyTrainingModel
      final training = DailyTrainingModel(
        id: '', // 后端会生成或查找已存在的ID
        studentId: currentUser.uid, // 使用当前用户的 uid
        coachId: state.coachId!,
        date: state.currentDate,
        planSelection: TrainingDaySelection(
          exercisePlanId: state.exercisePlanId,
          exerciseDayNumber: state.exerciseDayNumber,
        ),
        exercises: state.exercises,
        completionStatus: state.hasCompletedExercises ? 'completed' : 'in_progress',
        isReviewed: false,
      );

      await _repository.upsertTodayTraining(training);

      state = state.copyWith(isSaving: false);

      AppLogger.info('保存训练记录成功');
    } catch (e, stackTrace) {
      AppLogger.error('保存训练记录失败', e, stackTrace);
      state = state.copyWith(
        isSaving: false,
        error: '保存失败: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 上传视频
  Future<void> uploadVideo(int exerciseIndex, File videoFile) async {
    try {
      if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

      AppLogger.info('开始上传视频');

      // 构建存储路径
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'students/trainings/${state.currentDate}/$exerciseIndex/$timestamp.mp4';

      // 上传
      final downloadUrl = await _repository.uploadVideo(videoFile, path);

      // 更新 exercise
      final exercise = state.exercises[exerciseIndex];
      final updatedExercise = exercise.addVideo(downloadUrl);
      updateExercise(exerciseIndex, updatedExercise);

      // 自动保存
      await saveRecord();

      AppLogger.info('视频上传成功');
    } catch (e, stackTrace) {
      AppLogger.error('视频上传失败', e, stackTrace);
      state = state.copyWith(error: '视频上传失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 删除视频
  Future<void> deleteVideo(int exerciseIndex, int videoIndex) async {
    try {
      if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

      final exercise = state.exercises[exerciseIndex];
      if (videoIndex < 0 || videoIndex >= exercise.videos.length) return;

      AppLogger.info('删除视频: exercise=$exerciseIndex, video=$videoIndex');

      // 更新 exercise（移除视频）
      final updatedExercise = exercise.removeVideo(videoIndex);
      updateExercise(exerciseIndex, updatedExercise);

      // 自动保存
      await saveRecord();

      AppLogger.info('视频删除成功');
    } catch (e, stackTrace) {
      AppLogger.error('视频删除失败', e, stackTrace);
      state = state.copyWith(error: '视频删除失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 实时更新 Set（不触发保存）
  void updateSetRealtime(int exerciseIndex, int setIndex, TrainingSet set) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    // 记录 exercise 开始时间（如果是第一次编辑且计时器在运行）
    if (state.isTimerRunning && !state.exerciseStartTimes.containsKey(exerciseIndex)) {
      _recordExerciseStartTime(exerciseIndex);
    }

    // 自动标记 Set 完成（如果 reps 不为空）
    final autoCompletedSet = set.reps.isNotEmpty ? set.copyWith(completed: true) : set;

    // 更新本地状态
    final updatedExercise = exercise.updateSet(setIndex, autoCompletedSet);
    updateExercise(exerciseIndex, updatedExercise);

    // 检查该 exercise 的所有 Sets 是否都已完成（如果完成会自动保存）
    _checkAndCompleteExercise(exerciseIndex);
  }

  /// 切换 Set 完成状态
  void toggleSetCompleted(int exerciseIndex, int setIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    final set = exercise.sets[setIndex];

    // 如果 Set 从完成变为未完成，且 Exercise 已完成，需要取消 Exercise 完成状态
    if (set.completed && exercise.completed) {
      final uncompletedExercise = exercise.copyWith(completed: false);
      updateExercise(exerciseIndex, uncompletedExercise);
      AppLogger.info('Exercise $exerciseIndex 取消完成状态（重新编辑 Set）');
    }

    // 切换 Set 完成状态
    final updatedSet = set.copyWith(completed: !set.completed);
    final updatedExercise = exercise.updateSet(setIndex, updatedSet);
    updateExercise(exerciseIndex, updatedExercise);

    AppLogger.info('切换 Set 完成状态: exercise=$exerciseIndex, set=$setIndex, completed=${updatedSet.completed}');
  }

  // ========== 计时器相关方法 ==========

  /// 启动全局计时器
  void startTimer() {
    state = state.copyWith(
      timerStartTime: DateTime.now(),
      isTimerRunning: true,
    );
    AppLogger.info('计时器已启动');
  }

  /// 停止计时器
  void stopTimer() {
    state = state.copyWith(
      timerStartTime: null,
      isTimerRunning: false,
    );
    AppLogger.info('计时器已停止');
  }

  /// 启动某个 Exercise 的计时器
  void startExerciseTimer(int index) {
    if (index < 0 || index >= state.exercises.length) return;

    state = state.copyWith(
      currentExerciseStartTime: DateTime.now(),
      currentExerciseIndex: index,
    );
    AppLogger.info('Exercise $index 计时器已启动');
  }

  /// 重置并启动新 Exercise 的计时器
  void resetExerciseTimer(int newIndex) {
    if (newIndex < 0 || newIndex >= state.exercises.length) return;

    // 只有在全局计时器运行时才启动 Exercise 计时器
    if (!state.isTimerRunning) return;

    state = state.copyWith(
      currentExerciseStartTime: DateTime.now(),
      currentExerciseIndex: newIndex,
    );
    AppLogger.info('Exercise $newIndex 计时器已重置并启动');
  }

  /// 记录某个 exercise 的开始时间
  void _recordExerciseStartTime(int index) {
    final updatedTimes = Map<int, DateTime>.from(state.exerciseStartTimes);
    updatedTimes[index] = DateTime.now();
    state = state.copyWith(exerciseStartTimes: updatedTimes);
    AppLogger.info('记录 exercise $index 开始时间');
  }

  /// 计算并返回某个 exercise 的耗时（秒数）
  int? _calculateExerciseTimeSpent(int index) {
    // 优先使用 currentExerciseStartTime（如果这是当前 exercise）
    if (state.currentExerciseIndex == index && state.currentExerciseStartTime != null) {
      final duration = DateTime.now().difference(state.currentExerciseStartTime!);
      return duration.inSeconds;
    }

    // 否则使用 exerciseStartTimes
    final startTime = state.exerciseStartTimes[index];
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime);
    return duration.inSeconds;
  }

  /// 检查并自动完成 exercise（如果所有 Sets 都已完成）
  void _checkAndCompleteExercise(int index) {
    final exercise = state.exercises[index];

    // 如果已经标记为完成，不重复处理
    if (exercise.completed) return;

    // 检查所有 Sets 是否都已完成
    final allSetsCompleted = exercise.sets.every((set) => set.completed);

    if (allSetsCompleted) {
      // 计算耗时
      final timeSpent = _calculateExerciseTimeSpent(index);

      // 标记 exercise 为完成
      final completedExercise = exercise.copyWith(
        completed: true,
        timeSpent: timeSpent,
      );
      updateExercise(index, completedExercise);

      // 立即保存
      saveRecord().catchError((e) {
        AppLogger.error('Exercise 完成后保存失败', e);
      });

      AppLogger.info('Exercise $index 自动完成, 耗时: $timeSpent 秒');

      // 重置计时器到下一个未完成的 exercise
      _resetTimerToNextIncomplete(index);
    }
  }

  /// 重置计时器到下一个未完成的 exercise
  /// [completedIndex] 刚完成的 exercise 索引
  void _resetTimerToNextIncomplete(int completedIndex) {
    if (!state.isTimerRunning) return;

    // 先从完成的 exercise 后面找
    for (int i = completedIndex + 1; i < state.exercises.length; i++) {
      if (!state.exercises[i].completed) {
        resetExerciseTimer(i);
        AppLogger.info('计时器已重置到 Exercise $i (下一个未完成)');
        return;
      }
    }

    // 如果后面没有未完成的，从头开始找
    for (int i = 0; i < completedIndex; i++) {
      if (!state.exercises[i].completed) {
        resetExerciseTimer(i);
        AppLogger.info('计时器已重置到 Exercise $i (从头查找)');
        return;
      }
    }

    // 如果所有 exercise 都完成了
    AppLogger.info('所有 Exercise 已完成，无需重置计时器');
  }
}
