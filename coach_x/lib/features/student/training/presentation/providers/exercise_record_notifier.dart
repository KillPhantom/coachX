import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_compress/video_compress.dart';
import 'package:coach_x/core/constants/app_constants.dart';
import 'package:coach_x/core/services/video_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_record_state.dart';
import 'package:coach_x/core/models/video_upload_state.dart';
import 'package:coach_x/features/student/training/data/repositories/training_record_repository.dart';

/// 训练记录 Notifier
class ExerciseRecordNotifier extends StateNotifier<ExerciseRecordState> {
  final TrainingRecordRepository _repository;
  Timer? _debounceTimer;

  ExerciseRecordNotifier(this._repository, String initialDate)
    : super(ExerciseRecordState.initial(initialDate));

  /// 后台压缩并上传视频
  ///
  /// @deprecated 此方法已弃用，现在由 VideoUploadSection 处理压缩和上传。
  @Deprecated(
    'Video compression and upload is now handled by VideoUploadSection.',
  )
  Future<void> _compressAndUpload(
    int exerciseIndex,
    int videoIndex,
    File originalFile,
  ) async {
    File finalFile = originalFile;

    try {
      // 条件压缩（后台执行）
      AppLogger.info('📦 检查视频是否需要压缩');
      final shouldCompress = await VideoService.shouldCompress(
        originalFile,
        thresholdMB: AppConstants.videoCompressionThresholdMB,
      );

      AppLogger.info('📦 压缩检查结果: ${shouldCompress ? "需要压缩" : "不需要压缩"}');

      if (shouldCompress) {
        AppLogger.info(
          '视频超过 ${AppConstants.videoCompressionThresholdMB}MB，开始后台压缩',
        );
        finalFile = await VideoService.compressVideo(
          originalFile,
          quality: VideoQuality.MediumQuality,
        );
        AppLogger.info('视频压缩完成');
      }
    } catch (e) {
      AppLogger.error('视频压缩失败，使用原文件上传', e);
      // 压缩失败不阻塞上传，继续使用原文件
    }

    // 压缩完成（或跳过），开始上传
    _startAsyncUpload(exerciseIndex, videoIndex, finalFile);
  }

  /// 启动后台异步上传
  ///
  /// @deprecated 此方法已弃用，现在由 VideoUploadSection 处理异步上传。
  @Deprecated('Async upload is now handled by VideoUploadSection.')
  void _startAsyncUpload(int exerciseIndex, int videoIndex, File videoFile) {
    // 构建存储路径
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'students/trainings/$userId/$timestamp.mp4';

    AppLogger.info('开始上传: $path');

    // 监听上传进度
    final subscription = _repository
        .uploadVideoWithProgress(videoFile, path)
        .listen(
          (progress) {
            // 实时更新进度
            updateVideoUploadProgress(exerciseIndex, videoIndex, progress);
            // 安全检查：确保 progress 是有效数字
            if (progress.isFinite) {
              AppLogger.info('上传进度: ${(progress * 100).toInt()}%');
            } else {
              AppLogger.info('上传进度: 无效值 (NaN/Infinity)');
            }
          },
          onDone: () async {
            try {
              // 1. 上传完成，获取视频下载 URL
              final downloadUrl = await _repository.getDownloadUrl(path);
              AppLogger.info('视频上传成功: $downloadUrl');

              // 2. 上传缩略图
              String? thumbnailUrl;
              final exercise = state.exercises[exerciseIndex];
              final video = exercise.videos[videoIndex];

              if (video.thumbnailPath != null) {
                try {
                  AppLogger.info('开始上传缩略图');
                  final thumbnailPath = path.replaceAll('.mp4', '_thumb.jpg');
                  thumbnailUrl = await _repository.uploadThumbnail(
                    File(video.thumbnailPath!),
                    thumbnailPath,
                  );
                  AppLogger.info('缩略图上传成功: $thumbnailUrl');
                } catch (e) {
                  AppLogger.error('缩略图上传失败，继续保存视频', e);
                  // 缩略图上传失败不阻塞视频保存
                }
              }

              // 3. 完成视频上传，保存两个 URL
              _completeVideoUpload(
                exerciseIndex,
                videoIndex,
                downloadUrl,
                thumbnailUrl: thumbnailUrl,
              );

              // 4. 自动保存到 Firestore
              await saveRecord();

              AppLogger.info('视频记录保存成功');
            } catch (e) {
              AppLogger.error('视频上传流程失败', e);
              _failVideoUpload(exerciseIndex, videoIndex, '上传失败');
            }
          },
          onError: (error) {
            AppLogger.error('视频上传失败', error);
            _failVideoUpload(exerciseIndex, videoIndex, error.toString());
          },
        );

    // 保存订阅（用于 dispose 时取消）
    final key = '$exerciseIndex-$videoIndex';
    final updatedSubscriptions = Map<String, StreamSubscription<double>>.from(
      state.uploadSubscriptions,
    );
    updatedSubscriptions[key] = subscription;

    state = state.copyWith(uploadSubscriptions: updatedSubscriptions);
  }

