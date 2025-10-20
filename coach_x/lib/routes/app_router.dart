import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/student/home/presentation/pages/student_home_page.dart';
import '../features/student/training/presentation/pages/training_page.dart';
import '../features/student/chat/presentation/pages/student_chat_page.dart';
import '../features/student/profile/presentation/pages/student_profile_page.dart';
import '../features/coach/home/presentation/pages/coach_home_page.dart';
import '../features/coach/students/presentation/pages/students_page.dart';
import '../features/coach/plans/presentation/pages/plans_page.dart';
import '../features/coach/chat/presentation/pages/coach_chat_page.dart';
import '../features/coach/profile/presentation/pages/coach_profile_page.dart';

/// 应用路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.login,
  debugLogDiagnostics: true, // Debug模式下输出路由日志
  // 错误页面
  errorBuilder: (context, state) => const ErrorPage(),

  // 路由表
  routes: [
    // 根路由 - 重定向到登录页或首页
    GoRoute(path: RouteNames.splash, redirect: (context, state) => RouteNames.login),

    // 登录页
    GoRoute(
      path: RouteNames.login,
      pageBuilder: (context, state) => CupertinoPage(key: state.pageKey, child: const LoginPage()),
    ),

    // 注册页
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const RegisterPage()),
    ),

    // 学生端路由组
    GoRoute(path: '/student', redirect: (context, state) => RouteNames.studentHome),

    GoRoute(
      path: RouteNames.studentHome,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const StudentHomePage()),
    ),

    GoRoute(
      path: RouteNames.studentTraining,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const TrainingPage()),
    ),

    GoRoute(
      path: RouteNames.studentChat,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const StudentChatPage()),
    ),

    GoRoute(
      path: RouteNames.studentProfile,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const StudentProfilePage()),
    ),

    // 教练端路由组
    GoRoute(path: '/coach', redirect: (context, state) => RouteNames.coachHome),

    GoRoute(
      path: RouteNames.coachHome,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const CoachHomePage()),
    ),

    GoRoute(
      path: RouteNames.coachStudents,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const StudentsPage()),
    ),

    GoRoute(
      path: RouteNames.coachPlans,
      pageBuilder: (context, state) => CupertinoPage(key: state.pageKey, child: const PlansPage()),
    ),

    GoRoute(
      path: RouteNames.coachChat,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const CoachChatPage()),
    ),

    GoRoute(
      path: RouteNames.coachProfile,
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const CoachProfilePage()),
    ),
  ],
);

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
            const Text('页面不存在', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
