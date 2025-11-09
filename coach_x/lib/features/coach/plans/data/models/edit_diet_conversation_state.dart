import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// 饮食计划编辑对话状态
class EditDietConversationState {
  final DietPlanModel? currentPlan;
  final List<LLMChatMessage> messages;
  final bool isAIResponding;
  final DietPlanEditSuggestion? pendingSuggestion;
  final String? error;
  final DietPlanModel? previewPlan;
  final bool isPreviewMode;

  // 营养数据
  final Macros? currentTotalMacros;
  final Macros? previewTotalMacros;

  const EditDietConversationState({
    this.currentPlan,
    this.messages = const [],
    this.isAIResponding = false,
    this.pendingSuggestion,
    this.error,
    this.previewPlan,
    this.isPreviewMode = false,
    this.currentTotalMacros,
    this.previewTotalMacros,
  });

  /// 初始状态
  factory EditDietConversationState.initial({
    required DietPlanModel currentPlan,
  }) {
    return EditDietConversationState(
      currentPlan: currentPlan,
      messages: const [],
      isAIResponding: false,
      currentTotalMacros: calculatePlanMacros(currentPlan),
    );
  }

  /// 计算计划的总营养数据
  static Macros calculatePlanMacros(DietPlanModel plan) {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalCalories = 0;

    for (final day in plan.days) {
      for (final meal in day.meals) {
        for (final item in meal.items) {
          totalProtein += item.protein;
          totalCarbs += item.carbs;
          totalFat += item.fat;
          totalCalories += item.calories;
        }
      }
    }

    // 返回平均每天的营养数据
    final dayCount = plan.days.isNotEmpty ? plan.days.length : 1;
    return Macros(
      protein: totalProtein / dayCount,
      carbs: totalCarbs / dayCount,
      fat: totalFat / dayCount,
      calories: totalCalories / dayCount,
    );
  }

  /// 是否有待确认的建议
  bool get hasPendingSuggestion => pendingSuggestion != null;

  /// 是否可以发送消息
  bool get canSendMessage => !isAIResponding && !hasPendingSuggestion;

  /// 是否有错误
  bool get hasError => error != null;

  /// 添加消息
  EditDietConversationState addMessage(LLMChatMessage message) {
    return copyWith(messages: [...messages, message]);
  }

  /// 更新最后一条消息
  EditDietConversationState updateLastMessage(LLMChatMessage message) {
    if (messages.isEmpty) {
      return copyWith(messages: [message]);
    }

    final updatedMessages = [...messages];
    updatedMessages[updatedMessages.length - 1] = message;
    return copyWith(messages: updatedMessages);
  }

  /// 复制并修改
  EditDietConversationState copyWith({
    DietPlanModel? currentPlan,
    List<LLMChatMessage>? messages,
    bool? isAIResponding,
    DietPlanEditSuggestion? pendingSuggestion,
    String? error,
    DietPlanModel? previewPlan,
    bool? isPreviewMode,
    Macros? currentTotalMacros,
    Macros? previewTotalMacros,
    bool clearError = false,
    bool clearPreview = false,
    bool clearSuggestion = false,
  }) {
    return EditDietConversationState(
      currentPlan: currentPlan ?? this.currentPlan,
      messages: messages ?? this.messages,
      isAIResponding: isAIResponding ?? this.isAIResponding,
      pendingSuggestion: clearSuggestion
          ? null
          : (pendingSuggestion ?? this.pendingSuggestion),
      error: clearError ? null : (error ?? this.error),
      previewPlan: clearPreview ? null : (previewPlan ?? this.previewPlan),
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      currentTotalMacros: currentTotalMacros ?? this.currentTotalMacros,
      previewTotalMacros: previewTotalMacros ?? this.previewTotalMacros,
    );
  }

  @override
  String toString() {
    return 'EditDietConversationState(messages: ${messages.length}, isAIResponding: $isAIResponding, hasPendingSuggestion: $hasPendingSuggestion)';
  }
}
