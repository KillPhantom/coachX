import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/training_reviews/presentation/providers/training_review_providers.dart';
import '../widgets/summary_section.dart';
import '../widgets/event_reminder_section.dart';
import '../widgets/pending_reviews_section.dart';
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
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 内容区域
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                // 刷新所有数据
                ref.invalidate(coachSummaryProvider);
                ref.invalidate(eventRemindersProvider);
                ref.invalidate(trainingReviewsStreamProvider);
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

                  // Upcoming Schedule区域
                  const EventReminderSection(),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Pending Reviews区域
                  const PendingReviewsSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
