import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/features/student/body_stats/data/repositories/body_stats_repository.dart';
import 'package:coach_x/features/student/body_stats/data/repositories/body_stats_repository_impl.dart';
import 'package:coach_x/features/student/body_stats/presentation/providers/body_stats_record_notifier.dart';
import 'package:coach_x/features/student/body_stats/presentation/providers/body_stats_history_notifier.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_stats_state.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_stats_history_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Body Stats Repository Provider
///
/// 提供 BodyStatsRepository 实例
final bodyStatsRepositoryProvider = Provider<BodyStatsRepository>((ref) {
  return BodyStatsRepositoryImpl();
});

/// Body Stats Record Provider
///
/// 管理记录页面的状态
final bodyStatsRecordProvider =
    StateNotifierProvider<BodyStatsRecordNotifier, BodyStatsState>((ref) {
  final repository = ref.watch(bodyStatsRepositoryProvider);
  final weightUnit = ref.watch(userWeightUnitProvider).value ?? 'kg';

  return BodyStatsRecordNotifier(
    repository: repository,
    initialWeightUnit: weightUnit,
  );
});

/// Body Stats History Provider
///
/// 管理历史页面的状态
final bodyStatsHistoryProvider = StateNotifierProvider<
    BodyStatsHistoryNotifier, BodyStatsHistoryState>((ref) {
  final repository = ref.watch(bodyStatsRepositoryProvider);
  return BodyStatsHistoryNotifier(repository: repository);
});

/// User Weight Unit Provider
///
/// 从 Firestore 读取用户的体重单位偏好
final userWeightUnitProvider = FutureProvider<String>((ref) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'kg';

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists) return 'kg';

    final data = doc.data();
    if (data == null) return 'kg';

    // 读取 unitPreference 字段，默认为 'kg'
    final unitPreference = data['unitPreference'] as String?;

    // unitPreference 可能是 'metric' 或 'imperial'
    if (unitPreference == 'imperial') {
      return 'lbs';
    } else {
      return 'kg';
    }
  } catch (e) {
    // 出错时默认返回 kg
    return 'kg';
  }
});
