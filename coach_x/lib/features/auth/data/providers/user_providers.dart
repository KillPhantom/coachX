import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository_impl.dart';
import 'package:coach_x/features/auth/data/providers/auth_providers.dart';

/// 用户仓库Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

/// 当前用户信息Provider（从Firestore获取）
///
/// 根据当前登录用户的ID从Firestore获取完整用户信息
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userRepositoryProvider);
  return repository.watchUser(userId);
});

/// 用户角色Provider
///
/// 提供当前用户的角色信息
final userRoleProvider = Provider<UserRole?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user?.role,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 是否为学生Provider
final isStudentProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == UserRole.student;
});

/// 是否为教练Provider
final isCoachProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.coach;
});
