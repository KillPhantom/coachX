import 'package:cloud_firestore/cloud_firestore.dart';

/// 消息类型枚举
enum MessageType {
  text,
  image,
  video,
  voice;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.voice:
        return 'voice';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }
}

/// 消息状态枚举
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get value {
    switch (this) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  static MessageStatus fromString(String value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }
}

/// 消息媒体元数据
class MessageMetadata {
  final String? fileName;
  final int? fileSize; // bytes
  final int? duration; // seconds
  final int? width;
  final int? height;
  final String? thumbnailUrl;

  const MessageMetadata({
    this.fileName,
    this.fileSize,
    this.duration,
    this.width,
    this.height,
    this.thumbnailUrl,
  });

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      duration: json['duration'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (fileName != null) json['fileName'] = fileName;
    if (fileSize != null) json['fileSize'] = fileSize;
    if (duration != null) json['duration'] = duration;
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (thumbnailUrl != null) json['thumbnailUrl'] = thumbnailUrl;
    return json;
  }
}

/// 消息模型
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final MessageMetadata? mediaMetadata;
  final MessageStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.mediaMetadata,
    this.status = MessageStatus.sent,
    this.isDeleted = false,
    required this.createdAt,
    this.readAt,
  });

  /// 解析Firestore时间戳字段（支持Timestamp和int类型）
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    // 如果是其他类型，返回默认值
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// 从Firestore文档创建
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Message document data is null');
    }

    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: MessageType.fromString(data['type'] as String? ?? 'text'),
      content: data['content'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaMetadata: data['mediaMetadata'] != null
          ? MessageMetadata.fromJson(data['mediaMetadata'] as Map<String, dynamic>)
          : null,
      status: MessageStatus.fromString(data['status'] as String? ?? 'sent'),
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      readAt: data['readAt'] != null ? _parseTimestamp(data['readAt']) : null,
    );
  }

  /// 转换为Firestore文档数据
  Map<String, dynamic> toFirestore() {
    final json = {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.value,
      'content': content,
      'status': status.value,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (mediaUrl != null) json['mediaUrl'] = mediaUrl!;
    if (mediaMetadata != null) json['mediaMetadata'] = mediaMetadata!.toJson();
    if (readAt != null) json['readAt'] = Timestamp.fromDate(readAt!);
    return json;
  }

  /// 判断是否由当前用户发送
  bool isSentBy(String userId) => senderId == userId;

  /// 复制并修改
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    String? mediaUrl,
    MessageMetadata? mediaMetadata,
    MessageStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
