import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/coach_summary_model.dart';
import 'coach_home_repository.dart';

/// Coach Home Repository实现
///
/// 直接查询Firestore获取教练首页统计数据
class CoachHomeRepositoryImpl implements CoachHomeRepository {
  final FirebaseFirestore _firestore;

  CoachHomeRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<CoachSummaryModel> fetchCoachSummary(String coachId) async {
    try {
      AppLogger.info('开始获取教练首页统计数据: coachId=$coachId');

      // 计算7天前的日期（基于用户时区）
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final sevenDaysAgoDateStr = _formatDate(sevenDaysAgo);

      AppLogger.info('计算日期范围: sevenDaysAgo=$sevenDaysAgoDateStr, now=${_formatDate(now)}');

      // 并行查询三个统计数据
      final results = await Future.wait([
        _getCheckInsLast7Days(coachId, sevenDaysAgoDateStr),
        _getUnreviewedTrainingsCount(coachId),
        _getUnreadMessagesCount(coachId),
      ]);

      final checkInsCount = results[0] as int;
      final unreviewedCount = results[1] as int;
      final unreadCount = results[2] as int;

      AppLogger.info(
        '统计数据获取完成: checkIns=$checkInsCount, unreviewed=$unreviewedCount, unread=$unreadCount',
      );

      return CoachSummaryModel(
        studentCheckInsLast7Days: checkInsCount,
        unreviewedTrainings: unreviewedCount,
        unreadMessages: unreadCount,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取教练首页统计数据失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取最近7天学生打卡次数
  Future<int> _getCheckInsLast7Days(String coachId, String sevenDaysAgo) async {
    try {
      final snapshot = await _firestore
          .collection('dailyTrainings')
          .where('coachID', isEqualTo: coachId)
          .where('date', isGreaterThanOrEqualTo: sevenDaysAgo)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('查询最近7天打卡次数失败', e);
      return 0;
    }
  }

  /// 获取待审核训练记录数
  Future<int> _getUnreviewedTrainingsCount(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('dailyTrainings')
          .where('coachID', isEqualTo: coachId)
          .where('isReviewed', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('查询待审核训练记录数失败', e);
      return 0;
    }
  }

  /// 获取未读消息数
  Future<int> _getUnreadMessagesCount(String coachId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('coachId', isEqualTo: coachId)
          .get();

      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final coachUnreadCount = data['coachUnreadCount'] as int? ?? 0;
        totalUnread += coachUnreadCount;
      }

      return totalUnread;
    } catch (e) {
      AppLogger.error('查询未读消息数失败', e);
      return 0;
    }
  }

  /// 格式化日期为字符串（YYYY-MM-DD）
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
