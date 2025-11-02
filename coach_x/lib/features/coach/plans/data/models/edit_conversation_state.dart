import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';

/// 编辑会话状态
class EditConversationState {
  final List<LLMChatMessage> messages; // 对话消息列表
  final bool isAIResponding; // AI 是否正在响应
  final PlanEditSuggestion? pendingSuggestion; // 待确认的修改建议
  final ExercisePlanModel? currentPlan; // 当前计划
  final ExercisePlanModel? previewPlan; // 预览修改后的计划
  final String? error; // 错误信息
  final bool isPreviewMode; // 是否处于预览模式

  const EditConversationState({
    this.messages = const [],
    this.isAIResponding = false,
    this.pendingSuggestion,
    this.currentPlan,
    this.previewPlan,
    this.error,
    this.isPreviewMode = false,
  });

  /// 初始状态
  factory EditConversationState.initial({
    ExercisePlanModel? currentPlan,
  }) {
    return EditConversationState(
      currentPlan: currentPlan,
    );
  }

  /// 复制并修改
  EditConversationState copyWith({
    List<LLMChatMessage>? messages,
    bool? isAIResponding,
    PlanEditSuggestion? pendingSuggestion,
    ExercisePlanModel? currentPlan,
    ExercisePlanModel? previewPlan,
    String? error,
    bool? isPreviewMode,
    bool clearPendingSuggestion = false,
    bool clearPreviewPlan = false,
    bool clearError = false,
  }) {
    return EditConversationState(
      messages: messages ?? this.messages,
      isAIResponding: isAIResponding ?? this.isAIResponding,
      pendingSuggestion: clearPendingSuggestion ? null : (pendingSuggestion ?? this.pendingSuggestion),
      currentPlan: currentPlan ?? this.currentPlan,
      previewPlan: clearPreviewPlan ? null : (previewPlan ?? this.previewPlan),
      error: clearError ? null : (error ?? this.error),
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
    );
  }

  /// 添加消息
  EditConversationState addMessage(LLMChatMessage message) {
    return copyWith(
      messages: [...messages, message],
    );
  }

  /// 更新最后一条消息
  EditConversationState updateLastMessage(LLMChatMessage message) {
    if (messages.isEmpty) {
      return addMessage(message);
    }

    final updatedMessages = List<LLMChatMessage>.from(messages);
    updatedMessages[updatedMessages.length - 1] = message;

    return copyWith(messages: updatedMessages);
  }

  /// 追加内容到最后一条消息
  EditConversationState appendToLastMessage(String content) {
    if (messages.isEmpty) {
      return this;
    }

    final lastMessage = messages.last;
    final updatedMessage = lastMessage.copyWith(
      content: lastMessage.content + content,
    );

    return updateLastMessage(updatedMessage);
  }

  /// 清空对话
  EditConversationState clearConversation() {
    return copyWith(
      messages: [],
      clearPendingSuggestion: true,
      clearPreviewPlan: true,
      clearError: true,
      isAIResponding: false,
      isPreviewMode: false,
    );
  }

  /// 是否有待确认的建议
  bool get hasPendingSuggestion => pendingSuggestion != null;

  /// 是否有预览计划
  bool get hasPreviewPlan => previewPlan != null;

  /// 是否有错误
  bool get hasError => error != null && error!.isNotEmpty;

  /// 是否可以发送消息
  bool get canSendMessage => !isAIResponding && currentPlan != null;

  @override
  String toString() {
    return 'EditConversationState(messages: ${messages.length}, isAIResponding: $isAIResponding, hasPendingSuggestion: $hasPendingSuggestion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditConversationState &&
        other.messages == messages &&
        other.isAIResponding == isAIResponding &&
        other.pendingSuggestion == pendingSuggestion &&
        other.currentPlan == currentPlan &&
        other.previewPlan == previewPlan &&
        other.error == error &&
        other.isPreviewMode == isPreviewMode;
  }

  @override
  int get hashCode {
    return messages.hashCode ^
        isAIResponding.hashCode ^
        pendingSuggestion.hashCode ^
        currentPlan.hashCode ^
        previewPlan.hashCode ^
        error.hashCode ^
        isPreviewMode.hashCode;
  }
}

