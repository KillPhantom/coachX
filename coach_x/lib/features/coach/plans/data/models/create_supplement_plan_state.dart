import 'dart:convert';
import 'supplement_day.dart';

/// 创建/编辑补剂计划的状态模型
class CreateSupplementPlanState {
  final String? planId;
  final String planName;
  final String description;
  final List<SupplementDay> days;
  final bool isLoading;
  final bool isEditMode;
  final String? errorMessage;
  final List<String> validationErrors;

  /// 初始快照 - 用于判断是否有未保存的修改（编辑模式）
  final String? initialPlanName;
  final String? initialDescription;
  final String? initialDaysJson;

  const CreateSupplementPlanState({
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
  });

  /// 计算属性 - 是否可以保存
  bool get canSave =>
      planName.isNotEmpty &&
      days.isNotEmpty &&
      validationErrors.isEmpty &&
      !isLoading;

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

  /// 计算属性 - 总补剂数
  int get totalSupplements => days.fold(
    0,
    (sum, day) => sum + day.timings.fold(0, (s, t) => s + t.supplements.length),
  );

  /// 复制并修改部分字段
  CreateSupplementPlanState copyWith({
    String? planId,
    String? planName,
    String? description,
    List<SupplementDay>? days,
    bool? isLoading,
    bool? isEditMode,
    String? errorMessage,
    List<String>? validationErrors,
    String? initialPlanName,
    String? initialDescription,
    String? initialDaysJson,
  }) {
    return CreateSupplementPlanState(
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
    );
  }

  /// 清除错误消息
  CreateSupplementPlanState clearError() {
    return CreateSupplementPlanState(
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
      other is CreateSupplementPlanState &&
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
    return 'CreateSupplementPlanState(planId: $planId, planName: $planName, days: ${days.length}, isLoading: $isLoading, isEditMode: $isEditMode)';
  }
}
