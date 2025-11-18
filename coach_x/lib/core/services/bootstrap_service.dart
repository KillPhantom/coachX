import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/core/services/user_cache_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/routes/route_names.dart';

/// 启动路由决策服务
///
/// 负责在应用启动时根据认证状态和缓存状态决定初始路由
class BootstrapService {
  BootstrapService._();

  /// 确定初始路由
  ///
  /// 根据以下逻辑决定应用启动时的初始路由：
  /// 1. 如果用户未登录 → 返回登录页
  /// 2. 如果用户已登录但缓存无效 → 返回Splash页
  /// 3. 如果用户已登录且缓存有效 → 根据角色返回对应首页
  ///
  /// 返回路由路径字符串
  static Future<String> determineInitialRoute() async {
    try {
      AppLogger.info('开始确定初始路由...');

      // 检查用户登录状态
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        AppLogger.info('用户未登录 → 登录页');
        return RouteNames.login;
      }

      AppLogger.info('用户已登录: ${currentUser.uid}');

      // 检查缓存有效性
      final cacheValid = UserCacheService.isValid();

      if (!cacheValid) {
        AppLogger.info('缓存无效 → Splash页');
        return RouteNames.splash;
      }

      // 缓存有效，获取角色并跳转到对应首页
      final role = UserCacheService.getCachedRole();

      if (role == null) {
        AppLogger.warning('缓存有效但角色为空 → Splash页');
        return RouteNames.splash;
      }

      if (role == 'coach') {
        AppLogger.info('教练角色 → 教练首页');
        return RouteNames.coachHome;
      } else if (role == 'student') {
        AppLogger.info('学生角色 → 学生首页');
        return RouteNames.studentHome;
      } else {
        AppLogger.warning('未知角色: $role → Splash页');
        return RouteNames.splash;
      }
    } catch (e, stackTrace) {
      AppLogger.error('确定初始路由失败', e, stackTrace);
      // 出错时默认返回登录页
      return RouteNames.login;
    }
  }
}
