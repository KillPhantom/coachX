import 'package:go_router/go_router.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/routes/route_names.dart';

/// 认证守卫
///
/// 检查用户是否已登录，未登录则重定向到登录页
String? authGuard(GoRouterState state) {
  final isLoggedIn = AuthService.currentUser != null;

  if (!isLoggedIn) {
    return RouteNames.login;
  }

  return null; // 返回null表示允许访问
}

/// 角色守卫
///
/// 检查用户角色是否匹配
/// [requiredRole] 需要的角色（'student' 或 'coach'）
String? roleGuard(GoRouterState state, String requiredRole) {
  // 首先检查是否登录
  final authCheck = authGuard(state);
  if (authCheck != null) {
    return authCheck;
  }

  // TODO: 从Firestore获取用户角色
  // 目前暂时允许所有已登录用户访问

  return null;
}
