import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// Daily Training Summary Data Bundle
class DailySummaryData {
  final DailyTrainingModel dailyTraining;
  final List<TrainingFeedbackModel> feedbacks;
  final Macros? targetMacros; // From Diet Plan
  final int recordDaysCount;
  final int coachReviewsCount;

  const DailySummaryData({
    required this.dailyTraining,
    required this.feedbacks,
    this.targetMacros,
    required this.recordDaysCount,
    required this.coachReviewsCount,
  });
}

