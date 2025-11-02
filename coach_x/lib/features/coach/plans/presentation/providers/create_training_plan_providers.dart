import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/create_training_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_training_day.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/repositories/plan_repository_impl.dart';
import 'create_training_plan_notifier.dart';

// ==================== 主状态 Provider ====================

/// 创建训练计划 Notifier Provider
final createTrainingPlanNotifierProvider =
    StateNotifierProvider.autoDispose<CreateTrainingPlanNotifier, CreateTrainingPlanState>(
  (ref) {
    // 获取 Repository
    final repository = ref.watch(trainingPlanRepositoryProvider);
    return CreateTrainingPlanNotifier(repository);
  },
);

// ==================== 计算 Providers ====================

/// 当前选中的训练日 Provider
final currentDayProvider = Provider.autoDispose<ExerciseTrainingDay?>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.selectedDay;
});

/// 当前选中的动作 Provider
final currentExerciseProvider = Provider.autoDispose<Exercise?>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  
  if (state.selectedDayIndex == null ||
      state.selectedExerciseIndex == null ||
      state.selectedDayIndex! < 0 ||
      state.selectedDayIndex! >= state.days.length) {
    return null;
  }

  final day = state.days[state.selectedDayIndex!];
  
  if (state.selectedExerciseIndex! < 0 ||
      state.selectedExerciseIndex! >= day.exercises.length) {
    return null;
  }

  return day.exercises[state.selectedExerciseIndex!];
});

/// 是否可以保存 Provider
final canSaveProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.canSave;
});

/// 验证错误列表 Provider
final validationErrorsProvider = Provider.autoDispose<List<String>>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.validationErrors;
});

/// 是否有未保存的更改 Provider
final hasUnsavedChangesProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.hasUnsavedChanges;
});

/// 训练日总数 Provider
final totalDaysProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.totalDays;
});

/// 所有动作总数 Provider
final totalExercisesProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.totalExercises;
});

/// 所有 Sets 总数 Provider
final totalSetsProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.totalSets;
});

/// 是否正在加载 Provider
final isLoadingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.isLoading;
});

/// AI 是否正在生成 Provider
final isAIGeneratingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.isAIGenerating;
});

/// 是否有 AI 建议 Provider
final hasSuggestionsProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(createTrainingPlanNotifierProvider);
  return state.hasSuggestions;
});

// ==================== Repository Provider ====================

/// Training Plan Repository Provider
final trainingPlanRepositoryProvider = Provider<PlanRepositoryImpl>((ref) {
  return PlanRepositoryImpl();
});

