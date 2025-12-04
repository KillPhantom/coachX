import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AI 对话状态
class AIChatState {
  final List<MessageModel> messages;
  final bool isGenerating;
  final String? error;

  const AIChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.error,
  });

  AIChatState copyWith({
    List<MessageModel>? messages,
    bool? isGenerating,
    String? error,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

/// AI 对话控制器
class AIChatController extends StateNotifier<AIChatState> {
  AIChatController() : super(const AIChatState());

  final _uuid = const Uuid();
  StreamSubscription? _subscription;

  /// 发送消息
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    // 使用固定的 AI ID
    const aiId = 'ai_coach';

    // 1. 添加用户消息
    final userMessage = MessageModel(
      id: _uuid.v4(),
      conversationId: 'ai_chat_$userId',
      senderId: userId,
      receiverId: aiId,
      type: MessageType.text,
      content: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isGenerating: true,
      error: null,
    );

    // 2. 创建 AI 响应占位消息
    final aiMessageId = _uuid.v4();
    final aiMessage = MessageModel(
      id: aiMessageId,
      conversationId: 'ai_chat_$userId',
      senderId: aiId,
      receiverId: userId,
      type: MessageType.text,
      content: '', // 初始为空，等待流式更新
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...state.messages, aiMessage],
    );

    // 3. 开始流式请求
    try {
      _subscription?.cancel();
      _subscription = AIService.chatWithAI(userMessage: text).listen(
        (event) {
          _handleStreamEvent(event, aiMessageId);
        },
        onError: (error) {
          AppLogger.error('AI Chat Error', error);
          state = state.copyWith(
            isGenerating: false,
            error: error.toString(),
          );
          _updateMessageStatus(aiMessageId, MessageStatus.failed);
        },
        onDone: () {
          state = state.copyWith(isGenerating: false);
          _updateMessageStatus(aiMessageId, MessageStatus.delivered);
        },
      );
    } catch (e) {
      AppLogger.error('Start AI Chat Error', e);
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
      _updateMessageStatus(aiMessageId, MessageStatus.failed);
    }
  }

  /// 处理流式事件
  void _handleStreamEvent(Map<String, dynamic> event, String messageId) {
    final type = event['type'] as String?;

    if (type == 'text_delta') {
      final content = event['content'] as String?;
      if (content != null) {
        _appendMessageContent(messageId, content);
      }
    } else if (type == 'error') {
      final error = event['error'] as String?;
      state = state.copyWith(
        isGenerating: false,
        error: error,
      );
      _updateMessageStatus(messageId, MessageStatus.failed);
    } else if (type == 'complete') {
      state = state.copyWith(isGenerating: false);
      _updateMessageStatus(messageId, MessageStatus.delivered);
    }
  }

  /// 追加消息内容
  void _appendMessageContent(String messageId, String delta) {
    state = state.copyWith(
      messages: state.messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(
            content: msg.content + delta,
            status: MessageStatus.sending, // 保持 sending 状态直到完成
          );
        }
        return msg;
      }).toList(),
    );
  }

  /// 更新消息状态
  void _updateMessageStatus(String messageId, MessageStatus status) {
    state = state.copyWith(
      messages: state.messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(status: status);
        }
        return msg;
      }).toList(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider
final aiChatControllerProvider =
    StateNotifierProvider.autoDispose<AIChatController, AIChatState>((ref) {
  return AIChatController();
});

