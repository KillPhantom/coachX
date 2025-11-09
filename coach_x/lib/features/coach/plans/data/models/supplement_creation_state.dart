import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';

/// 选择步骤枚举
enum SelectionStep {
  training, // 正在选择训练计划
  diet, // 正在选择饮食计划
}

/// 补剂计划创建状态
class SupplementCreationState {
  final List<LLMChatMessage> messages;
  final bool isAIResponding;
  final SupplementDay? pendingSuggestion;
  final String? errorMessage;
  final bool canSendMessage;

  // 多步选择状态
  final SelectionStep? currentSelectionStep;
  final String? selectedTrainingPlanId;
  final String? selectedDietPlanId;
  final String? selectedTrainingPlanName;
  final String? selectedDietPlanName;

  const SupplementCreationState({
    this.messages = const [],
    this.isAIResponding = false,
    this.pendingSuggestion,
    this.errorMessage,
    this.canSendMessage = true,
    this.currentSelectionStep,
    this.selectedTrainingPlanId,
    this.selectedDietPlanId,
    this.selectedTrainingPlanName,
    this.selectedDietPlanName,
  });

  SupplementCreationState copyWith({
    List<LLMChatMessage>? messages,
    bool? isAIResponding,
    SupplementDay? pendingSuggestion,
    bool clearPendingSuggestion = false,
    String? errorMessage,
    bool? canSendMessage,
    SelectionStep? currentSelectionStep,
    String? selectedTrainingPlanId,
    String? selectedDietPlanId,
    String? selectedTrainingPlanName,
    String? selectedDietPlanName,
  }) {
    return SupplementCreationState(
      messages: messages ?? this.messages,
      isAIResponding: isAIResponding ?? this.isAIResponding,
      pendingSuggestion: clearPendingSuggestion
          ? null
          : (pendingSuggestion ?? this.pendingSuggestion),
      errorMessage: errorMessage ?? this.errorMessage,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      currentSelectionStep: currentSelectionStep ?? this.currentSelectionStep,
      selectedTrainingPlanId:
          selectedTrainingPlanId ?? this.selectedTrainingPlanId,
      selectedDietPlanId: selectedDietPlanId ?? this.selectedDietPlanId,
      selectedTrainingPlanName:
          selectedTrainingPlanName ?? this.selectedTrainingPlanName,
      selectedDietPlanName: selectedDietPlanName ?? this.selectedDietPlanName,
    );
  }
}
