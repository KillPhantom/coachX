import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/cupertino_card.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import '../providers/coach_home_providers.dart';
import 'recent_activity_item.dart';

/// Recent Activity区域组件
///
/// 显示最近活跃的学生列表
class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
          ),
          child: Text(l10n.recentActivityTitle, style: AppTextStyles.title3),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: [
                for (final activity in activities)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.spacingM,
                    ),
                    child: RecentActivityItem(
                      activity: activity,
                      onTap: () {
                        // TODO: 跳转到学生详情页面
                        // 路由: /student-detail/${activity.studentId}
                        // 注意: StudentDetailPage 待后续实现
                        context.push('/student-detail/${activity.studentId}');
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spacingXXL),
              child: LoadingIndicator(),
            ),
          ),
          error: (error, stack) => ErrorView(
            error: error.toString(),
            onRetry: () => ref.invalidate(recentActivitiesProvider),
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return CupertinoCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXXL),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.person_2,
                size: 48.0,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                AppLocalizations.of(context)!.noRecentActivity,
                style: AppTextStyles.subhead.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
