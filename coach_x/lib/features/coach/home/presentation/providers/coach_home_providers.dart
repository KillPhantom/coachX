import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/features/coach/training_reviews/data/models/training_review_list_item_model.dart';
import 'package:coach_x/features/coach/training_reviews/presentation/providers/training_review_providers.dart';
import '../../data/models/coach_summary_model.dart';
import '../../data/repositories/coach_home_repository.dart';
import '../../data/repositories/coach_home_repository_impl.dart';

/// 当前教练ID Provider
final currentCoachIdProvider = Provider<String?>((ref) {
  return AuthService.currentUserId;
});

/// Coach Home Repository Provider
final coachHomeRepositoryProvider = Provider<CoachHomeRepository>((ref) {
  return CoachHomeRepositoryImpl();
});

/// Coach Summary Provider
///
/// 提供教练首页的统计信息
/// 缓存1小时后自动失效
final coachSummaryProvider =
    FutureProvider.autoDispose<CoachSummaryModel>((ref) async {
  // 保持缓存1小时
  final link = ref.keepAlive();

  // 1小时后自动失效
  Timer(const Duration(hours: 1), () {
    link.close();
  });

  final coachId = ref.watch(currentCoachIdProvider);

  if (coachId == null) {
    throw Exception('教练ID不存在');
  }

  final repository = ref.watch(coachHomeRepositoryProvider);
  return repository.fetchCoachSummary(coachId);
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
