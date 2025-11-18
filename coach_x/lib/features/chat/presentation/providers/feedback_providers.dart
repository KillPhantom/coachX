import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';

// ==================== Search & Filter Providers ====================

/// 搜索关键词 Provider
final feedbackSearchQueryProvider = StateProvider<String>((ref) => '');

/// 日期范围筛选 Provider
final feedbackDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

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

/// 筛选后的 Feedback List Provider
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

      // 2. 获取搜索关键词
      final searchQuery = ref
          .watch(feedbackSearchQueryProvider)
          .trim()
          .toLowerCase();

      // 3. 获取日期范围
      final dateRange = ref.watch(feedbackDateRangeProvider);

      // 4. 应用过滤
      var filtered = feedbacks;

      // 4.1 搜索过滤（按 feedback 内容）
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((feedback) {
          final textContent = (feedback.textContent ?? '').toLowerCase();
          final exerciseName = (feedback.exerciseName ?? '').toLowerCase();

          return textContent.contains(searchQuery) ||
              exerciseName.contains(searchQuery);
        }).toList();
      }

      // 4.2 日期范围过滤
      if (dateRange != null) {
        filtered = filtered.where((feedback) {
          final feedbackDate = DateTime.parse(feedback.trainingDate);
          final startDate = DateTime(
            dateRange.start.year,
            dateRange.start.month,
            dateRange.start.day,
          );
          final endDate = DateTime(
            dateRange.end.year,
            dateRange.end.month,
            dateRange.end.day,
            23,
            59,
            59,
          );

          return feedbackDate.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              feedbackDate.isBefore(endDate.add(const Duration(seconds: 1)));
        }).toList();
      }

      // 5. 按日期降序排序（最新的在前）
      filtered.sort((a, b) => b.trainingDate.compareTo(a.trainingDate));

      return filtered;
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
