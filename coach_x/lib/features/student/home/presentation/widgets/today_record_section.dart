import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../data/models/student_plans_model.dart';
import '../providers/student_home_providers.dart';
import 'diet_plan_card.dart';

/// 今日饮食计划区块
///
/// 显示今日的饮食计划
class TodayRecordSection extends ConsumerWidget {
  const TodayRecordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(studentPlansProvider);
    final dayNumbersAsync = ref.watch(currentDayNumbersProvider);

    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (plans) {
        if (plans.hasNoPlan) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Text(l10n.todayRecord, style: AppTextStyles.bodyMedium),
              ),

              // 内容区域（包含指示器）
              _buildRecordCards(context, plans, dayNumbersAsync),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordCards(
    BuildContext context,
    StudentPlansModel plans,
    Map<String, int> dayNumbers,
  ) {
    // 只显示饮食计划
    if (plans.dietPlan == null) {
      return const SizedBox.shrink();
    }

    return _DietPlanWithIndicator(plans: plans, dayNumbers: dayNumbers);
  }
}

/// 内部 Widget：饮食计划卡片 + 指示器
class _DietPlanWithIndicator extends StatefulWidget {
  final StudentPlansModel plans;
  final Map<String, int> dayNumbers;

  const _DietPlanWithIndicator({required this.plans, required this.dayNumbers});

  @override
  State<_DietPlanWithIndicator> createState() => _DietPlanWithIndicatorState();
}

class _DietPlanWithIndicatorState extends State<_DietPlanWithIndicator> {
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    final dayNum = widget.dayNumbers['diet'] ?? 1;
    final dietDay = widget.plans.dietPlan!.days.firstWhere(
      (day) => day.day == dayNum,
      orElse: () => widget.plans.dietPlan!.days.first,
    );

    _totalPages = dietDay.meals.length + 1;

    return Column(
      children: [
        // 饮食计划卡片
        DietPlanCard(
          dietDay: dietDay,
          // TBD: 未来从 todayRecord 计算进度
          progress: null,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
        ),

        // 圆点指示器
        if (_totalPages > 1) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildPageIndicator(),
          const SizedBox(height: AppDimensions.spacingM),
        ],
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppColors.primaryColor
                : AppColors.dividerLight,
          ),
        );
      }),
    );
  }
}
