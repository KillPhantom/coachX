import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/edit_conversation_state.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'edit_conversation_notifier.dart';

// ==================== 主状态 Provider ====================

/// 编辑对话 Notifier Provider
final editConversationNotifierProvider =
    StateNotifierProvider.autoDispose<
      EditConversationNotifier,
      EditConversationState
    >((ref) {
      return EditConversationNotifier();
    });

// ==================== 计算 Providers ====================

/// 对话消息列表 Provider
final messagesProvider = Provider.autoDispose<List<LLMChatMessage>>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.messages;
});

/// AI 是否正在响应 Provider
final isAIRespondingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.isAIResponding;
});

/// 待确认的修改建议 Provider
final pendingSuggestionProvider = Provider.autoDispose<PlanEditSuggestion?>((
  ref,
) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.pendingSuggestion;
});

/// 当前计划 Provider
final currentEditPlanProvider = Provider.autoDispose<ExercisePlanModel?>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.currentPlan;
});

/// 预览计划 Provider
final previewPlanProvider = Provider.autoDispose<ExercisePlanModel?>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.previewPlan;
});

/// 是否处于预览模式 Provider
final isPreviewModeProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.isPreviewMode;
});

/// 错误信息 Provider
final editErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.error;
});

/// 是否有待确认的建议 Provider
final hasPendingSuggestionProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.hasPendingSuggestion;
});

/// 是否可以发送消息 Provider
final canSendMessageProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.canSendMessage;
});

/// 是否有错误 Provider
final hasEditErrorProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.hasError;
});

/// 消息数量 Provider
final messageCountProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(editConversationNotifierProvider);
  return state.messages.length;
});
