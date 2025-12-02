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
import 'package:coach_x/core/models/media_upload_state.dart';
import 'package:coach_x/features/student/training/data/repositories/training_record_repository.dart';
import 'package:coach_x/core/services/media_upload_manager.dart';

/// 训练记录 Notifier
class ExerciseRecordNotifier extends StateNotifier<ExerciseRecordState> {
  final TrainingRecordRepository _repository;
  final MediaUploadManager _uploadManager;
  Timer? _debounceTimer;
  StreamSubscription<UploadProgress>? _uploadProgressSubscription;

  ExerciseRecordNotifier(
    this._repository,
    this._uploadManager,
    String initialDate,
  ) : super(ExerciseRecordState.initial(initialDate)) {
    _listenToUploadProgress();
  }

  /// 更新视频上传进度 (Rename to updateMediaUploadProgress if possible, keeping for compat if needed, but updating internals)
  void updateVideoUploadProgress(
    int exerciseIndex,
    int videoIndex,
    double progress,
  ) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    final updatedExercise = exercise.updateMediaProgress(videoIndex, progress);
    updateExercise(exerciseIndex, updatedExercise);
  }

  /// 重试视频上传 (Rename to retryMediaUpload)
  Future<void> retryMediaUpload(int exerciseIndex, int mediaIndex) async {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (mediaIndex < 0 || mediaIndex >= exercise.media.length) return;

    final item = exercise.media[mediaIndex];
    if (item.status != MediaUploadStatus.error || item.localPath == null) {
      return;
    }

    AppLogger.info(
      '重试上传媒体: exerciseIndex=$exerciseIndex, mediaIndex=$mediaIndex',
    );

    // 重置状态为 pending
    final updatedExercise = exercise.retryMediaUpload(mediaIndex);
    updateExercise(exerciseIndex, updatedExercise);

    // 重新启动上传 (注意：Notifier 不再负责上传，这里可能逻辑有变。
    // VideoUploadSection 处理了重试逻辑（onRetry callback）。
    // 所以这里其实主要就是重置状态，VideoUploadSection 收到 retry 后会重新调用 process logic?
    // Wait, VideoUploadSection.onRetry calls _handleMediaRetry which resets state AND restarts upload.
    // VideoUploadSection manages its own upload process.
    // ExerciseRecordNotifier syncs state.
    // If VideoUploadSection handles retries internally and notifies callbacks,
    // then Notifier just needs to respond to callbacks.
    // BUT VideoUploadSection takes `initialMedia` from parent.
    // If parent updates `initialMedia` (via Riverpod state change), VideoUploadSection might rebuild or sync?
    // VideoUploadSection `_initializeMedia` only runs on `initState`.
    // It doesn't sync from props on build unless keys change or we implement `didUpdateWidget`.
    // Looking at VideoUploadSection (old):
    // `didUpdateWidget` wasn't implemented to sync `initialVideos`.
    // `ExerciseRecordCard` passes `exercise.videos` to `VideoUploadSection`.
    // If `VideoUploadSection` manages its own state `_videos`, and `ExerciseRecordCard` passes updated videos from Riverpod...
    // There is a disconnection risk.
    // `VideoUploadSection` (new) has `_mediaList`. It initializes from `widget.initialMedia` in `initState`.
    // It does NOT update `_mediaList` when `widget.initialMedia` changes in `didUpdateWidget`.
    // So `ExerciseRecordNotifier` updates are NOT reflected in `VideoUploadSection` if `VideoUploadSection` is already built.
    // However, `VideoUploadSection` calls callbacks (`onUploadCompleted`) which update Notifier.
    // The flow seems to be: VideoUploadSection (Source of Truth for upload process) -> Notifier (Persisted State).
    // So `retryMediaUpload` in Notifier might only be needed if we want to reset persisted state.
    // But `VideoUploadSection` has `_handleMediaRetry` which handles re-upload locally.
    // The `VideoThumbnailCard` inside `VideoUploadSection` calls `_handleMediaRetry`.
    // `ExerciseRecordCard` passes `onVideoRetry` callback to `VideoUploadSection`.
    // Wait, `VideoUploadSection` (old) had `onVideoRetry`? No.
    // `VideoUploadSection` (old) `VideoThumbnailCard` called `_handleVideoRetry` (internal).
    // `ExerciseRecordCard` passed `onVideoRetry`?
    // `ExerciseRecordCard`: `this.onVideoRetry`.
    // `VideoUploadSection` (old) did NOT have `onVideoRetry` callback exposed.
    // Ah, `ExerciseRecordCard` passed `onVideoRetry` to ... wait.
    // In `ExerciseRecordCard.dart`:
    // `VideoUploadSection(...)`
    // It did NOT pass `onVideoRetry`.
    // `ExerciseRecordCard` constructor HAS `onVideoRetry`, but it wasn't used in `build` for `VideoUploadSection`.
    // So `ExerciseRecordNotifier.retryVideoUpload` might be unused or for other purposes?
    // Let's check usages of `retryVideoUpload` in `ExerciseRecordPage`.
    // `onVideoRetry: (videoIndex) { ref.read(...).retryVideoUpload(index, videoIndex); }`
    // But `ExerciseRecordCard` didn't hook it up to `VideoUploadSection`.
    // So `retryVideoUpload` in Notifier was likely dead code or for a different UI path.
    // `VideoUploadSection` handles retry internally.
    
    // I'll keep `retryMediaUpload` in Notifier just in case, but updated to use `media`.
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _uploadProgressSubscription?.cancel();
    _uploadManager.dispose();

    // 取消所有上传订阅（旧代码，保持兼容）
    for (final subscription in state.uploadSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  /// 加载今日训练
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

      if (training != null &&
          training.exercises != null &&
          training.exercises!.isNotEmpty) {
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
            note: '', // Note field removed from Exercise model
            type: planExercise.type,
            sets: planExercise.sets,
            completed: false,
            media: const [], // Changed from videos to media
            exerciseTemplateId: planExercise.exerciseTemplateId,
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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 更新某个 exercise
  void updateExercise(int index, StudentExerciseModel exercise) {
    if (index < 0 || index >= state.exercises.length) return;

    final newExercises = List<StudentExerciseModel>.from(state.exercises);
    newExercises[index] = exercise;
    state = state.copyWith(exercises: newExercises);
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

      // 计算 totalDuration（仅当所有 exercise 完成且计时器运行过）
      int? totalDuration;
      final allExercisesCompleted =
          state.exercises.isNotEmpty &&
          state.exercises.every((e) => e.completed);
      if (allExercisesCompleted && state.timerStartTime != null) {
        totalDuration = DateTime.now()
            .difference(state.timerStartTime!)
            .inSeconds;
        AppLogger.info('计算训练总时长: $totalDuration 秒');
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
        completionStatus: state.hasCompletedExercises
            ? 'completed'
            : 'in_progress',
        isReviewed: false,
        totalDuration: totalDuration,
      );

      await _repository.upsertTodayTraining(training);

      state = state.copyWith(isSaving: false);

      AppLogger.info('保存训练记录成功');
    } catch (e, stackTrace) {
      AppLogger.error('保存训练记录失败', e, stackTrace);
      state = state.copyWith(isSaving: false, error: '保存失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 删除视频 (Rename to deleteMedia)
  Future<void> deleteMedia(int exerciseIndex, int mediaIndex) async {
    try {
      if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

      final exercise = state.exercises[exerciseIndex];
      if (mediaIndex < 0 || mediaIndex >= exercise.media.length) return;

      AppLogger.info('删除媒体: exercise=$exerciseIndex, media=$mediaIndex');

      // 如果视频正在上传，取消上传任务
      final key = '$exerciseIndex-$mediaIndex';
      final subscription = state.uploadSubscriptions[key];
      if (subscription != null) {
        AppLogger.info('取消上传任务: $key');
        await subscription.cancel();

        // 从订阅列表中移除
        final updatedSubscriptions =
            Map<String, StreamSubscription<double>>.from(
              state.uploadSubscriptions,
            );
        updatedSubscriptions.remove(key);
        state = state.copyWith(uploadSubscriptions: updatedSubscriptions);
      }

      // 更新 exercise（移除媒体）
      final updatedExercise = exercise.removeMedia(mediaIndex);
      updateExercise(exerciseIndex, updatedExercise);

      // 自动保存
      await saveRecord();

      AppLogger.info('媒体删除成功');
    } catch (e, stackTrace) {
      AppLogger.error('媒体删除失败', e, stackTrace);
      state = state.copyWith(error: '媒体删除失败: ${e.toString()}');
      rethrow;
    }
  }

  // Set updates methods same...
  /// 实时更新 Set（不触发保存，不标记完成）
  void updateSetRealtime(int exerciseIndex, int setIndex, TrainingSet set) {
     if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    // 仅更新 Set 数据（不改变 completed 状态）
    final updatedExercise = exercise.updateSet(setIndex, set);
    updateExercise(exerciseIndex, updatedExercise);
  }

  /// 手动完成 Set（点击 checkmark button 触发）
  void completeSet(
    int exerciseIndex,
    int setIndex,
    String reps,
    String weight,
  ) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    // 记录 exercise 开始时间（如果是第一次编辑且计时器在运行）
    if (state.isTimerRunning &&
        !state.exerciseStartTimes.containsKey(exerciseIndex)) {
      _recordExerciseStartTime(exerciseIndex);
    }

    // 更新 Set：填入 reps/weight 并标记完成
    final completedSet = TrainingSet(
      reps: reps,
      weight: weight,
      completed: true,
    );
    final updatedExercise = exercise.updateSet(setIndex, completedSet);
    updateExercise(exerciseIndex, updatedExercise);

    // 检查该 exercise 的所有 Sets 是否都已完成（如果完成会自动保存）
    _checkAndCompleteExercise(exerciseIndex);

    AppLogger.info(
      '手动完成 Set: exercise=$exerciseIndex, set=$setIndex, reps=$reps, weight=$weight',
    );
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

    AppLogger.info(
      '切换 Set 完成状态: exercise=$exerciseIndex, set=$setIndex, completed=${updatedSet.completed}',
    );
  }

  // Timer methods... (Same)
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
    state = state.copyWith(timerStartTime: null, isTimerRunning: false);
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
    if (state.currentExerciseIndex == index &&
        state.currentExerciseStartTime != null) {
      final duration = DateTime.now().difference(
        state.currentExerciseStartTime!,
      );
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

  // ========== 媒体上传管理方法 ==========

  /// 监听上传进度
  void _listenToUploadProgress() {
    _uploadProgressSubscription = _uploadManager.progressStream.listen((progress) {
      _handleUploadProgress(progress);
    });
  }

  /// 处理上传进度事件
  void _handleUploadProgress(UploadProgress progress) {
    // 解析 taskId (格式: "exerciseIndex_mediaIndex")
    final parts = progress.taskId.split('_');
    if (parts.length != 2) {
      AppLogger.error('[ExerciseRecordNotifier] 无效的 taskId 格式: ${progress.taskId}');
      return;
    }

    final exerciseIndex = int.tryParse(parts[0]);
    final mediaIndex = int.tryParse(parts[1]);

    if (exerciseIndex == null || mediaIndex == null) {
      AppLogger.error('[ExerciseRecordNotifier] 无法解析 taskId: ${progress.taskId}');
      return;
    }

    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      AppLogger.error('[ExerciseRecordNotifier] exerciseIndex 越界: $exerciseIndex');
      return;
    }

    final exercise = state.exercises[exerciseIndex];
    if (mediaIndex < 0 || mediaIndex >= exercise.media.length) {
      AppLogger.error('[ExerciseRecordNotifier] mediaIndex 越界: $mediaIndex');
      return;
    }

    AppLogger.info(
      '[ExerciseRecordNotifier] 上传进度更新: ${progress.taskId} - ${(progress.progress * 100).toInt()}% (${progress.status})',
    );

    // 更新媒体状态
    final updatedMedia = List<MediaUploadState>.from(exercise.media);
    updatedMedia[mediaIndex] = updatedMedia[mediaIndex].copyWith(
      status: progress.status,
      progress: progress.progress,
      error: progress.error,
      downloadUrl: progress.downloadUrl,
      thumbnailUrl: progress.thumbnailUrl,
      thumbnailPath: progress.thumbnailPath,
    );

    final updatedExercise = exercise.copyWith(media: updatedMedia);
    updateExercise(exerciseIndex, updatedExercise);

    // 如果完成，保存到 Firestore
    if (progress.status == MediaUploadStatus.completed) {
      AppLogger.info('[ExerciseRecordNotifier] 媒体上传完成，保存记录: ${progress.taskId}');
      saveRecord();
    }
  }

  /// 添加媒体并启动上传
  ///
  /// 由 UI 选择媒体后调用，立即启动后台上传
  void addPendingMedia(
    int exerciseIndex,
    String localPath,
    MediaType type, {
    String? thumbnailPath,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      AppLogger.error(
        '❌ [addPendingMedia] exerciseIndex 无效: $exerciseIndex (总数: ${state.exercises.length})',
      );
      return;
    }

    AppLogger.info(
      '➕ [addPendingMedia] 添加媒体并启动上传: exerciseIndex=$exerciseIndex, localPath=$localPath, type=$type',
    );

    // 1. 添加到 state
    final exercise = state.exercises[exerciseIndex];
    final updatedExercise = exercise.addPendingMedia(localPath, type, thumbnailPath: thumbnailPath);
    updateExercise(exerciseIndex, updatedExercise);

    // 2. 立即启动后台上传
    final mediaIndex = updatedExercise.media.length - 1;
    final taskId = '${exerciseIndex}_$mediaIndex';
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = type == MediaType.video ? 'mp4' : 'jpg';
    final storagePath = 'students/trainings/$userId/$timestamp.$ext';

    _uploadManager.startUpload(
      file: File(localPath),
      type: type,
      storagePath: storagePath,
      taskId: taskId,
      maxVideoSeconds: 60,
      compressionThresholdMB: 50,
    );

    AppLogger.info(
      '✅ [addPendingMedia] 媒体已添加并开始上传，taskId=$taskId',
    );
  }

  /// 完成媒体上传（由 MediaUploadSection 上传完成后调用）
  ///
  /// 更新媒体状态为 completed，并立即保存到 Firestore
  Future<void> completeMediaUpload(
    int exerciseIndex,
    int mediaIndex,
    String downloadUrl, {
    String? thumbnailUrl,
  }) async {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      AppLogger.error(
        '❌ [completeMediaUpload] exerciseIndex 无效: $exerciseIndex (总数: ${state.exercises.length})',
      );
      return;
    }

    final exercise = state.exercises[exerciseIndex];
    if (mediaIndex < 0 || mediaIndex >= exercise.media.length) {
      AppLogger.error(
        '❌ [completeMediaUpload] mediaIndex 无效: $mediaIndex (总数: ${exercise.media.length})',
      );
      return;
    }

    AppLogger.info(
      '✅ [completeMediaUpload] 媒体上传完成: exerciseIndex=$exerciseIndex, mediaIndex=$mediaIndex, downloadUrl=$downloadUrl',
    );

    try {
      // 更新状态为 completed
      final updatedExercise = exercise.completeMediaUpload(
        mediaIndex,
        downloadUrl,
        thumbnailUrl: thumbnailUrl,
      );
      updateExercise(exerciseIndex, updatedExercise);

      AppLogger.info('📝 [completeMediaUpload] 状态已更新，准备保存到 Firestore');

      // 立即保存到 Firestore
      await saveRecord();

      AppLogger.info('✅ [completeMediaUpload] 媒体记录已保存到后端');
    } catch (e, stackTrace) {
      AppLogger.error('❌ [completeMediaUpload] 保存失败', e, stackTrace);
      // 不抛出错误，避免阻塞 UI
    }
  }

}
