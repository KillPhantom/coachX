/// 路由名称常量
/// 定义应用中所有的路由路径
class RouteNames {
  RouteNames._(); // 私有构造函数，防止实例化

  // ==================== 根路由 ====================

  /// 启动页
  static const String splash = '/';

  /// 登录页
  static const String login = '/login';

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

  // ==================== 共享路由 ====================

  /// 计划详情页（带参数）
  static const String planDetail = '/plan/:id';

  /// 训练详情页（带参数）
  static const String trainingDetail = '/training/:id';

  // ==================== 工具方法 ====================

  /// 获取计划详情路由（替换参数）
  static String getPlanDetailRoute(String id) {
    return '/plan/$id';
  }

  /// 获取训练详情路由（替换参数）
  static String getTrainingDetailRoute(String id) {
    return '/training/$id';
  }
}
