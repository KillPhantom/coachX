import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/student/diet/data/repositories/diet_record_repository.dart';
import 'package:coach_x/features/student/diet/data/repositories/diet_record_repository_impl.dart';
import 'package:coach_x/features/student/diet/data/models/diet_record_state.dart';
import 'diet_record_notifier.dart';

// ==================== Repository Provider ====================

/// 饮食记录Repository Provider
final dietRecordRepositoryProvider = Provider<DietRecordRepository>((ref) {
  return DietRecordRepositoryImpl();
});

// ==================== State Notifier Provider ====================

/// 饮食记录状态Provider
final dietRecordStateProvider =
    StateNotifierProvider<DietRecordNotifier, DietRecordState>((ref) {
      final repository = ref.watch(dietRecordRepositoryProvider);
      return DietRecordNotifier(repository, ref);
    });

// ==================== Computed Providers ====================

/// 当前日期Provider (格式: "yyyy-MM-dd")
final currentDateProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});
