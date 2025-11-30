import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/routes/route_names.dart';

class DailySummaryTile extends StatelessWidget {
  final String dateLabel;
  final List<TrainingFeedbackModel> feedbacks;

  const DailySummaryTile({
    super.key,
    required this.dateLabel,
    required this.feedbacks,
  });

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) return const SizedBox.shrink();

    final dailyTrainingId = feedbacks.first.dailyTrainingId;
    
    // Count feedback types
    int textCount = 0;
    int voiceCount = 0;
    int videoCount = 0;
    for (final f in feedbacks) {
      if (f.feedbackType == 'text') textCount++;
      else if (f.feedbackType == 'voice') voiceCount++;
      else if (f.feedbackType == 'video') videoCount++;
    }

    final summaryText = [
      if (textCount > 0) '$textCount Text',
      if (voiceCount > 0) '$voiceCount Voice',
      if (videoCount > 0) '$videoCount Video',
    ].join(', ');

    return GestureDetector(
      onTap: () {
        context.push(RouteNames.getDailyTrainingSummaryRoute(dailyTrainingId));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date Icon or similar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summaryText.isEmpty ? 'Training Summary' : summaryText,
                    style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

