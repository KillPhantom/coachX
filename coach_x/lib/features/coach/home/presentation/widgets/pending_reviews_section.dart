import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/features/coach/training_reviews/presentation/widgets/training_review_card.dart';
import '../providers/coach_home_providers.dart';

/// Pending Reviews区域组件
///
/// 显示最新的5条待审核训练记录
class PendingReviewsSection extends ConsumerWidget {
  const PendingReviewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pendingReviews = ref.watch(top5PendingReviewsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section标题行 - 标题 + View All按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.pendingReviewsTitle, style: AppTextStyles.bodyMedium),
            if (pendingReviews.isNotEmpty)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  context.push(RouteNames.coachTrainingReviews);
                }, minimumSize: Size(0, 0),
                child: Text(
                  l10n.viewAll,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),

        // 列表内容
        if (pendingReviews.isEmpty)
          _buildEmptyState(context)
        else
          // 训练审核卡片列表
          for (final review in pendingReviews)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              child: TrainingReviewCard(item: review),
            ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXXL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_shield,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.noPendingReviews,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              l10n.noPendingReviewsDesc,
              style: AppTextStyles.subhead.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
