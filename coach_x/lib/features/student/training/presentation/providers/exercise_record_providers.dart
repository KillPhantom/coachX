import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_record_state.dart';
import 'package:coach_x/features/student/training/data/repositories/training_record_repository.dart';
import 'package:coach_x/features/student/training/data/repositories/training_record_repository_impl.dart';
import 'exercise_record_notifier.dart';

/// Training Record Repository Provider
final trainingRecordRepositoryProvider = Provider<TrainingRecordRepository>((ref) {
  return TrainingRecordRepositoryImpl();
});

/// Exercise Record Notifier Provider
final exerciseRecordNotifierProvider =
    StateNotifierProvider.autoDispose<ExerciseRecordNotifier, ExerciseRecordState>(
  (ref) {
    final repository = ref.watch(trainingRecordRepositoryProvider);
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return ExerciseRecordNotifier(repository, dateString);
  },
);
