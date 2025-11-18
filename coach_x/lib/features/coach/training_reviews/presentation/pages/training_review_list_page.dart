import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../providers/training_review_providers.dart';
import '../widgets/training_review_card.dart';
import '../widgets/training_review_filter_bar.dart';

/// 训练审核列表页面
///
/// 显示教练需要审核的所有学生训练记录
class TrainingReviewListPage extends ConsumerWidget {
  const TrainingReviewListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reviewsAsync = ref.watch(trainingReviewsStreamProvider);
    final filteredReviews = ref.watch(filteredTrainingReviewsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(
            CupertinoIcons.back,
            size: 28,
            color: AppColors.textPrimary,
          ),
        ),
        middle: Text(l10n.trainingReviews, style: AppTextStyles.navTitle),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索和筛选栏
            const TrainingReviewFilterBar(),

            // 训练记录列表
            Expanded(
              child: reviewsAsync.when(
                data: (_) => _buildReviewList(context, filteredReviews),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(context, ref, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建训练记录列表
  Widget _buildReviewList(BuildContext context, List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // 刷新数据
            final container = ProviderScope.containerOf(context);
            container.invalidate(trainingReviewsStreamProvider);
            // 等待一小段时间让数据刷新
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return TrainingReviewCard(item: reviews[index]);
            }, childCount: reviews.length),
          ),
        ),
      ],
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(child: LoadingIndicator());
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load reviews',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                // 重新加载
                ref.invalidate(trainingReviewsStreamProvider);
              },
              child: Text(
                'Retry',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // 刷新数据
            final container = ProviderScope.containerOf(context);
            container.invalidate(trainingReviewsStreamProvider);
            // 等待一小段时间让数据刷新
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.tray,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTrainingReviews,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noTrainingReviewsDesc,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
