/// 路由名称常量
/// 定义应用中所有的路由路径
class RouteNames {
  RouteNames._(); // 私有构造函数，防止实例化

  // ==================== 根路由 ====================

  /// 启动页
  static const String splash = '/';

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

  /// 学生饮食记录页
  static const String studentDietRecord = '/student/diet-record';

  /// AI食物扫描页
  static const String studentAIFoodScanner = '/student/ai-food-scanner';

  /// 身体数据记录页
  static const String studentBodyStatsRecord = '/student/body-stats-record';

  /// 身体数据历史页
  static const String studentBodyStatsHistory = '/student/body-stats-history';

  /// 训练记录页
  static const String studentExerciseRecord = '/student/exercise-record';

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

  /// 创建补剂计划页
  static const String createSupplementPlan = 'create-supplement-plan';

  // ==================== 共享路由 ====================

  /// 计划详情页（带参数）
  static const String planDetail = '/plan/:id';

  /// 训练详情页（带参数）
  static const String trainingDetail = '/training/:id';

  /// 对话详情页（带参数）
  static const String chatDetail = '/chat/:conversationId';

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
}
