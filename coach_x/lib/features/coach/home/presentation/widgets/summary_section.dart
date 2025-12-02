import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/cupertino_card.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import 'package:coach_x/routes/route_names.dart';
import '../providers/coach_home_providers.dart';
import 'package:flutter/material.dart' show Icons;

/// Summary区域组件
///
/// 显示教练首页的统计信息，包括：
/// - 过去30天学生完成训练统计
/// - 待审核训练记录数
/// - 未读消息数
class SummarySection extends ConsumerWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(coachSummaryProvider);

    return CupertinoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.coachHomeSummaryTitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.spacingL),
          summaryAsync.when(
            data: (summary) => Row(
              children: [
                // 第1列：本周学生打卡次数
                Expanded(
                  child: _StatColumn(
                    icon: Icons.fitness_center,
                    value: '${summary.studentCheckInsLast7Days}',
                    label: l10n.recordTraining,
                    onTap: () => context.push(RouteNames.coachStudents),
                  ),
                ),
                // 第2列：待审核训练记录数
                Expanded(
                  child: _StatColumn(
                    icon: CupertinoIcons.star,
                    value: '${summary.unreviewedTrainings}',
                    label: l10n.recordsToReview,
                    onTap: () {
                      context.push(RouteNames.coachTrainingReviews);
                    },
                  ),
                ),
                // 第3列：未读消息
                Expanded(
                  child: _StatColumn(
                    icon: CupertinoIcons.envelope_badge,
                    value: '${summary.unreadMessages}',
                    label: l10n.unreadMessagesLabel,
                    onTap: () {
                      // TODO: 跳转到Chat Tab
                      _showTodoAlert(context, '跳转到Chat', '打开Chat Tab查看未读消息');
                    },
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacingXXL),
                child: LoadingIndicator(),
              ),
            ),
            error: (error, stack) => ErrorView(
              error: error.toString(),
              onRetry: () => ref.invalidate(coachSummaryProvider),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示TODO提示
  void _showTodoAlert(BuildContext context, String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('TODO: $title'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.know, style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// 统计列组件
///
/// 用于显示单个统计项，包括图标、数值和标签
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          Icon(icon, size: 28, color: AppColors.primaryAction),
          const SizedBox(height: AppDimensions.spacingS),
          // 数值
          Text(
            value,
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          // 标签
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
