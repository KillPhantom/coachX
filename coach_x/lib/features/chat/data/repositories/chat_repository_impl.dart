import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/data/models/conversation_model.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'chat_repository.dart';

/// Chat Repository 实现类
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl();

  @override
  Stream<List<ConversationModel>> watchConversations(
    String userId,
    UserRole role,
  ) {
    try {
      final fieldName = role == UserRole.coach ? 'coachId' : 'studentId';

      return FirestoreService.watchCollection(
        'conversations',
        where: [
          [fieldName, '==', userId],
        ],
        orderBy: 'lastMessageTime',
        descending: true,
      ).map((snapshot) {
        return snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听对话列表失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await FirestoreService.getDocument(
        'conversations',
        conversationId,
      );

      if (!doc.exists) {
        return null;
      }

      return ConversationModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error('获取对话失败: $conversationId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> getOrCreateConversation(
    String coachId,
    String studentId,
  ) async {
    try {
      final result = await CloudFunctionsService.call(
        'get_or_create_conversation',
        {'coachId': coachId, 'studentId': studentId},
      );

      final data = Map<String, dynamic>.from(result['data'] as Map);
      return data['conversationId'] as String;
    } catch (e, stackTrace) {
      AppLogger.error('获取或创建对话失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<MessageModel>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) {
    try {
      return FirestoreService.watchCollection(
        'messages',
        where: [
          ['conversationId', '==', conversationId],
        ],
        orderBy: 'createdAt',
        descending: true,
        limit: limit,
      ).map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听消息列表失败: $conversationId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String receiverId,
    required MessageType type,
    required String content,
    String? mediaUrl,
    MessageMetadata? mediaMetadata,
  }) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        throw Exception('用户未登录');
      }

      final result = await CloudFunctionsService.call('send_message', {
        'conversationId': conversationId,
        'receiverId': receiverId,
        'type': type.value,
        'content': content,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaMetadata != null) 'mediaMetadata': mediaMetadata.toJson(),
      });

      // 返回已发送的消息模型
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final messageId = data['messageId'] as String;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int,
      );

      return MessageModel(
        id: messageId,
        conversationId: conversationId,
        senderId: currentUserId,
        receiverId: receiverId,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        mediaMetadata: mediaMetadata,
        status: MessageStatus.sent,
        createdAt: createdAt,
      );
    } catch (e, stackTrace) {
      AppLogger.error('发送消息失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      await CloudFunctionsService.call('mark_messages_as_read', {
        'conversationId': conversationId,
        'lastReadTimestamp': DateTime.now().millisecondsSinceEpoch,
      });

      AppLogger.info('标记消息已读成功: $conversationId');
    } catch (e, stackTrace) {
      AppLogger.error('标记消息已读失败: $conversationId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<MessageModel>> fetchMoreMessages(
    String conversationId,
    DateTime beforeTimestamp, {
    int limit = 50,
  }) async {
    try {
      final result = await CloudFunctionsService.call('fetch_messages', {
        'conversationId': conversationId,
        'beforeTimestamp': beforeTimestamp.millisecondsSinceEpoch,
        'limit': limit,
      });

      final data = Map<String, dynamic>.from(result['data'] as Map);
      final messagesList = data['messages'] as List<dynamic>;
      return messagesList.map((data) {
        // 从JSON创建MessageModel（需要添加fromJson方法）
        return MessageModel(
          id: data['id'] as String,
          conversationId: data['conversationId'] as String,
          senderId: data['senderId'] as String,
          receiverId: data['receiverId'] as String,
          type: MessageType.fromString(data['type'] as String),
          content: data['content'] as String,
          mediaUrl: data['mediaUrl'] as String?,
          mediaMetadata: data['mediaMetadata'] != null
              ? MessageMetadata.fromJson(data['mediaMetadata'])
              : null,
          status: MessageStatus.fromString(data['status'] as String),
          isDeleted: data['isDeleted'] as bool? ?? false,
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
          readAt: data['readAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['readAt'])
              : null,
        );
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('加载更多消息失败: $conversationId', e, stackTrace);
      rethrow;
    }
  }
}
