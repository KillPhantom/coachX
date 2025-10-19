/// CoachX API常量定义
/// 包含API相关的常量配置
class ApiConstants {
  ApiConstants._(); // 私有构造函数，防止实例化

  // ==================== 基础配置 ====================

  /// API基础URL（开发环境）
  /// TODO: 替换为实际的Firebase Cloud Functions URL
  static const String baseUrlDev = 'https://your-project.cloudfunctions.net';

  /// API基础URL（生产环境）
  /// TODO: 替换为实际的Firebase Cloud Functions URL
  static const String baseUrlProd = 'https://your-project.cloudfunctions.net';

  /// 当前使用的基础URL
  static const String baseUrl = baseUrlDev; // 根据环境切换

  // ==================== API版本 ====================

  /// API版本
  static const String apiVersion = 'v1';

  // ==================== 请求头 ====================

  /// Content-Type
  static const String contentType = 'application/json';

  /// Accept
  static const String accept = 'application/json';

  /// Authorization前缀
  static const String authPrefix = 'Bearer';

  // ==================== 用户相关API ====================

  /// 登录
  static const String login = '/login';

  /// 获取用户信息
  static const String fetchUserInfo = '/fetchUserInfo';

  /// 更新用户信息
  static const String updateUserInfo = '/updateUserInfo';

  // ==================== 学员与统计API ====================

  /// 获取学员列表
  static const String fetchStudents = '/fetchStudents';

  /// 获取学员统计
  static const String fetchStudentsStats = '/fetchStudentsStats';

  // ==================== 计划相关API ====================

  /// 训练计划操作
  static const String exercisePlan = '/exercisePlan';

  /// 饮食计划操作
  static const String dietPlan = '/dietPlan';

  /// 补剂计划操作
  static const String supplementPlan = '/supplementPlan';

  /// 分配计划
  static const String assignPlan = '/assignPlan';

  /// 获取学生计划
  static const String getStudentPlans = '/getStudentPlans';

  // ==================== 学生训练API ====================

  /// 更新今日训练
  static const String upsertTodayTraining = '/upsertTodayTraining';

  /// 获取今日训练
  static const String fetchTodayTraining = '/fetchTodayTraining';

  /// 获取训练历史
  static const String fetchTrainingHistory = '/fetchTrainingHistory';

  /// 获取最新训练
  static const String fetchLatestTraining = '/fetchLatestTraining';

  /// 获取未审核训练
  static const String fetchUnreviewedTrainings = '/fetchUnreviewedTrainings';

  // ==================== 动作反馈API ====================

  /// 更新动作反馈
  static const String upsertExerciseFeedback = '/upsertExerciseFeedback';

  /// 获取动作反馈
  static const String getExerciseFeedback = '/getExerciseFeedback';

  /// 获取历史反馈
  static const String getExerciseHistoryFeedback =
      '/getExerciseHistoryFeedback';

  // ==================== 身体测量API ====================

  /// 保存测量数据
  static const String saveMeasurementSession = '/saveMeasurementSession';

  /// 删除测量数据
  static const String deleteMeasurementSession = '/deleteMeasurementSession';

  /// 获取测量数据
  static const String fetchMeasurementSessions = '/fetchMeasurementSessions';

  // ==================== 食物库API ====================

  /// 食物库操作
  static const String foodLibrary = '/foodLibrary';

  // ==================== 邀请码API ====================

  /// 获取邀请码
  static const String fetchInvitationCode = '/fetchInvitationCode';

  /// 验证邀请码
  static const String verifyInvitationCode = '/verifyInvitationCode';

  /// 生成邀请码
  static const String generateInvitationCodes = '/generateInvitationCodes';

  /// 生成学生邀请码
  static const String generateStudentInvitationCode =
      '/generateStudentInvitationCode';

  // ==================== AI生成API ====================

  /// AI生成训练计划
  static const String generateAITrainingPlan = '/generateAITrainingPlan';

  // ==================== Firebase Storage路径 ====================

  /// 用户头像路径
  static const String userAvatarsPath = 'avatars';

  /// 训练视频路径
  static const String trainingVideosPath = 'training_videos';

  /// 训练图片路径
  static const String trainingImagesPath = 'training_images';

  /// 身体测量图片路径
  static const String bodyStatsImagesPath = 'body_stats';

  /// 饮食图片路径
  static const String dietImagesPath = 'diet_images';
}
