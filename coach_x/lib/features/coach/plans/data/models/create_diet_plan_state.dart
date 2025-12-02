import 'dart:convert';
import 'package:coach_x/core/enums/ai_status.dart';
import 'diet_day.dart';
import 'diet_plan_import_stats.dart';

/// 创建/编辑饮食计划的状态模型
class CreateDietPlanState {
  final String? planId;
  final String planName;
  final String description;
  final List<DietDay> days;
  final bool isLoading;
  final bool isEditMode;
  final String? errorMessage;
  final List<String> validationErrors;

  /// 初始快照 - 用于判断是否有未保存的修改（编辑模式）
  final String? initialPlanName;
  final String? initialDescription;
  final String? initialDaysJson;

  /// AI 流式生成相关字段
  final DietPlanImportStats? dietStreamingStats;
  final int currentStep; // 当前步骤 (1-4)
  final double currentStepProgress; // 当前步骤进度 (0-100)
  final DietDay? currentDayInProgress; // 正在生成的天
  final AIGenerationStatus aiStatus; // AI 生成状态

  const CreateDietPlanState({
    this.planId,
    this.planName = '',
    this.description = '',
    this.days = const [],
    this.isLoading = false,
    this.isEditMode = false,
    this.errorMessage,
    this.validationErrors = const [],
    this.initialPlanName,
    this.initialDescription,
    this.initialDaysJson,
    this.dietStreamingStats,
    this.currentStep = 0,
    this.currentStepProgress = 0.0,
    this.currentDayInProgress,
    this.aiStatus = AIGenerationStatus.idle,
  });

  /// 计算属性 - 是否可以保存
  bool get canSave => planName.isNotEmpty && days.isNotEmpty && !isLoading;

  /// 计算属性 - 是否有未保存的更改
  bool get hasUnsavedChanges {
    // 快照未设置，表示刚初始化还没保存快照
    if (initialDaysJson == null) {
      return false;
    }

    // 对比初始快照
    if (planName != (initialPlanName ?? '')) return true;
    if (description != (initialDescription ?? '')) return true;

    // 深度对比 days（通过 JSON 序列化）
    final currentDaysJson = jsonEncode(days.map((d) => d.toJson()).toList());
    return currentDaysJson != initialDaysJson;
  }

  /// 计算属性 - 总天数
  int get totalDays => days.length;

  /// 计算属性 - 总餐次数
  int get totalMeals => days.fold(0, (sum, day) => sum + day.meals.length);

  /// 计算属性 - 总食物条目数
  int get totalFoodItems => days.fold(
    0,
    (sum, day) =>
        sum + day.meals.fold(0, (mealSum, meal) => mealSum + meal.items.length),
  );

  /// 复制并修改部分字段
  CreateDietPlanState copyWith({
    String? planId,
    String? planName,
    String? description,
    List<DietDay>? days,
    bool? isLoading,
    bool? isEditMode,
    String? errorMessage,
    List<String>? validationErrors,
    String? initialPlanName,
    String? initialDescription,
    String? initialDaysJson,
    DietPlanImportStats? dietStreamingStats,
    int? currentStep,
    double? currentStepProgress,
    DietDay? currentDayInProgress,
    AIGenerationStatus? aiStatus,
  }) {
    return CreateDietPlanState(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      isEditMode: isEditMode ?? this.isEditMode,
      errorMessage: errorMessage ?? this.errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
      initialPlanName: initialPlanName ?? this.initialPlanName,
      initialDescription: initialDescription ?? this.initialDescription,
      initialDaysJson: initialDaysJson ?? this.initialDaysJson,
      dietStreamingStats: dietStreamingStats ?? this.dietStreamingStats,
      currentStep: currentStep ?? this.currentStep,
      currentStepProgress: currentStepProgress ?? this.currentStepProgress,
      currentDayInProgress: currentDayInProgress ?? this.currentDayInProgress,
      aiStatus: aiStatus ?? this.aiStatus,
    );
  }

  /// 清除错误消息
  CreateDietPlanState clearError() {
    return CreateDietPlanState(
      planId: planId,
      planName: planName,
      description: description,
      days: days,
      isLoading: isLoading,
      isEditMode: isEditMode,
      errorMessage: null,
      validationErrors: const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateDietPlanState &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          planName == other.planName &&
          description == other.description &&
          days == other.days &&
          isLoading == other.isLoading &&
          isEditMode == other.isEditMode &&
          errorMessage == other.errorMessage &&
          validationErrors == other.validationErrors;

  @override
  int get hashCode =>
      planId.hashCode ^
      planName.hashCode ^
      description.hashCode ^
      days.hashCode ^
      isLoading.hashCode ^
      isEditMode.hashCode ^
      errorMessage.hashCode ^
      validationErrors.hashCode;

  @override
  String toString() {
    return 'CreateDietPlanState(planId: $planId, planName: $planName, days: ${days.length}, isLoading: $isLoading, isEditMode: $isEditMode)';
  }
}
