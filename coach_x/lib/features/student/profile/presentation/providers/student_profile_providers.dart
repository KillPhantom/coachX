import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/cache/user_avatar_cache_service.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';

/// 当前学生Provider
///
/// 监听当前登录的学生用户信息
final currentStudentProvider = Provider<UserModel?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 教练信息Provider
///
/// 根据学生的 coachId 获取教练信息
final coachInfoProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = ref.watch(currentStudentProvider);

  // 如果没有教练ID，返回null
  if (currentUser?.coachId == null) {
    return null;
  }

  // 获取教练信息
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getUser(currentUser!.coachId!);
});

/// 单位偏好Provider
///
/// 获取当前用户的单位偏好设置
final unitPreferenceProvider = Provider<String>((ref) {
  final currentUser = ref.watch(currentStudentProvider);
  return currentUser?.unitPreference ?? 'imperial';
});

/// 是否使用公制单位Provider
final isMetricProvider = Provider<bool>((ref) {
  final preference = ref.watch(unitPreferenceProvider);
  return preference.toLowerCase() == 'metric';
});

/// 教练头像URL Provider（带缓存）
///
/// 根据教练ID获取缓存的头像URL
final coachAvatarUrlProvider = FutureProvider<String?>((ref) async {
  final currentUser = ref.watch(currentStudentProvider);

  if (currentUser?.coachId == null) {
    return null;
  }

  return await UserAvatarCacheService.getAvatarUrl(currentUser!.coachId!);
});

/// 强制刷新教练头像
///
/// 用于下拉刷新时调用
Future<void> forceRefreshCoachAvatar(String coachId) async {
  await UserAvatarCacheService.forceRefreshAvatar(coachId);
}
