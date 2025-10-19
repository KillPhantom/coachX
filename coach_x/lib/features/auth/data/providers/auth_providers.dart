import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';

/// 认证状态Stream Provider
/// 
/// 监听Firebase Auth的认证状态变化
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges();
});

/// 当前用户Provider
/// 
/// 提供当前登录的用户信息
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 当前用户ID Provider
/// 
/// 提供当前登录用户的ID
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

/// 是否已登录Provider
/// 
/// 检查用户是否已登录
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// 是否邮箱已验证Provider
/// 
/// 检查用户邮箱是否已验证
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
});

