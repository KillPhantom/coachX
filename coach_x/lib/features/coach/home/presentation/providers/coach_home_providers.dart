import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/features/coach/training_reviews/data/models/training_review_list_item_model.dart';
import 'package:coach_x/features/coach/training_reviews/presentation/providers/training_review_providers.dart';
import '../../data/models/coach_summary_model.dart';
import '../../data/models/event_reminder_model.dart';

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
  // 整合未读消息统计和待审核训练数（过去30天）
  //
  // 示例API调用:
  // final response = await CloudFunctionsService.call('fetchStudentsStats');
  // return CoachSummaryModel.fromJson(response);

  // Mock数据
  await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟

  return CoachSummaryModel(
    studentsCompletedLast30Days: 20,
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

/// Top 5 Pending Reviews Provider
///
/// 提供最新的5条待审核训练记录
final top5PendingReviewsProvider = Provider<List<TrainingReviewListItemModel>>((
  ref,
) {
  // 获取所有筛选后的训练审核记录
  final allReviews = ref.watch(filteredTrainingReviewsProvider);

  // 过滤出未审核的记录
  final pendingReviews = allReviews
      .where((review) => !review.isReviewed)
      .toList();

  // 按创建时间降序排序
  pendingReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // 取前5条
  return pendingReviews.take(5).toList();
});
