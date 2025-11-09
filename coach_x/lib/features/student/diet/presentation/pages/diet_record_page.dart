import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/student/home/presentation/providers/student_home_providers.dart';
import '../providers/diet_record_providers.dart';
import '../widgets/macro_summary_row.dart';
import '../widgets/meal_suggestion_card.dart';

/// 饮食记录页面
class DietRecordPage extends ConsumerStatefulWidget {
  const DietRecordPage({super.key});

  @override
  ConsumerState<DietRecordPage> createState() => _DietRecordPageState();
}

class _DietRecordPageState extends ConsumerState<DietRecordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() {
    final plansAsync = ref.read(studentPlansProvider);
    final dayNumbers = ref.read(currentDayNumbersProvider);

    plansAsync.whenData((plans) {
      if (plans.dietPlan != null) {
        final dayNum = dayNumbers['diet'] ?? 1;
        final dietDay = plans.dietPlan!.days.firstWhere(
          (day) => day.day == dayNum,
          orElse: () => plans.dietPlan!.days.first,
        );

        ref.read(dietRecordStateProvider.notifier).initialize(dietDay);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(dietRecordStateProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.mealRecord),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(l10n.coachSuggestion, style: AppTextStyles.title3),
                  const SizedBox(height: AppDimensions.spacingM),
                  if (state.dietDay != null)
                    MacroSummaryRow(macros: state.dietDay!.macros),
                  const SizedBox(height: AppDimensions.spacingL),
                  ...state.meals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final meal = entry.value;
                    return MealSuggestionCard(
                      meal: meal,
                      index: index,
                      onToggleComplete: () => ref
                          .read(dietRecordStateProvider.notifier)
                          .toggleMealCompletion(index),
                    );
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
