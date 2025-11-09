import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 无计划占位符
///
/// 当学生没有被分配任何计划时显示
class EmptyPlanPlaceholder extends StatelessWidget {
  const EmptyPlanPlaceholder({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        // 下拉刷新
        CupertinoSliverRefreshControl(onRefresh: onRefresh),

        // 空状态内容
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  Text(
                    l10n.noPlanAssigned,
                    style: AppTextStyles.title3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    l10n.contactCoachForPlan,
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                  CupertinoButton.filled(
                    onPressed: () {
                      // 导航到学生计划页面
                      context.go('/student/plan');
                    },
                    child: Text(
                      l10n.viewAvailablePlans,
                      style: AppTextStyles.buttonMedium,
                    ),
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
