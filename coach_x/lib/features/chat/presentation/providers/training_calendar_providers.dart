import 'dart:collection';

import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class TrainingCalendarRequest {
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  const TrainingCalendarRequest({
    required this.studentId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainingCalendarRequest &&
        other.studentId == studentId &&
        other.startDate.isAtSameMomentAs(startDate) &&
        other.endDate.isAtSameMomentAs(endDate);
  }

  @override
  int get hashCode => Object.hash(
    studentId,
    startDate.millisecondsSinceEpoch,
    endDate.millisecondsSinceEpoch,
  );
}

final trainingCalendarProvider =
    FutureProvider.family<
      Map<DateTime, List<DailyTrainingModel>>,
      TrainingCalendarRequest
    >((ref, request) async {
      final repository = ref.watch(dailyTrainingRepositoryProvider);
      final trainings = await repository.getTrainingsInRange(
        studentId: request.studentId,
        startDate: request.startDate,
        endDate: request.endDate,
      );

      final grouped = SplayTreeMap<DateTime, List<DailyTrainingModel>>();

      for (final training in trainings) {
        final parsed = DateTime.tryParse(training.date);
        if (parsed == null) {
          continue;
        }

        final key = DateTime(parsed.year, parsed.month, parsed.day);
        grouped.putIfAbsent(key, () => []).add(training);
      }

      return grouped;
    });
