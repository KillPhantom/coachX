import 'dart:typed_data';

import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/features/chat/data/models/conversation_model.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';

/// Chat Repository 抽象接口
abstract class ChatRepository {
  /// 监听用户的对话列表
  Stream<List<ConversationModel>> watchConversations(
    String userId,
    UserRole role,
  );

  /// 获取单个对话
  Future<ConversationModel?> getConversation(String conversationId);

  /// 获取或创建对话
  Future<String> getOrCreateConversation(String coachId, String studentId);

  /// 监听对话消息列表
  Stream<List<MessageModel>> watchMessages(
    String conversationId, {
    int limit = 50,
  });

  /// 发送消息
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String receiverId,
    required MessageType type,
    required String content,
    String? mediaUrl,
    MessageMetadata? mediaMetadata,
    String? quotedMessageId,
    String? quotedMessageContent,
    String? quotedMessageSenderId,
    String? quotedMessageSenderName,
  });

  /// 删除消息（软删除）
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  });

  /// 标记消息为已读
  Future<void> markMessagesAsRead(String conversationId, String userId);

  /// 加载更多历史消息
  Future<List<MessageModel>> fetchMoreMessages(
    String conversationId,
    DateTime beforeTimestamp, {
    int limit = 50,
  });

  /// 上传媒体文件（文件路径）
  /// [mediaType] 媒体类型：'voice', 'image', 'video', 'video_thumbnail'
  Future<String> uploadMediaFile({
    required String filePath,
    required String conversationId,
    required String mediaType,
  });

  /// 上传媒体文件（字节数据）
  /// [mediaType] 媒体类型：'image'
  Future<String> uploadMediaBytes({
    required Uint8List bytes,
    required String conversationId,
    required String mediaType,
  });
}
