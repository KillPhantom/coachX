import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/widgets/video_player_dialog.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/data/models/daily_summary_data.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/chat/presentation/widgets/audio_player_widget.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';
import 'package:coach_x/core/models/media_upload_state.dart';

class ExerciseSummarySection extends StatelessWidget {
  final DailySummaryData data;

  const ExerciseSummarySection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final exercises = data.dailyTraining.exercises ?? [];
    final completedExercises = exercises.where((e) => e.completed).length;
    final completedMovements = _calculateTotalReps(exercises);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise summary',
            style: AppTextStyles.title3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Stats Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textPrimary),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(completedExercises, 'Completed Exercises'),
                  const VerticalDivider(color: AppColors.dividerMedium, thickness: 1),
                  _buildStatItem(completedMovements, 'Completed movements'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Exercise List
          ...exercises.map((exercise) => _buildExerciseItem(context, exercise, data.feedbacks)),
        ],
      ),
    );
  }

  int _calculateTotalReps(List<StudentExerciseModel> exercises) {
    return exercises.fold<int>(0, (sum, e) {
      if (!e.completed) return sum;
      return sum + e.sets.fold<int>(0, (sSum, set) {
        // Fixed type error: Parse reps string to int
        final repsInt = int.tryParse(set.reps) ?? 0;
        return sSum + repsInt;
      });
    });
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.caption2.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExerciseItem(BuildContext context, StudentExerciseModel exercise, List<TrainingFeedbackModel> allFeedbacks) {
    // Find feedbacks for this exercise
    final exerciseFeedbacks = allFeedbacks.where((f) {
      if (exercise.exerciseTemplateId != null && f.exerciseTemplateId == exercise.exerciseTemplateId) {
        return true;
      }
      if (f.exerciseName == exercise.name) {
        return true;
      }
      return false;
    }).toList();

    // Debug logging
    AppLogger.debug('🔍 All Feedbacks: ${allFeedbacks}');
    AppLogger.debug('🔍 Exercise Feedbacks: ${exerciseFeedbacks}');


    final hasVideo = exercise.media.any((m) => m.type == MediaType.video);
    if (!hasVideo && exerciseFeedbacks.isEmpty) return const SizedBox.shrink();

    final videoThumbnail = hasVideo 
        ? exercise.media.firstWhere((m) => m.type == MediaType.video).thumbnailUrl 
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Thumbnail with Play Button
              GestureDetector(
                onTap: hasVideo ? () => _handleVideoTap(context, exercise) : null,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dividerLight),
                    image: videoThumbnail != null && videoThumbnail.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(videoThumbnail),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Placeholder icon if no thumbnail
                      if (videoThumbnail == null || videoThumbnail.isEmpty)
                        const Icon(Icons.videocam, size: 40, color: AppColors.textTertiary),
                      // Play icon overlay
                      if (hasVideo && videoThumbnail != null && videoThumbnail.isNotEmpty)
                        Icon(
                          CupertinoIcons.play_circle_fill,
                          size: 40,
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Feedback Bubbles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: exerciseFeedbacks.isEmpty
                      ? [
                          // Placeholder empty
                        ]
                      : exerciseFeedbacks.map((f) => _buildFeedbackBubble(f)).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBubble(TrainingFeedbackModel feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
          topLeft: Radius.circular(4),
        ),
        border: Border.all(color: AppColors.textPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From coach:',
            style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (feedback.textContent != null)
            Text(
              feedback.textContent!,
              style: AppTextStyles.footnote,
            ),
          if (feedback.voiceUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: AudioPlayerWidget(
                audioUrl: feedback.voiceUrl!,
                duration: feedback.voiceDuration ?? 0,
                isMine: false,
              ),
            ),
        ],
      ),
    );
  }

  /// Handle video thumbnail tap - open video player dialog
  void _handleVideoTap(BuildContext context, StudentExerciseModel exercise) {
    // Extract video URLs from exercise
    final videoUrls = exercise.media
        .where((m) => m.type == MediaType.video && m.downloadUrl != null && m.downloadUrl!.isNotEmpty)
        .map((m) => m.downloadUrl!)
        .toList();

    if (videoUrls.isEmpty) {
      AppLogger.warning('No valid video URLs found for exercise: ${exercise.name}');
      return;
    }

    AppLogger.debug('Opening video player with ${videoUrls.length} video(s) for exercise: ${exercise.name}');

    // Show video player dialog
    VideoPlayerDialog.show(
      context,
      videoUrls: videoUrls,
      initialIndex: 0,
    );
  }
}
