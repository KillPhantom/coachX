/// 路由名称常量
/// 定义应用中所有的路由路径
class RouteNames {
  RouteNames._(); // 私有构造函数，防止实例化

  // ==================== 根路由 ====================

  /// 启动页/Splash页
  static const String splash = '/splash';

  /// 登录页
  static const String login = '/login';

  /// Profile Setup页
  static const String profileSetup = '/profile-setup';

  // ==================== 学生端路由 ====================

  /// 学生首页
  static const String studentHome = '/student/home';

  /// 学生计划页
  static const String studentPlan = '/student/plan';

  /// 学生训练页
  static const String studentTraining = '/student/training';

  /// 学生对话页
  static const String studentChat = '/student/chat';

  /// 学生资料页
  static const String studentProfile = '/student/profile';

  /// AI食物扫描页
  static const String studentAIFoodScanner = '/student/ai-food-scanner';

  /// 身体数据记录页
  static const String studentBodyStatsRecord = '/student/body-stats-record';

  /// 身体数据历史页
  static const String studentBodyStatsHistory = '/student/body-stats-history';

  /// 训练记录页
  static const String studentExerciseRecord = '/student/exercise-record';

  /// 学生训练日历页
  static const String studentTrainingCalendar =
      '/students/:studentId/training-calendar';

  // ==================== 教练端路由 ====================

  /// 教练首页
  static const String coachHome = '/coach/home';

  /// 学生列表页
  static const String coachStudents = '/coach/students';

  /// 计划管理页
  static const String coachPlans = '/coach/plans';

  /// 教练对话页
  static const String coachChat = '/coach/chat';

  /// 教练资料页
  static const String coachProfile = '/coach/profile';

  /// 训练审核列表页
  static const String coachTrainingReviews = '/coach/training-reviews';

  /// 训练批阅 Feed 页
  static const String trainingFeed = '/coach/training-feed/:dailyTrainingId';

  /// 创建补剂计划页
  static const String createSupplementPlan = 'create-supplement-plan';

  // ==================== 共享路由 ====================

  /// 语言选择页
  static const String languageSelection = '/language-selection';

  /// 计划详情页（带参数）
  static const String planDetail = '/plan/:id';

  /// 训练详情页（带参数）
  static const String trainingDetail = '/training/:id';

  /// 对话详情页（带参数）
  static const String chatDetail = '/chat/:conversationId';

  /// 每日训练总结页（带参数）
  static const String dailyTrainingSummary =
      '/daily-training-summary/:dailyTrainingId';

  // ==================== 工具方法 ====================

  /// 获取计划详情路由（替换参数）
  static String getPlanDetailRoute(String id) {
    return '/plan/$id';
  }

  /// 获取训练详情路由（替换参数）
  static String getTrainingDetailRoute(String id) {
    return '/training/$id';
  }

  /// 获取对话详情路由（替换参数）
  static String getChatDetailRoute(String conversationId) {
    return '/chat/$conversationId';
  }

  /// 获取训练批阅 Feed 路由（替换参数）
  static String getTrainingFeedRoute(
    String dailyTrainingId, {
    required String studentId,
    required String studentName,
  }) {
    return '/coach/training-feed/$dailyTrainingId?studentId=$studentId&studentName=$studentName';
  }

  /// 获取每日训练总结路由（替换参数）
  static String getDailyTrainingSummaryRoute(String dailyTrainingId) {
    return '/daily-training-summary/$dailyTrainingId';
  }

  /// 获取训练日历页面路由
  static String getTrainingCalendarRoute(
    String studentId, {
    String? focusDate,
  }) {
    final base = '/students/$studentId/training-calendar';
    if (focusDate == null || focusDate.isEmpty) {
      return base;
    }
    final encodedDate = Uri.encodeComponent(focusDate);
    return '$base?date=$encodedDate';
  }
}
