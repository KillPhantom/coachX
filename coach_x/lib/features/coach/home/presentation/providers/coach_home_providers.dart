import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import '../../data/models/coach_summary_model.dart';
import '../../data/models/event_reminder_model.dart';
import '../../data/models/recent_activity_model.dart';

/// 当前教练ID Provider
final currentCoachIdProvider = Provider<String?>((ref) {
  return AuthService.currentUserId;
});

/// Coach Summary Provider
///
/// 提供教练首页的统计信息
final coachSummaryProvider = FutureProvider<CoachSummaryModel>((ref) async {
  // TODO: 替换为真实API调用
  // 调用 Cloud Function: fetchStudentsStats()
  // 整合未读消息统计和待审核训练数
  //
  // 示例API调用:
  // final response = await CloudFunctionsService.call('fetchStudentsStats');
  // return CoachSummaryModel.fromJson(response);

  // Mock数据
  await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟

  return CoachSummaryModel(
    studentsCompletedToday: 15,
    totalStudents: 25,
    unreadMessages: 20,
    unreviewedTrainings: 14,
    lastUpdated: DateTime.now(),
  );
});

/// Event Reminders Provider
///
/// 提供Event Reminder列表
final eventRemindersProvider = FutureProvider<List<EventReminderModel>>((
  ref,
) async {
  final coachId = ref.watch(currentCoachIdProvider);

  if (coachId == null) {
    return [];
  }

  // TODO: 替换为Firestore实时监听
  // Collection: eventReminders
  // Query: where('coachId', '==', currentCoachId)
  //        .where('isCompleted', '==', false)
  //        .orderBy('scheduledTime')
  //        .limit(3)
  //
  // 示例实现:
  // return FirebaseFirestore.instance
  //     .collection('eventReminders')
  //     .where('coachId', isEqualTo: coachId)
  //     .where('isCompleted', isEqualTo: false)
  //     .orderBy('scheduledTime')
  //     .limit(3)
  //     .snapshots()
  //     .map((snapshot) => snapshot.docs
  //         .map((doc) => EventReminderModel.fromFirestore(doc))
  //         .toList());

  // Mock数据
  await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟

  return [
    EventReminderModel(
      id: '1',
      type: EventReminderType.offlineClass,
      title: 'Offline class with student X tomorrow 9:00 AM',
      scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 9)),
      coachId: coachId,
      createdAt: DateTime.now(),
      isCompleted: false,
    ),
    EventReminderModel(
      id: '2',
      type: EventReminderType.therapySession,
      title: 'Therapy session on 10/02/2025 for massage',
      description: 'Regular massage therapy session',
      scheduledTime: DateTime(2025, 10, 2, 14, 0),
      location: 'Massage Center',
      coachId: coachId,
      createdAt: DateTime.now(),
      isCompleted: false,
    ),
  ];
});

/// Recent Activities Provider
///
/// 提供Recent Activity列表
final recentActivitiesProvider = FutureProvider<List<RecentActivityModel>>((
  ref,
) async {
  // TODO: 替换为真实数据查询
  // 需要聚合多个数据源:
  // 1. 最近训练记录 (dailyTraining)
  // 2. 最近消息 (messages)
  // 3. 最近打卡 (checkIns)
  // 按时间排序，取最近3条
  //
  // 示例实现思路:
  // 1. 查询教练的所有学生
  // 2. 查询这些学生的最近活动（训练、消息、打卡）
  // 3. 聚合排序，取最新的3条
  // 4. 转换为RecentActivityModel

  // Mock数据
  await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟

  return [
    RecentActivityModel(
      studentId: 's1',
      studentName: 'Liam Carter',
      avatarUrl: null,
      lastActiveTime: DateTime.now().subtract(const Duration(hours: 2)),
      activityType: 'training',
      activityDescription: 'Completed training',
    ),
    RecentActivityModel(
      studentId: 's2',
      studentName: 'Sophia Bennett',
      avatarUrl: null,
      lastActiveTime: DateTime.now().subtract(const Duration(days: 1)),
      activityType: 'message',
      activityDescription: 'Sent a message',
    ),
    RecentActivityModel(
      studentId: 's3',
      studentName: 'Ethan Harper',
      avatarUrl: null,
      lastActiveTime: DateTime.now().subtract(const Duration(days: 2)),
      activityType: 'checkin',
      activityDescription: 'Daily check-in',
    ),
  ];
});
