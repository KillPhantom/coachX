import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import '../providers/student_detail_providers.dart';
import '../widgets/student_profile_section.dart';
import '../widgets/student_weight_chart.dart';
import '../widgets/student_history_section.dart';

/// 学生详情页面（教练视角）
class StudentDetailPage extends ConsumerWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final studentDetailAsync = ref.watch(studentDetailProvider(studentId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
        middle: Text(l10n.studentDetailTitle, style: AppTextStyles.navTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
      ),
      child: studentDetailAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorView(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(studentDetailProvider(studentId));
          },
        ),
        data: (studentDetail) {
          return CustomScrollView(
            slivers: [
              // 刷新控制
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(studentDetailProvider(studentId));
                },
              ),

              // Profile Section
              SliverToBoxAdapter(
                child: StudentProfileSection(
                  basicInfo: studentDetail.basicInfo,
                  plans: studentDetail.plans,
                  stats: studentDetail.stats,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Weight Chart
              SliverToBoxAdapter(
                child: StudentWeightChart(studentId: studentId),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Training History
              SliverToBoxAdapter(
                child: StudentHistorySection(
                  recentTrainings: studentDetail.recentTrainings,
                  studentId: studentId,
                ),
              ),

              // 底部间距
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
