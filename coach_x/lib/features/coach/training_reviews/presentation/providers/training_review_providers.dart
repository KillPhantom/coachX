import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../../data/models/training_review_list_item_model.dart';
import '../../data/repositories/training_review_repository.dart';
import '../../data/repositories/training_review_repository_impl.dart';

// ==================== Repository Provider ====================

/// Training Review Repository Provider
final trainingReviewRepositoryProvider = Provider<TrainingReviewRepository>((
  ref,
) {
  return TrainingReviewRepositoryImpl();
});

// ==================== Search & Filter Providers ====================

/// 搜索关键词 Provider（按学生姓名搜索）
final reviewSearchQueryProvider = StateProvider<String>((ref) => '');

/// 审核状态筛选 Provider
/// null = All, true = Reviewed, false = Pending
final reviewStatusFilterProvider = StateProvider<bool?>((ref) => null);

// ==================== Data Providers ====================

/// Training Reviews Stream Provider
/// 从 Firestore 实时监听训练审核列表
final trainingReviewsStreamProvider =
    StreamProvider<List<TrainingReviewListItemModel>>((ref) {
      final coachId = AuthService.currentUserId;
      AppLogger.info(
        '🔍 [TrainingReview] Provider initialized, coachId: $coachId',
      );

      if (coachId == null) {
        AppLogger.warning(
          '🔍 [TrainingReview] coachId is null, returning empty stream',
        );
        return Stream.value([]);
      }

      AppLogger.info(
        '🔍 [TrainingReview] Starting to watch training reviews for coach: $coachId',
      );
      final repository = ref.read(trainingReviewRepositoryProvider);
      return repository.watchTrainingReviews(coachId);
    });

/// 筛选后的 Training Reviews Provider
/// 应用搜索和状态过滤
final filteredTrainingReviewsProvider =
    Provider<List<TrainingReviewListItemModel>>((ref) {
      // 1. 获取原始数据流
      final reviewsAsync = ref.watch(trainingReviewsStreamProvider);

      final reviews = reviewsAsync.when(
        data: (data) => data,
        loading: () => <TrainingReviewListItemModel>[],
        error: (_, __) => <TrainingReviewListItemModel>[],
      );

      // 2. 获取搜索关键词
      final searchQuery = ref
          .watch(reviewSearchQueryProvider)
          .trim()
          .toLowerCase();

      // 3. 获取状态筛选
      final statusFilter = ref.watch(reviewStatusFilterProvider);

      // 4. 应用过滤
      var filtered = reviews;

      // 4.1 搜索过滤（按学生姓名）
      if (searchQuery.isNotEmpty) {
        filtered = filtered
            .where((r) => r.studentName.toLowerCase().contains(searchQuery))
            .toList();
      }

      // 4.2 状态过滤
      if (statusFilter != null) {
        filtered = filtered.where((r) => r.isReviewed == statusFilter).toList();
      }

      // 5. 按日期降序排序（最新的在前）
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return filtered;
    });
