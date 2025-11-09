import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import 'package:coach_x/features/student/home/presentation/providers/student_home_providers.dart';
import '../widgets/plan_tabs_view.dart';

/// 学生训练计划页面
///
/// 显示学生的训练、饮食、补剂计划，支持标签切换
class TrainingPage extends ConsumerWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(studentPlansProvider);

    // 刷新逻辑
    Future<void> handleRefresh() async {
      ref.invalidate(studentPlansProvider);
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
            },
          ),
          data: (plans) {
            return PlanTabsView(plans: plans, onRefresh: handleRefresh);
          },
        ),
      ),
    );
  }
}
