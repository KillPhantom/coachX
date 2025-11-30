import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';

// ==================== Sort Provider ====================

/// 排序顺序 Provider
/// true = 降序（最新的在前）, false = 升序（最旧的在前）
final feedbackSortOrderProvider = StateProvider<bool>((ref) => true);

/// 搜索关键字 Provider（按会话隔离）
final feedbackSearchQueryProvider =
    StateProvider.family<String, String>((ref, conversationId) => '');

// ==================== Data Providers ====================

/// Feedback Stream Provider
/// 从 conversationId 获取 coachId + studentId，然后监听 feedbacks
final feedbacksStreamProvider =
    StreamProvider.family<
      List<TrainingFeedbackModel>,
      String // conversationId
    >((ref, conversationId) async* {
      // 1. 获取 conversation 详情
      final conversationAsync = await ref.watch(
        conversationDetailProvider(conversationId).future,
      );

      if (conversationAsync == null) {
        yield [];
        return;
      }

      // 2. 提取 coachId 和 studentId
      final coachId = conversationAsync.coachId;
      final studentId = conversationAsync.studentId;

      // 3. 获取 repository
      final repository = ref.read(feedbackRepositoryProvider);

      // 4. 监听 feedbacks
      yield* repository.watchFeedbacks(studentId: studentId, coachId: coachId);
    });

/// 排序后的 Feedback List Provider
final filteredFeedbacksProvider =
    Provider.family<
      List<TrainingFeedbackModel>,
      String // conversationId
    >((ref, conversationId) {
      // 1. 获取原始列表
      final feedbacksAsync = ref.watch(feedbacksStreamProvider(conversationId));

      final feedbacks = feedbacksAsync.when(
        data: (data) => data,
        loading: () => <TrainingFeedbackModel>[],
        error: (_, __) => <TrainingFeedbackModel>[],
      );

      // 2. 获取排序顺序
      final isDescending = ref.watch(feedbackSortOrderProvider);
      final searchQuery =
          ref.watch(feedbackSearchQueryProvider(conversationId)).trim().toLowerCase();

      // 3. 复制列表并排序
      final sorted = List<TrainingFeedbackModel>.from(feedbacks);
      sorted.sort((a, b) {
        return isDescending
            ? b.trainingDate.compareTo(a.trainingDate)
            : a.trainingDate.compareTo(b.trainingDate);
      });

      if (searchQuery.isEmpty) {
        return sorted;
      }

      return sorted.where((feedback) {
        final exerciseName = feedback.exerciseName?.toLowerCase() ?? '';
        final textContent = feedback.textContent?.toLowerCase() ?? '';
        return exerciseName.contains(searchQuery) ||
            textContent.contains(searchQuery);
      }).toList();
    });

/// 按日期分组的 Provider
final groupedFeedbacksProvider =
    Provider.family<
      Map<String, List<TrainingFeedbackModel>>,
      String // conversationId
    >((ref, conversationId) {
      // 1. 获取筛选后的列表
      final feedbacks = ref.watch(filteredFeedbacksProvider(conversationId));

      // 2. 按日期分组
      final Map<String, List<TrainingFeedbackModel>> grouped = {};

      for (final feedback in feedbacks) {
        final dateLabel = _getDateGroupLabel(
          DateTime.parse(feedback.trainingDate),
        );

        if (!grouped.containsKey(dateLabel)) {
          grouped[dateLabel] = [];
        }

        grouped[dateLabel]!.add(feedback);
      }

      // 3. 返回分组结果（保持插入顺序）
      return grouped;
    });

// ==================== Helper Functions ====================

/// 获取日期分组标签
///
/// Returns:
/// - "Today" for today's date
/// - "Yesterday" for yesterday's date
/// - "MMMM d" format for other dates (e.g., "October 26")
String _getDateGroupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final targetDate = DateTime(date.year, date.month, date.day);

  if (targetDate == today) {
    return "Today";
  }

  if (targetDate == yesterday) {
    return "Yesterday";
  }

  return DateFormat('MMMM d').format(date);
}
