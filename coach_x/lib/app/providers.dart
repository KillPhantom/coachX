import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';

/// 全局Providers配置
/// 用于管理应用级的状态和依赖

/// 路由Provider
final routerProvider = Provider<GoRouter>((ref) {
  return appRouter;
});

/// 日志Provider（预留）
/// TODO: 实现日志Provider

/// 主题Provider（预留）
/// TODO: 实现主题切换Provider

/// 用户Provider（预留）
/// TODO: 实现用户状态管理Provider
