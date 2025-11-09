import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/enums/app_status.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/plan_validator.dart';
import 'package:coach_x/features/coach/plans/data/models/create_training_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_training_day.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/ai/ai_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/import_result.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/data/repositories/plan_repository.dart';

/// 创建训练计划状态管理
class CreateTrainingPlanNotifier
    extends StateNotifier<CreateTrainingPlanState> {
  final PlanRepository _planRepository;

  CreateTrainingPlanNotifier(this._planRepository)
    : super(const CreateTrainingPlanState());

  // ==================== 基础字段更新 ====================

  /// 更新计划名称
  void updatePlanName(String name) {
    state = state.copyWith(planName: name);
  }

  /// 更新描述
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  // ==================== 训练日管理 ====================

  /// 添加训练日
  void addDay({String? name, String? note}) {
    final dayNumber = state.days.length + 1;
    final newDay = ExerciseTrainingDay(
      day: dayNumber,
      name: name ?? 'Day $dayNumber',
      note: note ?? '',
      exercises: [], // 不自动添加空 Exercise，让用户手动添加
      completed: false,
    );

    final updatedDays = [...state.days, newDay];
    state = state.copyWith(days: updatedDays);

    AppLogger.debug('➕ 添加训练日 - Day $dayNumber');
  }

  /// 删除训练日
  void removeDay(int index) {
    if (index < 0 || index >= state.days.length) return;

    final updatedDays = List<ExerciseTrainingDay>.from(state.days);
    updatedDays.removeAt(index);

    // 重新编号
    for (int i = 0; i < updatedDays.length; i++) {
      updatedDays[i] = updatedDays[i].copyWith(day: i + 1);
    }

    state = state.copyWith(days: updatedDays);

    AppLogger.debug('🗑️ 删除训练日 - Index $index');
  }

  /// 更新训练日
  void updateDay(int index, ExerciseTrainingDay day) {
    if (index < 0 || index >= state.days.length) return;

    final updatedDays = List<ExerciseTrainingDay>.from(state.days);
    updatedDays[index] = day;

    state = state.copyWith(days: updatedDays);
  }

  /// 更新训练日名称
  void updateDayName(int dayIndex, String name) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final updatedDay = day.copyWith(name: name);
    updateDay(dayIndex, updatedDay);
  }

  /// 更新训练日备注
  void updateDayNote(int dayIndex, String note) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final updatedDay = day.copyWith(note: note);
    updateDay(dayIndex, updatedDay);
  }

  // ==================== 动作管理 ====================

  /// 添加动作
  void addExercise(int dayIndex, {Exercise? exercise}) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final newExercise = exercise ?? Exercise.empty();
    final updatedDay = day.addExercise(newExercise);

    updateDay(dayIndex, updatedDay);

    AppLogger.debug('➕ 添加动作 - Day ${dayIndex + 1}');
  }

  /// 删除动作
  void removeExercise(int dayIndex, int exerciseIndex) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final updatedDay = day.removeExercise(exerciseIndex);

    updateDay(dayIndex, updatedDay);

    AppLogger.debug(
      '🗑️ 删除动作 - Day ${dayIndex + 1}, Exercise ${exerciseIndex + 1}',
    );
  }

  /// 更新动作
  void updateExercise(int dayIndex, int exerciseIndex, Exercise exercise) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final updatedDay = day.updateExercise(exerciseIndex, exercise);

    updateDay(dayIndex, updatedDay);
  }

  /// 更新动作名称
  void updateExerciseName(int dayIndex, int exerciseIndex, String name) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) return;

    final exercise = day.exercises[exerciseIndex];
    final updatedExercise = exercise.copyWith(name: name);
    updateExercise(dayIndex, exerciseIndex, updatedExercise);
  }

  /// 更新动作备注
  void updateExerciseNote(int dayIndex, int exerciseIndex, String note) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) return;

    final exercise = day.exercises[exerciseIndex];
    final updatedExercise = exercise.copyWith(note: note);
    updateExercise(dayIndex, exerciseIndex, updatedExercise);
  }

  // ==================== Set 管理 ====================

  /// 添加 Set
  void addSet(int dayIndex, int exerciseIndex, {TrainingSet? set}) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) return;

    final exercise = day.exercises[exerciseIndex];
    final newSet = set ?? TrainingSet.empty();
    final updatedExercise = exercise.addSet(newSet);

    updateExercise(dayIndex, exerciseIndex, updatedExercise);

    AppLogger.debug(
      '➕ 添加Set - Day ${dayIndex + 1}, Exercise ${exerciseIndex + 1}',
    );
  }

  /// 删除 Set
  void removeSet(int dayIndex, int exerciseIndex, int setIndex) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) return;

    final exercise = day.exercises[exerciseIndex];
    final updatedExercise = exercise.removeSet(setIndex);

    updateExercise(dayIndex, exerciseIndex, updatedExercise);

    AppLogger.debug(
      '🗑️ 删除Set - Day ${dayIndex + 1}, Exercise ${exerciseIndex + 1}, Set ${setIndex + 1}',
    );
  }

  /// 更新 Set
  void updateSet(
    int dayIndex,
    int exerciseIndex,
    int setIndex,
    TrainingSet set,
  ) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) return;

    final exercise = day.exercises[exerciseIndex];
    final updatedExercise = exercise.updateSet(setIndex, set);

    updateExercise(dayIndex, exerciseIndex, updatedExercise);
  }

  // ==================== 选择管理 ====================

  /// 选中训练日
  void selectDay(int? index) {
    state = state.copyWith(
      selectedDayIndex: index,
      selectedExerciseIndex: -1, // 清空动作选择
    );
  }

  /// 选中动作
  void selectExercise(int? dayIndex, int? exerciseIndex) {
    state = state.copyWith(
      selectedDayIndex: dayIndex,
      selectedExerciseIndex: exerciseIndex,
    );
  }

  // ==================== 验证 ====================

  /// 验证当前计划
  void validate() {
    final plan = ExercisePlanModel(
      id: '',
      name: state.planName,
      description: state.description,
      ownerId: '',
      studentIds: const [],
      createdAt: 0,
      updatedAt: 0,
      days: state.days,
    );

    final errors = PlanValidator.getValidationErrors(plan);

    state = state.copyWith(validationErrors: errors);

    if (errors.isNotEmpty) {
      AppLogger.warning('⚠️ 验证失败: ${errors.first}');
    }
  }

  // ==================== 保存与加载 ====================

  /// 加载现有计划
  Future<bool> loadPlan(String planId) async {
    try {
      state = state.copyWith(loadingStatus: LoadingStatus.loading);

      AppLogger.info('📖 加载训练计划 - ID: $planId');

      // 从Repository加载计划
      final plan = await _planRepository.getPlanDetail(planId: planId);

      // 更新状态
      state = state.copyWith(
        planId: plan.id,
        planName: plan.name,
        description: plan.description,
        days: plan.days,
        loadingStatus: LoadingStatus.success,
        isEditMode: true,
      );

      AppLogger.info('✅ 训练计划加载成功: ${plan.name}');

      return true;
    } catch (e) {
      AppLogger.error('❌ 加载训练计划失败', e);

      state = state.copyWith(
        loadingStatus: LoadingStatus.error,
        errorMessage: '加载失败: $e',
      );

      return false;
    }
  }

  /// 保存计划
  Future<bool> savePlan() async {
    try {
      // 验证
      validate();
      if (state.validationErrors.isNotEmpty) {
        state = state.copyWith(errorMessage: state.validationErrors.first);
        return false;
      }

      state = state.copyWith(loadingStatus: LoadingStatus.loading);

      AppLogger.info('💾 保存训练计划: ${state.planName}');

      // 创建计划对象
      final plan = ExercisePlanModel(
        id: state.planId ?? '', // 编辑模式使用现有ID
        name: state.planName,
        description: state.description,
        ownerId: '', // 服务端填充
        studentIds: const [],
        createdAt: 0, // 服务端填充
        updatedAt: 0, // 服务端填充
        days: state.days,
      );

      // 根据是否有planId判断是创建还是更新
      String planId;
      if (state.isEditMode &&
          state.planId != null &&
          state.planId!.isNotEmpty) {
        // 更新现有计划
        await _planRepository.updatePlan(plan: plan);
        planId = state.planId!;
        AppLogger.info('✅ 训练计划更新成功 - ID: $planId');
      } else {
        // 创建新计划
        planId = await _planRepository.createPlan(plan: plan);
        AppLogger.info('✅ 训练计划创建成功 - ID: $planId');
      }

      state = state.copyWith(
        loadingStatus: LoadingStatus.success,
        planId: planId,
      );

      return true;
    } catch (e) {
      AppLogger.error('❌ 保存训练计划失败', e);

      state = state.copyWith(
        loadingStatus: LoadingStatus.error,
        errorMessage: '保存失败: $e',
      );

      return false;
    }
  }

  // ==================== 重置 ====================

  /// 重置状态
  void reset() {
    state = const CreateTrainingPlanState();
    AppLogger.debug('🔄 重置创建计划状态');
  }

  /// 清空错误
  void clearError() {
    state = state.clearError();
  }

  // ==================== AI 推荐 Sets ====================

  /// 推荐 Sets 配置
  Future<void> suggestSets(
    int dayIndex,
    int exerciseIndex,
    String exerciseName,
  ) async {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) return;

    try {
      AppLogger.info('🤖 AI推荐Sets - Exercise: $exerciseName');

      state = state.copyWith(
        aiStatus: AIGenerationStatus.generating,
        errorMessage: '',
      );

      final response = await AIService.suggestSets(exerciseName: exerciseName);

      if (response.isSuccess && response.sets != null) {
        // 成功：替换该动作的 Sets
        final exercise = day.exercises[exerciseIndex];
        final updatedExercise = exercise.copyWith(sets: response.sets!);

        final updatedExercises = List<Exercise>.from(day.exercises);
        updatedExercises[exerciseIndex] = updatedExercise;

        final updatedDay = day.copyWith(exercises: updatedExercises);

        final updatedDays = List<ExerciseTrainingDay>.from(state.days);
        updatedDays[dayIndex] = updatedDay;

        state = state.copyWith(
          days: updatedDays,
          aiStatus: AIGenerationStatus.success,
        );

        AppLogger.info('✅ AI推荐Sets成功 - ${response.sets!.length} 组');
      } else {
        state = state.copyWith(
          aiStatus: AIGenerationStatus.error,
          errorMessage: response.error ?? '推荐失败',
        );

        AppLogger.warning('⚠️ AI推荐失败: ${response.error}');
      }
    } catch (e) {
      AppLogger.error('❌ AI推荐异常', e);

      state = state.copyWith(
        aiStatus: AIGenerationStatus.error,
        errorMessage: 'AI推荐异常: $e',
      );
    }
  }

  // ==================== 建议管理 ====================

  /// 应用建议
  void applySuggestion(AISuggestion suggestion) {
    // TODO: 根据建议类型应用相应的数据
    AppLogger.debug('应用AI建议: ${suggestion.title}');

    // 移除已应用的建议
    final updatedSuggestions = state.suggestions
        .where((s) => s.id != suggestion.id)
        .toList();

    state = state.copyWith(suggestions: updatedSuggestions);
  }

  /// 忽略建议
  void dismissSuggestion(AISuggestion suggestion) {
    final updatedSuggestions = state.suggestions
        .where((s) => s.id != suggestion.id)
        .toList();

    state = state.copyWith(suggestions: updatedSuggestions);

    AppLogger.debug('忽略AI建议: ${suggestion.title}');
  }

  /// 清空所有建议
  void clearSuggestions() {
    state = state.copyWith(suggestions: []);
  }

  // ==================== 重置 AI 状态 ====================

  /// 重置 AI 状态
  void resetAIStatus() {
    state = state.copyWith(aiStatus: AIGenerationStatus.idle, errorMessage: '');
  }

  // ==================== 导入和引导式创建 ====================

  /// 从导入结果加载计划
  ///
  /// 将导入的计划数据加载到当前状态
  void loadFromImportResult(ImportResult result) {
    if (!result.isSuccess || result.plan == null) {
      AppLogger.warning('导入结果无效，无法加载');
      return;
    }

    final plan = result.plan!;
    AppLogger.info('📥 从导入结果加载计划: ${plan.name}');

    // 验证计划数据
    final errors = PlanValidator.getValidationErrors(plan);

    if (errors.isNotEmpty) {
      AppLogger.warning('导入的计划存在验证错误: ${errors.join(", ")}');
      state = state.copyWith(errorMessage: '导入的计划数据不完整：${errors.first}');
      return;
    }

    // 加载计划数据到状态
    state = state.copyWith(
      planName: plan.name,
      description: plan.description,
      days: plan.days,
      errorMessage: '',
    );

    AppLogger.info('✅ 计划加载成功 - ${plan.totalDays} 个训练日');
  }

  /// 从参数生成计划
  ///
  /// 使用结构化参数生成完整训练计划
  Future<void> generateFromParams(PlanGenerationParams params) async {
    try {
      AppLogger.info('🤖 基于参数生成计划');

      // 验证参数
      if (!params.isValid) {
        final errors = params.validationErrors;
        state = state.copyWith(
          aiStatus: AIGenerationStatus.error,
          errorMessage: '参数验证失败: ${errors.first}',
        );
        return;
      }

      // 设置加载状态
      state = state.copyWith(
        aiStatus: AIGenerationStatus.generating,
        errorMessage: '',
      );

      // 调用 AI 服务
      final response = await AIService.generatePlanFromParams(params: params);

      if (response.isSuccess && response.plan != null) {
        final plan = response.plan!;

        // 更新状态
        state = state.copyWith(
          planName: plan.name,
          description: plan.description,
          days: plan.days,
          aiStatus: AIGenerationStatus.success,
          errorMessage: '',
        );

        AppLogger.info('✅ 参数生成成功 - ${plan.totalDays} 个训练日');
      } else {
        state = state.copyWith(
          aiStatus: AIGenerationStatus.error,
          errorMessage: response.error ?? '生成失败',
        );
        AppLogger.warning('⚠️ 参数生成失败: ${response.error}');
      }
    } catch (e) {
      state = state.copyWith(
        aiStatus: AIGenerationStatus.error,
        errorMessage: '生成失败: $e',
      );
      AppLogger.error('❌ 参数生成异常', e);
    }
  }

  /// 应用导入的计划（可选择性合并或替换）
  ///
  /// [plan] 导入的计划
  /// [mode] 'replace' 替换全部，'merge' 合并训练日
  void applyImportedPlan(ExercisePlanModel plan, {String mode = 'replace'}) {
    if (mode == 'replace') {
      // 替换模式：完全替换当前计划
      state = state.copyWith(
        planName: plan.name,
        description: plan.description,
        days: plan.days,
      );
      AppLogger.info('✅ 计划已替换');
    } else if (mode == 'merge') {
      // 合并模式：将导入的训练日追加到当前计划
      final currentDays = state.days;
      final importedDays = plan.days.map((day) {
        return day.copyWith(day: currentDays.length + day.day);
      }).toList();

      state = state.copyWith(days: [...currentDays, ...importedDays]);
      AppLogger.info('✅ 计划已合并 - 新增 ${importedDays.length} 个训练日');
    }
  }

  /// 流式生成训练计划
  ///
  /// 使用 SSE 实时接收生成进度
  /// [params] 结构化参数
  Future<void> generateFromParamsStreaming(PlanGenerationParams params) async {
    try {
      AppLogger.info('🔄 开始流式生成训练计划');

      // 清空现有数据
      state = state.copyWith(
        days: [],
        aiStatus: AIGenerationStatus.generating,
        errorMessage: '',
        currentDayInProgress: null,
        currentDayNumber: null,
      );

      // 监听流式事件
      await for (final event in AIService.generatePlanStreaming(
        params: params,
      )) {
        if (event.isThinking) {
          // 思考过程（目前不需要显示，但保留日志）
          if (event.content != null) {
            AppLogger.debug('💭 思考: ${event.content}');
          }
        } else if (event.isDayStart) {
          // 开始生成新的一天
          AppLogger.info('📅 开始生成第 ${event.day} 天');
          state = state.copyWith(
            currentDayInProgress: ExerciseTrainingDay.empty(event.day!),
            currentDayNumber: event.day,
          );
        } else if (event.isExerciseStart) {
          // 动作开始（可选，仅记录日志）
          AppLogger.debug(
            '🏋️ 开始添加动作 ${event.exerciseIndex}/${event.totalExercises}: ${event.exerciseName}',
          );
        } else if (event.isExerciseComplete) {
          // 动作完成 - 追加到当前训练日
          if (state.currentDayInProgress != null &&
              event.exerciseData != null) {
            final updatedDay = state.currentDayInProgress!.addExercise(
              event.exerciseData!,
            );
            state = state.copyWith(currentDayInProgress: updatedDay);
            AppLogger.info(
              '✅ 第 ${event.day} 天第 ${event.exerciseIndex} 个动作已添加: ${event.exerciseData!.name}',
            );
          }
        } else if (event.isDayComplete) {
          // 一天完成 - 将当前训练日添加到列表
          if (state.currentDayInProgress != null) {
            final updatedDays = [...state.days, state.currentDayInProgress!];
            state = state.copyWith(
              days: updatedDays,
              currentDayInProgress: null,
              currentDayNumber: null,
            );
            AppLogger.info('🎉 第 ${event.day} 天已完成');
          }
        } else if (event.isComplete) {
          // 全部完成
          state = state.copyWith(
            aiStatus: AIGenerationStatus.success,
            currentDayInProgress: null,
            currentDayNumber: null,
          );
          AppLogger.info('🎉 流式生成完成 - 共 ${state.days.length} 天');
          break;
        } else if (event.isError) {
          // 错误
          state = state.copyWith(
            aiStatus: AIGenerationStatus.error,
            errorMessage: event.error ?? '生成失败',
            currentDayInProgress: null,
            currentDayNumber: null,
          );
          AppLogger.error('❌ 流式生成失败: ${event.error}');
          break;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 流式生成异常', e, stackTrace);
      state = state.copyWith(
        aiStatus: AIGenerationStatus.error,
        errorMessage: '生成失败: $e',
        currentDayInProgress: null,
        currentDayNumber: null,
      );
    }
  }

  /// 应用 AI 修改的计划
  ///
  /// [modifiedPlan] AI 修改后的完整计划
  void applyModifiedPlan(ExercisePlanModel modifiedPlan) {
    AppLogger.info('✅ 应用 AI 修改的计划');

    state = state.copyWith(
      planName: modifiedPlan.name,
      description: modifiedPlan.description,
      days: modifiedPlan.days,
    );

    AppLogger.info('计划已更新 - ${modifiedPlan.days.length} 个训练日');
  }
}
