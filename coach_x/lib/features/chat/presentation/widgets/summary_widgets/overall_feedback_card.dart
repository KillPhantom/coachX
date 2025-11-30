import 'package:flutter/material.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/data/models/daily_summary_data.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/widgets/audio_player_widget.dart';

class OverallFeedbackCard extends StatelessWidget {
  final DailySummaryData data;

  const OverallFeedbackCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Filter feedbacks where exerciseName is 'Daily Summary'
    final overallFeedbacks = data.feedbacks.where((f) {
      return f.exerciseName == 'Daily Summary';
    }).toList();

    if (overallFeedbacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall feedback From Coach',
            style: AppTextStyles.title3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textPrimary, width: 1), // Sketch style border
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: overallFeedbacks.map((feedback) {
                return _buildFeedbackItem(feedback);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(TrainingFeedbackModel feedback) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (feedback.feedbackType == 'voice' && feedback.voiceUrl != null)
            _buildVoiceItem(feedback),
          if (feedback.feedbackType == 'text' && feedback.textContent != null)
            Text(
              feedback.textContent!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          if (feedback.feedbackType == 'image' && feedback.imageUrl != null)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(8),
                 child: Image.network(
                   feedback.imageUrl!,
                   height: 100,
                   width: 100,
                   fit: BoxFit.cover,
                   errorBuilder: (_,__,___) => const Icon(Icons.broken_image),
                 ),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildVoiceItem(TrainingFeedbackModel feedback) {
    return AudioPlayerWidget(
      audioUrl: feedback.voiceUrl!,
      duration: feedback.voiceDuration ?? 0,
      isMine: false,
    );
  }
}
