import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/cupertino_card.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import '../providers/coach_home_providers.dart';
import 'summary_item.dart';

/// Summary区域组件
///
/// 显示教练首页的统计信息，包括：
/// - 学生完成训练统计
/// - 未读消息数
/// - 待审核训练记录数
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
          Text(l10n.coachHomeSummaryTitle, style: AppTextStyles.title3),
          const SizedBox(height: AppDimensions.spacingL),
          summaryAsync.when(
            data: (summary) => Column(
              children: [
                SummaryItem(
                  icon: CupertinoIcons.sportscourt,
                  text: '${summary.completionRate} students completed training today',
                  onTap: () {
                    // TODO: 跳转到学生列表（筛选已完成）
                    // 路由: /coach/students?filter=completed_today
                    _showTodoAlert(context, '跳转到学生列表', '显示今天完成训练的学生列表');
                  },
                ),
                _buildDivider(),
                SummaryItem(
                  icon: CupertinoIcons.envelope_badge,
                  text: '${summary.unreadMessages} unread messages',
                  onTap: () {
                    // TODO: 跳转到Chat Tab
                    // 可以通过改变Tab索引或使用go_router导航
                    _showTodoAlert(context, '跳转到Chat', '打开Chat Tab查看未读消息');
                  },
                ),
                _buildDivider(),
                SummaryItem(
                  icon: CupertinoIcons.star,
                  text: '${summary.unreviewedTrainings} training records need to be reviewed',
                  onTap: () {
                    // TODO: 跳转到待审核训练记录列表
                    // 路由: /coach/training-reviews
                    _showTodoAlert(context, '跳转到待审核列表', '显示需要审核的训练记录');
                  },
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

  /// 构建分割线
  Widget _buildDivider() {
    return Container(height: 0.5, color: AppColors.dividerLight);
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
            child: Text(l10n.know),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
