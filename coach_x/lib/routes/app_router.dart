import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/shared/profile_setup/presentation/pages/profile_setup_page.dart';
import '../features/coach/presentation/widgets/coach_tab_scaffold.dart';
import '../features/student/presentation/widgets/student_tab_scaffold.dart';

/// 应用路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.login,
  debugLogDiagnostics: true, // Debug模式下输出路由日志
  // 错误页面
  errorBuilder: (context, state) => const ErrorPage(),

  // 路由表
  routes: [
    // 根路由 - 重定向到登录页或首页
    GoRoute(
      path: RouteNames.splash,
      redirect: (context, state) => RouteNames.login,
    ),

    // 登录页
    GoRoute(
      path: RouteNames.login,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const LoginPage()),
    ),

    // 注册页
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const RegisterPage()),
    ),

    // Profile Setup页
    GoRoute(
      path: RouteNames.profileSetup,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const ProfileSetupPage()),
    ),

    // 学生端路由 - 使用Tab容器
    GoRoute(path: '/student', redirect: (context, state) => '/student/home'),
    GoRoute(
      path: '/student/:tab',
      pageBuilder: (context, state) {
        final tab = state.pathParameters['tab'] ?? 'home';
        final tabIndex = _getStudentTabIndex(tab);
        return CupertinoPage(
          key: state.pageKey,
          child: StudentTabScaffold(initialTabIndex: tabIndex),
        );
      },
    ),

    // 教练端路由 - 使用Tab容器
    GoRoute(path: '/coach', redirect: (context, state) => '/coach/home'),
    GoRoute(
      path: '/coach/:tab',
      pageBuilder: (context, state) {
        final tab = state.pathParameters['tab'] ?? 'home';
        final tabIndex = _getCoachTabIndex(tab);
        return CupertinoPage(
          key: state.pageKey,
          child: CoachTabScaffold(initialTabIndex: tabIndex),
        );
      },
    ),

    // 学生详情页面（从Recent Activity跳转）
    GoRoute(
      path: '/student-detail/:studentId',
      pageBuilder: (context, state) {
        final studentId = state.pathParameters['studentId']!;
        // TODO: 实现StudentDetailPage
        // 当前显示占位页面
        return CupertinoPage(
          key: state.pageKey,
          child: _StudentDetailPlaceholderPage(studentId: studentId),
        );
      },
    ),
  ],
);

/// 获取教练Tab索引
int _getCoachTabIndex(String tab) {
  switch (tab) {
    case 'home':
      return 0;
    case 'students':
      return 1;
    case 'plans':
      return 2;
    case 'chat':
      return 3;
    case 'profile':
      return 4;
    default:
      return 0;
  }
}

/// 获取学生Tab索引
int _getStudentTabIndex(String tab) {
  switch (tab) {
    case 'home':
      return 0;
    case 'plan':
      return 1;
    case 'chat':
      return 3; // 注意：跳过索引2（Add按钮）
    case 'profile':
      return 4;
    default:
      return 0;
  }
}

/// 学生详情占位页面
class _StudentDetailPlaceholderPage extends StatelessWidget {
  final String studentId;

  const _StudentDetailPlaceholderPage({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('Student Detail'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_circle, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Student Detail Page',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Student ID: $studentId',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'TODO: 实现学生详情页面',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 错误页面组件
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('错误')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            const Text(
              '页面不存在',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '抱歉，您访问的页面不存在',
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                context.go(RouteNames.login);
              },
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
