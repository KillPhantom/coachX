import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../widgets/summary_section.dart';
import '../widgets/event_reminder_section.dart';
import '../widgets/recent_activity_section.dart';
import '../providers/coach_home_providers.dart';

/// 教练首页
///
/// 显示教练的首页信息，包括：
/// - Summary统计信息
/// - Event Reminder事件提醒
/// - Recent Activity最近活跃学生
class CoachHomePage extends ConsumerWidget {
  const CoachHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Home'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // TODO: 打开设置页面
            // 路由: /coach/settings
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('TODO: 设置'),
                content: const Text('设置页面待实现'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('知道了'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
          child: const Icon(CupertinoIcons.settings),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 内容区域
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                // 刷新所有数据
                ref.invalidate(coachSummaryProvider);
                ref.invalidate(eventRemindersProvider);
                ref.invalidate(recentActivitiesProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingL,
                AppDimensions.spacingL,
                AppDimensions.spacingL,
                AppDimensions.spacingXXXL,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Summary区域
                  const SummarySection(),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Event Reminder区域
                  const EventReminderSection(),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Recent Activity区域
                  const RecentActivitySection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
