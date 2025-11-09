import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import '../providers/student_home_providers.dart';
import '../widgets/weekly_status_section.dart';
import '../widgets/today_record_section.dart';
import '../widgets/today_supplement_section.dart';
import '../widgets/today_training_plan_section.dart';
import '../widgets/empty_plan_placeholder.dart';

/// 学生首页
///
/// 显示学生的训练打卡状态、今日记录和训练计划
class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(studentPlansProvider);

    // 刷新逻辑
    Future<void> handleRefresh() async {
      ref.invalidate(studentPlansProvider);
      ref.invalidate(latestTrainingProvider);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return CupertinoPageScaffold(
      child: SafeArea(
        child: plansAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) => ErrorView(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(studentPlansProvider);
              ref.invalidate(latestTrainingProvider);
            },
          ),
          data: (plans) {
            // 如果没有任何计划，显示空状态
            if (plans.hasNoPlan) {
              return EmptyPlanPlaceholder(onRefresh: handleRefresh);
            }

            // 有计划，显示完整首页
            return CustomScrollView(
              slivers: [
                // 下拉刷新
                CupertinoSliverRefreshControl(onRefresh: handleRefresh),

                // 内容区域
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spacingL,
                    AppDimensions.spacingL,
                    AppDimensions.spacingL,
                    AppDimensions.spacingXXXL,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Weekly Status
                      const WeeklyStatusSection(),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Today's Meal Plan
                      const TodayRecordSection(),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Today's Supplement Plan
                      const TodaySupplementSection(),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Today's Training Plan
                      const TodayTrainingPlanSection(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
