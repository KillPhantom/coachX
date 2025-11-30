import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_summary_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/summary_widgets/diet_summary_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/summary_widgets/exercise_summary_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/summary_widgets/overall_feedback_card.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DailyTrainingSummaryPage extends ConsumerWidget {
  final String dailyTrainingId;

  const DailyTrainingSummaryPage({super.key, required this.dailyTrainingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailySummaryDataProvider(dailyTrainingId));
    final l10n = AppLocalizations.of(context)!;
    final summaryData = summaryAsync.asData?.value;

    void openCalendar() {
      if (summaryData == null) {
        return;
      }
      final dailyTraining = summaryData.dailyTraining;
      context.push(
        RouteNames.getTrainingCalendarRoute(
          dailyTraining.studentId,
          focusDate: dailyTraining.date,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: summaryAsync.when(
          data: (data) => Text(
            _formatDate(data.dailyTraining.date),
            style: AppTextStyles.title3.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        actions: [
          TextButton(
            onPressed: summaryData == null ? null : openCalendar,
            child: Text(
              l10n.viewAll,
              style: AppTextStyles.body.copyWith(
                color: summaryData == null
                    ? AppColors.textPrimary.withValues(alpha: 0.3)
                    : AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: summaryAsync.when(
        data: (data) => SingleChildScrollView(
          child: Column(
            children: [
              OverallFeedbackCard(data: data),
              DietSummarySection(data: data),
              ExerciseSummarySection(data: data),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
