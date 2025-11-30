import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/cache/user_avatar_cache_service.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:coach_x/features/chat/data/models/conversation_model.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_providers.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository_impl.dart';
import 'package:coach_x/app/providers.dart';

// ==================== Enums ====================

/// Tab 枚举
enum ChatDetailTab { chat, feedback }

// ==================== State Classes ====================

/// 媒体上传进度状态
class MediaUploadProgress {
  final bool isUploading;
  final double progress; // 0.0 - 1.0
  final String? error;

  const MediaUploadProgress({
    this.isUploading = false,
    this.progress = 0.0,
    this.error,
  });

  MediaUploadProgress copyWith({
    bool? isUploading,
    double? progress,
    String? error,
  }) {
    return MediaUploadProgress(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

// ==================== Providers ====================

/// 当前选中的 Tab Provider
final selectedChatTabProvider = StateProvider.autoDispose<ChatDetailTab>((ref) {
  return ChatDetailTab.chat;
});

/// 对话详情 Provider
/// 根据 conversationId 获取对话详情
final conversationDetailProvider = FutureProvider.autoDispose
    .family<ConversationModel?, String>((ref, conversationId) async {
      final chatRepository = ref.read(chatRepositoryProvider);
      return chatRepository.getConversation(conversationId);
    });

/// 对方用户信息 Provider
/// 根据 conversationId 获取对方用户的最新信息（包括头像）
final otherUserProvider = FutureProvider.autoDispose
    .family<UserModel?, String>((ref, conversationId) async {
      // 获取对话信息
      final conversation = await ref.watch(conversationDetailProvider(conversationId).future);
      if (conversation == null) return null;

      // 获取当前用户
      final currentUser = ref.watch(currentUserProvider).value;
      if (currentUser == null) return null;

      // 确定对方用户ID
      final otherUserId = currentUser.id == conversation.coachId
          ? conversation.studentId
          : conversation.coachId;

      // 获取对方用户信息
      final userRepository = UserRepositoryImpl();
      return userRepository.getUser(otherUserId);
    });

/// 消息列表 Stream Provider
/// 监听指定对话的实时消息流
final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, conversationId) {
      final chatRepository = ref.read(chatRepositoryProvider);
      return chatRepository.watchMessages(conversationId, limit: 50);
    });

/// 媒体上传进度 Provider
final mediaUploadProgressProvider =
    StateProvider.autoDispose<MediaUploadProgress>((ref) {
      return const MediaUploadProgress();
    });

/// 消息输入框文本 Provider
final messageInputTextProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

/// 是否正在加载更多消息 Provider
final isLoadingMoreMessagesProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// AI 面板显示状态 Provider
final showAIPanelProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// 消息发送状态 Provider
final isSendingMessageProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// 当前引用的消息 Provider
final quotedMessageProvider = StateProvider.autoDispose<MessageModel?>((ref) {
  return null;
});

/// 对方用户头像URL Provider（带缓存）
///
/// 根据 conversationId 获取对方用户的缓存头像URL
final otherUserAvatarUrlProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, conversationId) async {
      // 获取对话信息
      final conversation = await ref.watch(conversationDetailProvider(conversationId).future);
      if (conversation == null) return null;

      // 获取当前用户
      final currentUser = ref.watch(currentUserProvider).value;
      if (currentUser == null) return null;

      // 确定对方用户ID
      final otherUserId = currentUser.id == conversation.coachId
          ? conversation.studentId
          : conversation.coachId;

      // 从缓存获取头像URL
      return await UserAvatarCacheService.getAvatarUrl(otherUserId);
    });

/// 强制刷新对方用户头像
///
/// 用于下拉刷新时调用
Future<void> forceRefreshOtherUserAvatar(String otherUserId) async {
  await UserAvatarCacheService.forceRefreshAvatar(otherUserId);
}
