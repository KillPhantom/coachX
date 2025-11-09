import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_creation_state.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';
import 'package:coach_x/features/coach/plans/data/repositories/supplement_plan_repository.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/supplement_conversation_notifier.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_supplement_plan_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/plans_providers.dart';

/// 补剂对话状态 Provider
final supplementConversationNotifierProvider =
    StateNotifierProvider<
      SupplementConversationNotifier,
      SupplementCreationState
    >((ref) {
      final supplementRepo = ref.watch(supplementPlanRepositoryProvider);
      final planRepo = ref.watch(planRepositoryProvider);
      final createNotifier = ref.watch(
        createSupplementPlanNotifierProvider.notifier,
      );
      return SupplementConversationNotifier(
        supplementRepo,
        planRepo,
        createNotifier,
      );
    });

/// 补剂对话消息列表 Provider
final supplementMessagesProvider = Provider<List<LLMChatMessage>>((ref) {
  return ref.watch(supplementConversationNotifierProvider).messages;
});

/// 是否正在AI响应中 Provider
final isSupplementAIRespondingProvider = Provider<bool>((ref) {
  return ref.watch(supplementConversationNotifierProvider).isAIResponding;
});

/// 待处理的补剂建议 Provider
final pendingSupplementSuggestionProvider = Provider<SupplementDay?>((ref) {
  return ref.watch(supplementConversationNotifierProvider).pendingSuggestion;
});

/// 是否可以发送消息 Provider
final canSendSupplementMessageProvider = Provider<bool>((ref) {
  return ref.watch(supplementConversationNotifierProvider).canSendMessage;
});
