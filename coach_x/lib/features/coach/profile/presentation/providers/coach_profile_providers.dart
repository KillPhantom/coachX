import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';

/// 当前教练Provider
///
/// 监听当前登录的教练用户信息
final currentCoachProvider = Provider<UserModel?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 单位偏好Provider
///
/// 获取当前用户的单位偏好设置
final unitPreferenceProvider = Provider<String>((ref) {
  final currentUser = ref.watch(currentCoachProvider);
  // 额外的空值安全检查 - 确保永远不会返回null
  final preference = currentUser?.unitPreference;
  if (preference == null || preference.isEmpty) {
    return 'imperial';
  }
  return preference;
});

/// 是否使用公制单位Provider
final isMetricProvider = Provider<bool>((ref) {
  final preference = ref.watch(unitPreferenceProvider);
  return preference.toLowerCase() == 'metric';
});
