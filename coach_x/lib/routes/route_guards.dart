import 'package:go_router/go_router.dart';
import '../core/enums/user_role.dart';
import 'route_names.dart';

/// 路由守卫
/// 负责路由权限控制和重定向
class RouteGuards {
  RouteGuards._(); // 私有构造函数，防止实例化

  /// 检查用户是否已登录
  /// TODO: 实际实现需要从状态管理中获取登录状态
  static bool isLoggedIn() {
    // 暂时返回true，实际应该从 SharedPreferences 或 Riverpod 中获取
    return false;
  }

  /// 获取用户角色
  /// TODO: 实际实现需要从状态管理中获取用户角色
  static UserRole? getUserRole() {
    // 暂时返回null，实际应该从 SharedPreferences 或 Riverpod 中获取
    return null;
  }

  /// 认证守卫
  /// 检查用户是否已登录，未登录则重定向到登录页
  static String? authGuard(GoRouterState state) {
    if (!isLoggedIn()) {
      return RouteNames.login;
    }
    return null; // 返回null表示允许访问
  }

  /// 学生角色守卫
  /// 检查用户是否为学生角色
  static String? studentGuard(GoRouterState state) {
    // 先检查是否登录
    final authRedirect = authGuard(state);
    if (authRedirect != null) {
      return authRedirect;
    }

    // 检查角色
    final role = getUserRole();
    if (role == null || !role.isStudent) {
      // 如果不是学生，重定向到教练首页或登录页
      return role?.isCoach == true ? RouteNames.coachHome : RouteNames.login;
    }

    return null;
  }

  /// 教练角色守卫
  /// 检查用户是否为教练角色
  static String? coachGuard(GoRouterState state) {
    // 先检查是否登录
    final authRedirect = authGuard(state);
    if (authRedirect != null) {
      return authRedirect;
    }

    // 检查角色
    final role = getUserRole();
    if (role == null || !role.isCoach) {
      // 如果不是教练，重定向到学生首页或登录页
      return role?.isStudent == true
          ? RouteNames.studentHome
          : RouteNames.login;
    }

    return null;
  }

  /// 根据用户角色获取默认首页
  static String getDefaultHome() {
    if (!isLoggedIn()) {
      return RouteNames.login;
    }

    final role = getUserRole();
    if (role == null) {
      return RouteNames.login;
    }

    return role.isStudent ? RouteNames.studentHome : RouteNames.coachHome;
  }
}
