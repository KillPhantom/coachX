import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/features/chat/data/models/conversation_model.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';

/// Chat Repository 抽象接口
abstract class ChatRepository {
  /// 监听用户的对话列表
  ///
  /// [userId] 用户ID
  /// [role] 用户角色（教练或学生）
  /// 返回实时更新的对话列表流
  Stream<List<ConversationModel>> watchConversations(
    String userId,
    UserRole role,
  );

  /// 获取单个对话
  ///
  /// [conversationId] 对话ID
  /// 返回对话模型，不存在返回null
  Future<ConversationModel?> getConversation(String conversationId);

  /// 获取或创建对话
  ///
  /// [coachId] 教练ID
  /// [studentId] 学生ID
  /// 返回对话ID
  Future<String> getOrCreateConversation(String coachId, String studentId);

  /// 监听对话消息列表
  ///
  /// [conversationId] 对话ID
  /// [limit] 限制数量，默认50条
  /// 返回实时更新的消息列表流（按时间降序）
  Stream<List<MessageModel>> watchMessages(
    String conversationId, {
    int limit = 50,
  });

  /// 发送消息
  ///
  /// [conversationId] 对话ID
  /// [receiverId] 接收者ID
  /// [type] 消息类型
  /// [content] 消息内容
  /// [mediaUrl] 媒体URL（可选）
  /// [mediaMetadata] 媒体元数据（可选）
  /// 返回发送的消息模型
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String receiverId,
    required MessageType type,
    required String content,
    String? mediaUrl,
    MessageMetadata? mediaMetadata,
  });

  /// 标记消息为已读
  ///
  /// [conversationId] 对话ID
  /// [userId] 当前用户ID
  /// 返回操作是否成功
  Future<void> markMessagesAsRead(String conversationId, String userId);

  /// 加载更多历史消息
  ///
  /// [conversationId] 对话ID
  /// [beforeTimestamp] 在此时间之前的消息
  /// [limit] 限制数量
  /// 返回消息列表
  Future<List<MessageModel>> fetchMoreMessages(
    String conversationId,
    DateTime beforeTimestamp, {
    int limit = 50,
  });
}
