import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'route_names.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/shared/profile_setup/presentation/pages/profile_setup_page.dart';
import '../features/coach/presentation/widgets/coach_tab_scaffold.dart';
import '../features/student/presentation/widgets/student_tab_scaffold.dart';
import '../features/coach/plans/presentation/pages/create_training_plan_page.dart';
import '../features/coach/plans/presentation/pages/create_diet_plan_page.dart';
import '../features/coach/plans/presentation/pages/create_supplement_plan_page.dart';
import '../features/chat/presentation/pages/chat_detail_page.dart';
import '../features/chat/presentation/pages/daily_training_review_page.dart';
import '../features/chat/presentation/pages/training_feed_page.dart';
import '../features/shared/profile/presentation/pages/language_selection_page.dart';
import '../features/student/diet/presentation/pages/ai_food_scanner_page.dart';
import '../features/student/body_stats/presentation/pages/body_stats_record_page.dart';
import '../features/student/body_stats/presentation/pages/body_stats_history_page.dart';
import '../features/student/training/presentation/pages/exercise_record_page.dart';
import '../features/coach/training_reviews/presentation/pages/training_review_list_page.dart';
import '../features/coach/exercise_library/presentation/pages/exercise_library_page.dart';
import '../features/coach/students/presentation/pages/student_detail_page.dart';

/// 全局单例 GoRouter 实例
GoRouter? _appRouter;