  /// 更新视频上传进度
  void updateVideoUploadProgress(
    int exerciseIndex,
    int videoIndex,
    double progress,
  ) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    final updatedExercise = exercise.updateVideoProgress(videoIndex, progress);
    updateExercise(exerciseIndex, updatedExercise);
  }

  /// 完成视频上传
  void _completeVideoUpload(
    int exerciseIndex,
    int videoIndex,
    String downloadUrl, {
    String? thumbnailUrl,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    final updatedExercise = exercise.completeVideoUpload(
      videoIndex,
      downloadUrl,
      thumbnailUrl: thumbnailUrl,
    );
    updateExercise(exerciseIndex, updatedExercise);

    // 移除订阅
    final key = '$exerciseIndex-$videoIndex';
    final updatedSubscriptions = Map<String, StreamSubscription<double>>.from(
      state.uploadSubscriptions,
    );
    updatedSubscriptions.remove(key);
    state = state.copyWith(uploadSubscriptions: updatedSubscriptions);
  }

  /// 标记视频上传失败
  void _failVideoUpload(int exerciseIndex, int videoIndex, String error) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    final updatedExercise = exercise.failVideoUpload(videoIndex, error);
    updateExercise(exerciseIndex, updatedExercise);

    // 移除订阅
    final key = '$exerciseIndex-$videoIndex';
    final updatedSubscriptions = Map<String, StreamSubscription<double>>.from(
      state.uploadSubscriptions,
    );
    updatedSubscriptions.remove(key);
    state = state.copyWith(uploadSubscriptions: updatedSubscriptions);
  }

  /// 重试视频上传
  Future<void> retryVideoUpload(int exerciseIndex, int videoIndex) async {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (videoIndex < 0 || videoIndex >= exercise.videos.length) return;

    final video = exercise.videos[videoIndex];
    if (video.status != VideoUploadStatus.error || video.localPath == null) {
      return;
    }

    AppLogger.info(
      '重试上传视频: exerciseIndex=$exerciseIndex, videoIndex=$videoIndex',
    );

    // 重置状态为 pending
    final updatedExercise = exercise.retryVideoUpload(videoIndex);
    updateExercise(exerciseIndex, updatedExercise);

    // 重新启动上传
    _startAsyncUpload(exerciseIndex, videoIndex, File(video.localPath!));
  }

  @override
  void dispose() {
    // 取消所有上传订阅
    for (final subscription in state.uploadSubscriptions.values) {
      subscription.cancel();
    }
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
            videos: const [],
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

  /// 上传视频（异步非阻塞版本）
  ///
  /// @deprecated 此方法已弃用，现在由 VideoUploadSection 处理上传。
  /// 使用 addPendingVideo() 添加 pending 视频，
  /// 使用 completeVideoUpload() 在上传完成后更新状态。
  @Deprecated(
    'Use addPendingVideo() and completeVideoUpload() instead. '
    'Video upload is now handled by VideoUploadSection.',
  )
  Future<void> uploadVideo(int exerciseIndex, File videoFile) async {
    try {
      AppLogger.info(
        '🎬 [uploadVideo] 收到上传请求: exerciseIndex=$exerciseIndex, videoPath=${videoFile.path}',
      );

      if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
        AppLogger.error(
          '❌ [uploadVideo] exerciseIndex 无效: $exerciseIndex (总数: ${state.exercises.length})',
        );
        return;
      }

      AppLogger.info(
        '📋 [uploadVideo] 当前 exercise: ${state.exercises[exerciseIndex].name}',
      );
      AppLogger.info(
        '📋 [uploadVideo] 当前视频数: ${state.exercises[exerciseIndex].videos.length}',
      );

      // 1. 生成缩略图（本地）
      AppLogger.info('🖼️ [uploadVideo] 开始生成视频缩略图');
      final thumbnailFile = await VideoUtils.generateThumbnail(videoFile.path);
      AppLogger.info(
        '🖼️ [uploadVideo] 缩略图生成${thumbnailFile != null ? "成功: ${thumbnailFile.path}" : "失败（返回null）"}',
      );

      // 2. 立即添加到列表（pending 状态）
      final exercise = state.exercises[exerciseIndex];
      AppLogger.info('➕ [uploadVideo] 添加视频到pending列表');
      final updatedExercise = exercise.addPendingVideo(
        videoFile.path,
        thumbnailFile?.path,
      );
      updateExercise(exerciseIndex, updatedExercise);
      AppLogger.info(
        '✅ [uploadVideo] 视频已添加到列表，新视频数: ${updatedExercise.videos.length}',
      );

      // 3. 启动后台压缩 + 上传（不等待）
      final videoIndex = updatedExercise.videos.length - 1;
      AppLogger.info('🚀 [uploadVideo] 启动后台压缩和上传: videoIndex=$videoIndex');
      _compressAndUpload(exerciseIndex, videoIndex, videoFile);

      AppLogger.info('✅ [uploadVideo] 视频添加成功，后台压缩和上传已启动');
    } catch (e, stackTrace) {
      AppLogger.error('❌ [uploadVideo] 视频处理失败', e, stackTrace);
      state = state.copyWith(error: '视频处理失败: ${e.toString()}');
    }
  }

  /// 删除视频
  Future<void> deleteVideo(int exerciseIndex, int videoIndex) async {
    try {
      if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

      final exercise = state.exercises[exerciseIndex];
      if (videoIndex < 0 || videoIndex >= exercise.videos.length) return;

      AppLogger.info('删除视频: exercise=$exerciseIndex, video=$videoIndex');

      // 如果视频正在上传，取消上传任务
      final key = '$exerciseIndex-$videoIndex';
      final subscription = state.uploadSubscriptions[key];
      if (subscription != null) {
        AppLogger.info('取消视频上传任务: $key');
        await subscription.cancel();

        // 从订阅列表中移除
        final updatedSubscriptions =
            Map<String, StreamSubscription<double>>.from(
              state.uploadSubscriptions,
            );
        updatedSubscriptions.remove(key);
        state = state.copyWith(uploadSubscriptions: updatedSubscriptions);
      }

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

  // ========== 视频状态管理方法（新增，v2.4）==========

  /// 添加 Pending 状态视频（不启动上传）
  ///
  /// 由 VideoUploadSection 选择视频后调用，仅添加占位符
  void addPendingVideo(
    int exerciseIndex,
    String localPath,
    String? thumbnailPath,
  ) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      AppLogger.error(
        '❌ [addPendingVideo] exerciseIndex 无效: $exerciseIndex (总数: ${state.exercises.length})',
      );
      return;
    }

    AppLogger.info(
      '➕ [addPendingVideo] 添加 pending 视频: exerciseIndex=$exerciseIndex, localPath=$localPath',
    );

    final exercise = state.exercises[exerciseIndex];
    final updatedExercise = exercise.addPendingVideo(localPath, thumbnailPath);
    updateExercise(exerciseIndex, updatedExercise);

    AppLogger.info(
      '✅ [addPendingVideo] Pending 视频已添加，当前视频数: ${updatedExercise.videos.length}',
    );
  }

  /// 完成视频上传（由 VideoUploadSection 上传完成后调用）
  ///
  /// 更新视频状态为 completed，并立即保存到 Firestore
  Future<void> completeVideoUpload(
    int exerciseIndex,
    int videoIndex,
    String downloadUrl, {
    String? thumbnailUrl,
  }) async {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      AppLogger.error(
        '❌ [completeVideoUpload] exerciseIndex 无效: $exerciseIndex (总数: ${state.exercises.length})',
      );
      return;
    }

    final exercise = state.exercises[exerciseIndex];
    if (videoIndex < 0 || videoIndex >= exercise.videos.length) {
      AppLogger.error(
        '❌ [completeVideoUpload] videoIndex 无效: $videoIndex (总数: ${exercise.videos.length})',
      );
      return;
    }

    AppLogger.info(
      '✅ [completeVideoUpload] 视频上传完成: exerciseIndex=$exerciseIndex, videoIndex=$videoIndex, downloadUrl=$downloadUrl',
    );

    try {
      // 更新视频状态为 completed
      final updatedExercise = exercise.completeVideoUpload(
        videoIndex,
        downloadUrl,
        thumbnailUrl: thumbnailUrl,
      );
      updateExercise(exerciseIndex, updatedExercise);

      AppLogger.info('📝 [completeVideoUpload] 状态已更新，准备保存到 Firestore');

      // 立即保存到 Firestore
      await saveRecord();

      AppLogger.info('✅ [completeVideoUpload] 视频记录已保存到后端');
    } catch (e, stackTrace) {
      AppLogger.error('❌ [completeVideoUpload] 保存失败', e, stackTrace);
      // 不抛出错误，避免阻塞 UI
    }
  }
}
