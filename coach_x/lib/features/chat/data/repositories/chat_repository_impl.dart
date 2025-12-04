import 'dart:io';
import 'dart:typed_data';

import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/chat/data/models/conversation_model.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
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
        AppLogger.info('对话不存在，尝试创建: $conversationId');

        // 从 conversationId 解析 coachId 和 studentId
        // 格式: coach_{coachId}_student_{studentId}
        final parts = conversationId.split('_');
        if (parts.length == 4 && parts[0] == 'coach' && parts[2] == 'student') {
          final coachId = parts[1];
          final studentId = parts[3];

          AppLogger.info('解析 conversationId: coachId=$coachId, studentId=$studentId');

          try {
            // 调用 getOrCreateConversation 确保对话存在
            await getOrCreateConversation(coachId, studentId);
            AppLogger.info('对话创建成功，重新获取: $conversationId');

            // 重新获取对话
            final doc = await FirestoreService.getDocument(
              'conversations',
              conversationId,
            );

            if (!doc.exists) {
              AppLogger.warning('对话创建后仍不存在: $conversationId');
              return null;
            }

            return ConversationModel.fromFirestore(doc);
          } catch (fallbackError, fallbackStackTrace) {
            AppLogger.error('创建对话失败: $conversationId', fallbackError, fallbackStackTrace);
            rethrow;
          }
        } else {
          AppLogger.warning('conversationId 格式不正确，无法自动创建: $conversationId');
          return null;
        }
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
    String? quotedMessageId,
    String? quotedMessageContent,
    String? quotedMessageSenderId,
    String? quotedMessageSenderName,
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
        if (quotedMessageId != null) 'quotedMessageId': quotedMessageId,
        if (quotedMessageContent != null)
          'quotedMessageContent': quotedMessageContent,
        if (quotedMessageSenderId != null)
          'quotedMessageSenderId': quotedMessageSenderId,
        if (quotedMessageSenderName != null)
          'quotedMessageSenderName': quotedMessageSenderName,
      });

      // 临时调试日志
      AppLogger.info('=== send_message 响应 ===');
      AppLogger.info('result: ${result.toString()}');
      AppLogger.info('result[\'data\']: ${result['data'].toString()}');
      AppLogger.info('result[\'data\'] type: ${result['data'].runtimeType}');

      // 返回已发送的消息模型
      // 使用 safeMapCast 处理嵌套 Map
      final data = safeMapCast(result['data'], 'send_message.data');
      if (data == null) {
        throw Exception('send_message 返回数据格式错误');
      }

      final messageId = data['messageId'] as String;

      // 使用 safeIntCast 处理时间戳
      final createdAtTimestamp =
          safeIntCast(data['createdAt'], 0, 'createdAt') ?? 0;
      if (createdAtTimestamp == 0) {
        AppLogger.warning('⚠️ createdAt 解析失败，使用当前时间');
      }
      final createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtTimestamp);

      // Patch: 确保引用字段被保存到Firestore
      // 如果云函数没有保存这些字段（可能是因为 schema 限制），我们需要手动更新
      if (quotedMessageId != null) {
        try {
          await FirestoreService.updateDocument(
            'messages',
            messageId,
            {
              'quotedMessageId': quotedMessageId,
              if (quotedMessageContent != null)
                'quotedMessageContent': quotedMessageContent,
              if (quotedMessageSenderId != null)
                'quotedMessageSenderId': quotedMessageSenderId,
              if (quotedMessageSenderName != null)
                'quotedMessageSenderName': quotedMessageSenderName,
            },
          );
          AppLogger.info('手动更新引用消息字段成功: $messageId');
        } catch (e) {
          AppLogger.error('手动更新引用消息字段失败: $messageId', e);
          // 不抛出异常，以免影响发送流程
        }
      }

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
        quotedMessageId: quotedMessageId,
        quotedMessageContent: quotedMessageContent,
        quotedMessageSenderId: quotedMessageSenderId,
        quotedMessageSenderName: quotedMessageSenderName,
      );
    } catch (e, stackTrace) {
      AppLogger.error('发送消息失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await CloudFunctionsService.call('delete_message', {
        'conversationId': conversationId,
        'messageId': messageId,
      });

      AppLogger.info('删除消息成功: $messageId');
    } catch (e, stackTrace) {
      AppLogger.error('删除消息失败: $messageId', e, stackTrace);
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

  @override
  Future<String> uploadMediaFile({
    required String filePath,
    required String conversationId,
    required String mediaType,
  }) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) throw Exception('用户未登录');

      final file = File(filePath);
      if (!file.existsSync()) throw Exception('文件不存在');

      final extension = path.extension(filePath);
      final fileName = '${const Uuid().v4()}$extension';
      final storagePath =
          'chat_media/$conversationId/$mediaType/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      return await StorageService.uploadFile(
        file: file,
        storagePath: storagePath,
        metadata: {
          'senderId': currentUserId,
          'mediaType': mediaType,
          'conversationId': conversationId,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('上传媒体文件失败: $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadMediaBytes({
    required Uint8List bytes,
    required String conversationId,
    required String mediaType,
  }) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) throw Exception('用户未登录');

      final fileName = '${const Uuid().v4()}.jpg'; // 假设图片是jpg
      final storagePath =
          'chat_media/$conversationId/$mediaType/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      return await StorageService.uploadData(
        data: bytes,
        storagePath: storagePath,
        metadata: {
          'senderId': currentUserId,
          'mediaType': mediaType,
          'conversationId': conversationId,
          'contentType': 'image/jpeg',
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('上传媒体数据失败', e, stackTrace);
      rethrow;
    }
  }
}