/// 获取或创建应用路由配置
///
/// [initialRoute] 初始路由路径（仅在首次创建时使用）
GoRouter getAppRouter(String initialRoute) {
  // 如果已存在实例，直接返回（避免热重载时重新创建）
  if (_appRouter != null) {
    return _appRouter!;
  }

  // 首次创建 GoRouter 实例
  _appRouter = GoRouter(
    initialLocation: initialRoute,
    debugLogDiagnostics: true, // Debug模式下输出路由日志
    // 路由守护
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final currentPath = state.uri.path;

      // 公开路由（无需登录即可访问）
      const publicRoutes = [RouteNames.login, '/register', RouteNames.splash];

      // 如果用户未登录且不在公开路由，重定向到登录页
      if (!isLoggedIn && !publicRoutes.contains(currentPath)) {
        return RouteNames.login;
      }

      // 其他情况允许访问
      return null;
    },

    // 错误页面
    errorBuilder: (context, state) => const ErrorPage(),

    // 路由表
    routes: [
      // Splash页
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const SplashPage()),
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

      // AI食物扫描页（必须在 /student/:tab 之前）
      GoRoute(
        path: RouteNames.studentAIFoodScanner,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const AIFoodScannerPage()),
      ),

      // 身体数据记录页（必须在 /student/:tab 之前）
      GoRoute(
        path: RouteNames.studentBodyStatsRecord,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const BodyStatsRecordPage(),
        ),
      ),

      // 身体数据历史页（必须在 /student/:tab 之前）
      GoRoute(
        path: RouteNames.studentBodyStatsHistory,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const BodyStatsHistoryPage(),
        ),
      ),

      // 训练记录页（必须在 /student/:tab 之前）
      GoRoute(
        path: RouteNames.studentExerciseRecord,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const ExerciseRecordPage(),
        ),
      ),

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

      // 训练审核列表页面（必须在 /coach/:tab 之前，否则会被 :tab 匹配）
      GoRoute(
        path: '/coach/training-reviews',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const TrainingReviewListPage(),
          );
        },
      ),

      // 动作库页面（必须在 /coach/:tab 之前）
      GoRoute(
        path: '/coach/exercise-library',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const ExerciseLibraryPage(),
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

      // 学生详情页面
      GoRoute(
        path: '/student-detail/:studentId',
        pageBuilder: (context, state) {
          final studentId = state.pathParameters['studentId']!;
          return CupertinoPage(
            key: state.pageKey,
            child: StudentDetailPage(studentId: studentId),
          );
        },
      ),

      // 计划详情页面
      GoRoute(
        path: '/plan-detail/:planType/:planId',
        pageBuilder: (context, state) {
          final planType = state.pathParameters['planType']!;
          final planId = state.pathParameters['planId']!;
          // TODO: 实现PlanDetailPage
          // 当前显示占位页面
          return CupertinoPage(
            key: state.pageKey,
            child: _PlanDetailPlaceholderPage(
              planType: planType,
              planId: planId,
            ),
          );
        },
      ),

      // 创建/编辑训练计划页面（共享同一UI）
      // 路径: /training-plan/new - 创建模式
      // 路径: /training-plan/{planId} - 编辑模式
      GoRoute(
        path: '/training-plan/:planId',
        pageBuilder: (context, state) {
          final planId = state.pathParameters['planId'];
          // 如果planId是'new'，则为创建模式
          final actualPlanId = (planId == 'new') ? null : planId;
          return CupertinoPage(
            key: state.pageKey,
            child: CreateTrainingPlanPage(planId: actualPlanId),
          );
        },
      ),

      // 创建/编辑饮食计划页面（共享同一UI）
      // 路径: /diet-plan/new - 创建模式
      // 路径: /diet-plan/{planId} - 编辑模式
      GoRoute(
        path: '/diet-plan/:planId',
        pageBuilder: (context, state) {
          final planId = state.pathParameters['planId'];
          // 如果planId是'new'，则为创建模式
          final actualPlanId = (planId == 'new') ? null : planId;
          return CupertinoPage(
            key: state.pageKey,
            child: CreateDietPlanPage(planId: actualPlanId),
          );
        },
      ),

      // 创建/编辑补剂计划页面（共享同一UI）
      // 路径: /supplement-plan/new - 创建模式
      // 路径: /supplement-plan/{planId} - 编辑模式
      GoRoute(
        path: '/supplement-plan/:planId',
        pageBuilder: (context, state) {
          final planId = state.pathParameters['planId'];
          // 如果planId是'new'，则为创建模式
          final actualPlanId = (planId == 'new') ? null : planId;
          return CupertinoPage(
            key: state.pageKey,
            child: CreateSupplementPlanPage(planId: actualPlanId),
          );
        },
      ),

      // 对话详情页面
      GoRoute(
        path: '/chat/:conversationId',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return CupertinoPage(
            key: state.pageKey,
            child: ChatDetailPage(conversationId: conversationId),
          );
        },
      ),

      // 训练详情查看页面（Placeholder）
      GoRoute(
        path: '/training-review/:dailyTrainingId',
        pageBuilder: (context, state) {
          final dailyTrainingId = state.pathParameters['dailyTrainingId']!;
          return CupertinoPage(
            key: state.pageKey,
            child: DailyTrainingReviewPage(dailyTrainingId: dailyTrainingId),
          );
        },
      ),

      // 训练批阅 Feed 页
      GoRoute(
        path: '/coach/training-feed/:dailyTrainingId',
        pageBuilder: (context, state) {
          final dailyTrainingId = state.pathParameters['dailyTrainingId']!;
          final studentId = state.uri.queryParameters['studentId']!;
          final studentName = state.uri.queryParameters['studentName']!;
          return CupertinoPage(
            key: state.pageKey,
            child: TrainingFeedPage(
              dailyTrainingId: dailyTrainingId,
              studentId: studentId,
              studentName: studentName,
            ),
          );
        },
      ),

      // 语言选择页面
      GoRoute(
        path: '/language-selection',
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const LanguageSelectionPage(),
          );
        },
      ),
    ],
  );

  return _appRouter!;
}

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

/// 计划详情占位页面
class _PlanDetailPlaceholderPage extends StatelessWidget {
  final String planType;
  final String planId;

  const _PlanDetailPlaceholderPage({
    required this.planType,
    required this.planId,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back, size: 28),
        ),
        middle: const Text('Plan Detail'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.doc_text, size: 80),
            const SizedBox(height: 20),
            const Text('Plan Detail Page', style: AppTextStyles.title2),
            const SizedBox(height: 8),
            Text(
              'Type: $planType',
              style: AppTextStyles.callout.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
            Text(
              'ID: $planId',
              style: AppTextStyles.callout.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TODO: 实现计划详情页面',
              style: AppTextStyles.callout.copyWith(
                color: CupertinoColors.systemGrey,
              ),
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
            const Text('页面不存在', style: AppTextStyles.title3),
            const SizedBox(height: 8),
            const Text('抱歉，您访问的页面不存在', style: AppTextStyles.footnote),
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
