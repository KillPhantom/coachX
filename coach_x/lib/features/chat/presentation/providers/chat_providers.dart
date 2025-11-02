import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/features/chat/data/repositories/chat_repository.dart';
import 'package:coach_x/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:coach_x/features/chat/data/models/conversation_model.dart';
import 'package:coach_x/features/chat/data/models/last_message.dart';
import 'package:coach_x/features/coach/students/data/repositories/student_repository.dart';
import 'package:coach_x/features/coach/students/data/repositories/student_repository_impl.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository_impl.dart';
import 'package:coach_x/app/providers.dart';

// ==================== Repository Providers ====================

/// Chat Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl();
});

/// Student Repository Provider (用于获取学生列表)
final _studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepositoryImpl();
});

/// User Repository Provider (用于获取用户信息)
final _userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

// ==================== Data Models ====================

/// 对话列表项模型
/// 用于在对话列表页面显示
class ConversationItem {
  /// 对方用户ID（学生或教练）
  final String userId;

  /// 对方用户姓名
  final String userName;

  /// 对方用户头像URL
  final String? avatarUrl;

  /// 对话ID（可能为空，表示还未创建对话）
  final String? conversationId;

  /// 最后一条消息（可能为空）
  final LastMessage? lastMessage;

  /// 未读消息数
  final int unreadCount;

  /// 最后消息时间戳（用于排序）
  final int lastMessageTime;

  const ConversationItem({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.conversationId,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageTime = 0,
  });

  /// 复制并修改
  ConversationItem copyWith({
    String? userId,
    String? userName,
    String? avatarUrl,
    String? conversationId,
    LastMessage? lastMessage,
    int? unreadCount,
    int? lastMessageTime,
  }) {
    return ConversationItem(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      conversationId: conversationId ?? this.conversationId,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}

// ==================== Providers ====================

/// 对话列表Provider
/// 根据当前用户角色加载对话列表
final conversationItemsProvider =
    FutureProvider.autoDispose<List<ConversationItem>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;

  // 如果用户未登录，返回空列表
  if (currentUser == null) {
    return [];
  }

  final chatRepository = ref.read(chatRepositoryProvider);
  final userId = currentUser.id;
  final userRole = currentUser.role;

  // 根据用户角色加载对话列表
  if (userRole.isCoach) {
    // 教练端：从学生列表生成对话列表
    return _loadCoachConversations(
      userId,
      chatRepository,
      ref.read(_studentRepositoryProvider),
    );
  } else {
    // 学生端：显示与教练的对话
    return _loadStudentConversations(
      userId,
      currentUser.coachId,
      chatRepository,
      ref.read(_userRepositoryProvider),
    );
  }
});

/// 加载教练端对话列表
Future<List<ConversationItem>> _loadCoachConversations(
  String coachId,
  ChatRepository chatRepository,
  StudentRepository studentRepository,
) async {
  // 获取所有学生列表（限制为100个学生）
  // 性能优化：Chat功能不需要计划信息，设置includePlans=false
  final studentsResult = await studentRepository.fetchStudents(
    pageSize: 100, // 最大页面尺寸（后端限制）
    pageNumber: 1,
    includePlans: false, // 不查询计划信息，避免额外数据库查询
  );

  final students = studentsResult.students;
  final items = <ConversationItem>[];

  // 为每个学生创建对话项
  for (final student in students) {
    // 构建对话ID
    final conversationId = 'coach_${coachId}_student_${student.id}';

    // 尝试获取对话
    final conversation = await chatRepository.getConversation(conversationId);

    items.add(ConversationItem(
      userId: student.id,
      userName: student.name,
      avatarUrl: student.avatarUrl,
      conversationId: conversation?.id,
      lastMessage: conversation?.lastMessage,
      unreadCount: conversation?.getUnreadCount(coachId) ?? 0,
      lastMessageTime: conversation?.lastMessageTime.millisecondsSinceEpoch ?? 0,
    ));
  }

  // 按最后消息时间排序（最新的在前）
  items.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

  return items;
}

/// 加载学生端对话列表
Future<List<ConversationItem>> _loadStudentConversations(
  String studentId,
  String? coachId,
  ChatRepository chatRepository,
  UserRepository userRepository,
) async {
  // 如果没有教练，返回空列表
  if (coachId == null || coachId.isEmpty) {
    return [];
  }

  // 获取教练信息
  final coach = await userRepository.getUser(coachId);
  if (coach == null) {
    return [];
  }

  // 构建对话ID
  final conversationId = 'coach_${coachId}_student_$studentId';

  // 尝试获取对话
  final conversation = await chatRepository.getConversation(conversationId);

  return [
    ConversationItem(
      userId: coachId,
      userName: coach.name,
      avatarUrl: coach.avatarUrl,
      conversationId: conversation?.id,
      lastMessage: conversation?.lastMessage,
      unreadCount: conversation?.getUnreadCount(studentId) ?? 0,
      lastMessageTime: conversation?.lastMessageTime.millisecondsSinceEpoch ?? 0,
    ),
  ];
}

/// 单个对话Provider (Family)
/// 用于获取或创建对话
final conversationProvider =
    FutureProvider.autoDispose.family<ConversationModel?, String>(
  (ref, otherUserId) async {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) {
      return null;
    }

    final chatRepository = ref.read(chatRepositoryProvider);
    final currentUserId = currentUser.id;
    final userRole = currentUser.role;

    // 根据角色确定coachId和studentId
    String coachId;
    String studentId;

    if (userRole.isCoach) {
      coachId = currentUserId;
      studentId = otherUserId;
    } else {
      coachId = otherUserId;
      studentId = currentUserId;
    }

    // 获取或创建对话
    final conversationId =
        await chatRepository.getOrCreateConversation(coachId, studentId);

    // 返回对话详情
    return chatRepository.getConversation(conversationId);
  },
);
