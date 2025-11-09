import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/edit_diet_conversation_state.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'edit_diet_conversation_notifier.dart';

// ==================== 主状态 Provider ====================

/// 饮食计划编辑对话 Notifier Provider
final editDietConversationNotifierProvider =
    StateNotifierProvider.autoDispose<
      EditDietConversationNotifier,
      EditDietConversationState
    >((ref) {
      return EditDietConversationNotifier();
    });

// ==================== 计算 Providers ====================

/// 对话消息列表 Provider
final dietMessagesProvider = Provider.autoDispose<List<LLMChatMessage>>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.messages;
});

/// AI 是否正在响应 Provider
final isDietAIRespondingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.isAIResponding;
});

/// 待确认的修改建议 Provider
final pendingDietSuggestionProvider =
    Provider.autoDispose<DietPlanEditSuggestion?>((ref) {
      final state = ref.watch(editDietConversationNotifierProvider);
      return state.pendingSuggestion;
    });

/// 当前计划 Provider
final currentEditDietPlanProvider = Provider.autoDispose<DietPlanModel?>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.currentPlan;
});

/// 预览计划 Provider
final previewDietPlanProvider = Provider.autoDispose<DietPlanModel?>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.previewPlan;
});

/// 是否处于预览模式 Provider
final isPreviewDietModeProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.isPreviewMode;
});

/// 错误信息 Provider
final editDietErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.error;
});

/// 是否有待确认的建议 Provider
final hasPendingDietSuggestionProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.hasPendingSuggestion;
});

/// 是否可以发送消息 Provider
final canSendDietMessageProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.canSendMessage;
});

/// 是否有错误 Provider
final hasEditDietErrorProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.hasError;
});

/// 消息数量 Provider
final dietMessageCountProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.messages.length;
});

/// 当前营养数据 Provider
final currentDietMacrosProvider = Provider.autoDispose<Macros?>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.currentTotalMacros;
});

/// 预览营养数据 Provider
final previewDietMacrosProvider = Provider.autoDispose<Macros?>((ref) {
  final state = ref.watch(editDietConversationNotifierProvider);
  return state.previewTotalMacros;
});
