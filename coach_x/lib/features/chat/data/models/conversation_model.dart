import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'last_message.dart';

/// 对话模型
class ConversationModel {
  final String id;
  final String coachId;
  final String studentId;
  final LastMessage? lastMessage;
  final DateTime lastMessageTime;
  final int coachUnreadCount;
  final int studentUnreadCount;
  final DateTime coachLastReadTime;
  final DateTime studentLastReadTime;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final bool isArchived;
  final bool isPinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ConversationModel({
    required this.id,
    required this.coachId,
    required this.studentId,
    this.lastMessage,
    required this.lastMessageTime,
    this.coachUnreadCount = 0,
    this.studentUnreadCount = 0,
    required this.coachLastReadTime,
    required this.studentLastReadTime,
    required this.participantNames,
    required this.participantAvatars,
    this.isArchived = false,
    this.isPinned = false,
    this.createdAt,
    this.updatedAt,
  });

  /// 从Firestore文档创建
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Conversation document data is null');
    }

    return ConversationModel(
      id: doc.id,
      coachId: data['coachId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromJson(data['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: _parseTimestamp(data['lastMessageTime']),
      coachUnreadCount: data['coachUnreadCount'] as int? ?? 0,
      studentUnreadCount: data['studentUnreadCount'] as int? ?? 0,
      coachLastReadTime: _parseTimestamp(data['coachLastReadTime']),
      studentLastReadTime: _parseTimestamp(data['studentLastReadTime']),
      participantNames: Map<String, String>.from(
        data['participantNames'] as Map? ?? {},
      ),
      participantAvatars: Map<String, String>.from(
        data['participantAvatars'] as Map? ?? {},
      ),
      isArchived: data['isArchived'] as bool? ?? false,
      isPinned: data['isPinned'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

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

  /// 转换为Firestore文档数据
  Map<String, dynamic> toFirestore() {
    final json = {
      'coachId': coachId,
      'studentId': studentId,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'coachUnreadCount': coachUnreadCount,
      'studentUnreadCount': studentUnreadCount,
      'coachLastReadTime': coachLastReadTime.millisecondsSinceEpoch,
      'studentLastReadTime': studentLastReadTime.millisecondsSinceEpoch,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'isArchived': isArchived,
      'isPinned': isPinned,
    };
    if (lastMessage != null) {
      json['lastMessage'] = lastMessage!.toJson();
    }
    return json;
  }

  /// 获取对方用户ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == coachId ? studentId : coachId;
  }

  /// 获取对方用户名称
  String getOtherUserName(String currentUserId) {
    if (currentUserId == coachId) {
      return participantNames['studentName'] ?? '';
    } else {
      return participantNames['coachName'] ?? '';
    }
  }

  /// 获取对方用户头像
  String? getOtherUserAvatar(String currentUserId) {
    if (currentUserId == coachId) {
      return participantAvatars['studentAvatarUrl'];
    } else {
      return participantAvatars['coachAvatarUrl'];
    }
  }

  /// 获取当前用户的未读数
  int getUnreadCount(String currentUserId) {
    return currentUserId == coachId ? coachUnreadCount : studentUnreadCount;
  }

  /// 获取当前用户角色的未读数
  int getUnreadCountByRole(UserRole role) {
    return role == UserRole.coach ? coachUnreadCount : studentUnreadCount;
  }

  /// 生成对话ID
  static String generateId(String coachId, String studentId) {
    return 'coach_${coachId}_student_$studentId';
  }

  /// 复制并修改
  ConversationModel copyWith({
    String? id,
    String? coachId,
    String? studentId,
    LastMessage? lastMessage,
    DateTime? lastMessageTime,
    int? coachUnreadCount,
    int? studentUnreadCount,
    DateTime? coachLastReadTime,
    DateTime? studentLastReadTime,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    bool? isArchived,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      studentId: studentId ?? this.studentId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      coachUnreadCount: coachUnreadCount ?? this.coachUnreadCount,
      studentUnreadCount: studentUnreadCount ?? this.studentUnreadCount,
      coachLastReadTime: coachLastReadTime ?? this.coachLastReadTime,
      studentLastReadTime: studentLastReadTime ?? this.studentLastReadTime,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
