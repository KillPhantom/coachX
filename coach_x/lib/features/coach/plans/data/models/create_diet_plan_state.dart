import 'diet_day.dart';

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

  const CreateDietPlanState({
    this.planId,
    this.planName = '',
    this.description = '',
    this.days = const [],
    this.isLoading = false,
    this.isEditMode = false,
    this.errorMessage,
    this.validationErrors = const [],
  });

  /// 计算属性 - 是否可以保存
  bool get canSave => planName.isNotEmpty && days.isNotEmpty && !isLoading;

  /// 计算属性 - 是否有未保存的更改
  bool get hasUnsavedChanges => true; // 简化实现，总是返回 true

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
