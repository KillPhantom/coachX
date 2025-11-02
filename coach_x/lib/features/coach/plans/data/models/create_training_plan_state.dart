import 'package:coach_x/core/enums/app_status.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_training_day.dart';
import 'package:coach_x/features/coach/plans/data/models/ai/ai_suggestion.dart';
import 'package:coach_x/core/utils/plan_validator.dart';
import 'exercise_plan_model.dart';

/// 创建训练计划页面状态模型
class CreateTrainingPlanState {
  final String? planId;
  final String planName;
  final String description;
  final List<ExerciseTrainingDay> days;
  final LoadingStatus loadingStatus;
  final AIGenerationStatus aiStatus;
  final List<AISuggestion> suggestions;
  final String? errorMessage;
  final int? selectedDayIndex;
  final int? selectedExerciseIndex;
  final List<String> validationErrors;
  final bool isEditMode;
  
  /// 正在构建中的训练日
  final ExerciseTrainingDay? currentDayInProgress;
  
  /// 当前正在生成的天数
  final int? currentDayNumber;

  const CreateTrainingPlanState({
    this.planId,
    this.planName = '',
    this.description = '',
    this.days = const [],
    this.loadingStatus = LoadingStatus.initial,
    this.aiStatus = AIGenerationStatus.idle,
    this.suggestions = const [],
    this.errorMessage,
    this.selectedDayIndex,
    this.selectedExerciseIndex,
    this.validationErrors = const [],
    this.isEditMode = false,
    this.currentDayInProgress,
    this.currentDayNumber,
  });

  /// 复制并修改部分字段
  CreateTrainingPlanState copyWith({
    String? planId,
    String? planName,
    String? description,
    List<ExerciseTrainingDay>? days,
    LoadingStatus? loadingStatus,
    AIGenerationStatus? aiStatus,
    List<AISuggestion>? suggestions,
    String? errorMessage,
    int? selectedDayIndex,
    int? selectedExerciseIndex,
    List<String>? validationErrors,
    bool? isEditMode,
    ExerciseTrainingDay? currentDayInProgress,
    int? currentDayNumber,
  }) {
    return CreateTrainingPlanState(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      days: days ?? this.days,
      loadingStatus: loadingStatus ?? this.loadingStatus,
      aiStatus: aiStatus ?? this.aiStatus,
      suggestions: suggestions ?? this.suggestions,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      selectedExerciseIndex: selectedExerciseIndex ?? this.selectedExerciseIndex,
      validationErrors: validationErrors ?? this.validationErrors,
      isEditMode: isEditMode ?? this.isEditMode,
      currentDayInProgress: currentDayInProgress ?? this.currentDayInProgress,
      currentDayNumber: currentDayNumber ?? this.currentDayNumber,
    );
  }

  /// 清空错误信息
  CreateTrainingPlanState clearError() {
    return copyWith(
      errorMessage: '',
      validationErrors: [],
    );
  }

  /// 清空选择
  CreateTrainingPlanState clearSelection() {
    return copyWith(
      selectedDayIndex: -1,
      selectedExerciseIndex: -1,
    );
  }

  /// 验证当前状态
  bool get isValid {
    // 创建临时计划对象进行验证
    final plan = ExercisePlanModel(
      id: '',
      name: planName,
      description: description,
      ownerId: '',
      studentIds: const [],
      createdAt: 0,
      updatedAt: 0,
      days: days,
    );
    return PlanValidator.isValidPlan(plan);
  }

  /// 是否可以保存
  bool get canSave {
    // 基本验证
    if (planName.trim().isEmpty) return false;
    if (days.isEmpty) return false;

    // 至少要有一个训练日包含动作
    bool hasAtLeastOneExercise = false;

    // 验证每个训练日
    for (final day in days) {
      // 如果训练日有动作，验证这些动作
      if (day.exercises.isNotEmpty) {
        hasAtLeastOneExercise = true;
        
        // 每个动作要有名称和至少一组
        for (final exercise in day.exercises) {
          if (exercise.name.trim().isEmpty || exercise.sets.isEmpty) {
            return false;
          }
        }
      }
    }

    // 至少要有一个动作
    if (!hasAtLeastOneExercise) return false;

    // 不能在加载或AI生成中
    if (loadingStatus == LoadingStatus.loading) return false;
    if (aiStatus == AIGenerationStatus.generating) return false;

    return true;
  }

  /// 是否有未保存的更改
  bool get hasUnsavedChanges {
    return planName.isNotEmpty || days.isNotEmpty;
  }

  /// 获取当前选中的训练日
  ExerciseTrainingDay? get selectedDay {
    if (selectedDayIndex == null ||
        selectedDayIndex! < 0 ||
        selectedDayIndex! >= days.length) {
      return null;
    }
    return days[selectedDayIndex!];
  }

  /// 获取训练日总数
  int get totalDays => days.length;

  /// 获取所有动作总数
  int get totalExercises =>
      days.fold(0, (sum, day) => sum + day.totalExercises);

  /// 获取所有 Sets 总数
  int get totalSets => days.fold(0, (sum, day) => sum + day.totalSets);

  /// 是否正在加载
  bool get isLoading => loadingStatus == LoadingStatus.loading;

  /// 是否有错误
  bool get hasError =>
      loadingStatus == LoadingStatus.error || errorMessage != null;

  /// AI 是否正在生成
  bool get isAIGenerating => aiStatus == AIGenerationStatus.generating;

  /// 是否有 AI 建议
  bool get hasSuggestions => suggestions.isNotEmpty;

  /// 是否正在生成训练日
  bool get isGeneratingDay => currentDayInProgress != null;

  /// 当前训练日已生成的动作数
  int get currentDayExerciseCount =>
      currentDayInProgress?.exercises.length ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateTrainingPlanState &&
          runtimeType == other.runtimeType &&
          planName == other.planName &&
          description == other.description &&
          loadingStatus == other.loadingStatus &&
          aiStatus == other.aiStatus &&
          selectedDayIndex == other.selectedDayIndex &&
          selectedExerciseIndex == other.selectedExerciseIndex;

  @override
  int get hashCode =>
      planName.hashCode ^
      description.hashCode ^
      loadingStatus.hashCode ^
      aiStatus.hashCode ^
      selectedDayIndex.hashCode ^
      selectedExerciseIndex.hashCode;

  @override
  String toString() {
    return 'CreateTrainingPlanState('
        'planName: $planName, '
        'days: ${days.length}, '
        'loadingStatus: $loadingStatus, '
        'aiStatus: $aiStatus, '
        'canSave: $canSave)';
  }
}


