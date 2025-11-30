import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/features/chat/data/models/daily_summary_data.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_providers.dart';
import 'package:coach_x/core/utils/logger.dart';

import 'package:coach_x/core/services/auth_service.dart';

// ==================== Student Stats Provider ====================

/// Student Stats Provider
/// Fetches total "record days" and "coach reviews" for a student.
final studentStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, studentId) async {
  try {
    final currentUserId = AuthService.currentUserId;
    
    // 1. Daily Trainings Query
    final trainingWhere = <List<dynamic>>[
      ['studentID', '==', studentId], // Correct field name: studentID
      ['completionStatus', '==', 'completed'],
    ];
    
    // If current user is NOT the student (i.e., is Coach), filter by coachID
    if (currentUserId != null && currentUserId != studentId) {
      trainingWhere.add(['coachID', '==', currentUserId]);
    }

    final trainings = await FirestoreService.queryDocuments(
      'dailyTrainings',
      where: trainingWhere,
    );
    final recordDaysCount = trainings.length;

    // 2. Feedback Query
    final feedbackWhere = <List<dynamic>>[
      ['studentId', '==', studentId], // Correct field name: studentId
    ];

    // If current user is NOT the student (i.e., is Coach), filter by coachId
    if (currentUserId != null && currentUserId != studentId) {
      feedbackWhere.add(['coachId', '==', currentUserId]);
    }

    final feedbacks = await FirestoreService.queryDocuments(
      'dailyTrainingFeedback',
      where: feedbackWhere,
    );
    final coachReviewsCount = feedbacks.length;

    return {
      'recordDays': recordDaysCount,
      'coachReviews': coachReviewsCount,
    };
  } catch (e, stack) {
    AppLogger.error('Failed to fetch student stats', e, stack);
    return {
      'recordDays': 0,
      'coachReviews': 0,
    };
  }
});

// ==================== Daily Summary Data Provider ====================

/// Daily Summary Data Provider
/// Combines DailyTraining, Feedbacks, Diet Targets, and Stats.
final dailySummaryDataProvider = StreamProvider.family<DailySummaryData, String>((ref, dailyTrainingId) async* {
  final dailyTrainingRepository = ref.watch(dailyTrainingRepositoryProvider);
  final feedbackRepository = ref.watch(feedbackRepositoryProvider);
  final dietPlanRepository = ref.watch(dietPlanRepositoryProvider);

  // 1. Watch Daily Training
  final dailyTrainingStream = dailyTrainingRepository.watchDailyTraining(dailyTrainingId);
  
  await for (final dailyTraining in dailyTrainingStream) {
    if (dailyTraining == null) {
      continue;
    }

    // 2. Watch ALL Feedbacks for this training (including exercise-specific ones)
    final feedbacksStream = feedbackRepository.getFeedbackHistory(
      dailyTrainingId,
    );

    // Fetch static data (Stats & DietPlan)
    final studentId = dailyTraining.studentId;
    final stats = await ref.read(studentStatsProvider(studentId).future);
    
    Macros? targetMacros;
    final dietPlanId = dailyTraining.planSelection.dietPlanId;
    
    if (dietPlanId != null && dietPlanId.isNotEmpty) {
       try {
         final dietPlan = await dietPlanRepository.getPlan(dietPlanId);
         if (dietPlan != null) {
           final dayNum = dailyTraining.planSelection.dietDayNumber ?? 1;
           final dietDay = dietPlan.days.firstWhere(
             (d) => d.day == dayNum,
             orElse: () => dietPlan.days.first,
           );
           targetMacros = dietDay.macros;
         }
       } catch (e) {
         AppLogger.error('Failed to fetch diet plan', e);
       }
    }

    // Now combine with feedback stream
    yield* feedbacksStream.map((feedbacks) {
      return DailySummaryData(
        dailyTraining: dailyTraining,
        feedbacks: feedbacks,
        targetMacros: targetMacros,
        recordDaysCount: stats['recordDays'] ?? 0,
        coachReviewsCount: stats['coachReviews'] ?? 0,
      );
    });
  }
});
