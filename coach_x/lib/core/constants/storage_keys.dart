/// CoachX 本地存储键名常量
/// 用于SharedPreferences和Hive的键名管理
class StorageKeys {
  StorageKeys._(); // 私有构造函数，防止实例化

  // ==================== 用户相关 ====================

  /// 用户Token
  static const String userToken = 'user_token';

  /// 用户ID
  static const String userId = 'user_id';

  /// 用户角色（student/coach）
  static const String userRole = 'user_role';

  /// 用户信息
  static const String userInfo = 'user_info';

  /// 是否已登录
  static const String isLoggedIn = 'is_logged_in';

  // ==================== 应用设置 ====================

  /// 是否首次启动
  static const String isFirstLaunch = 'is_first_launch';

  /// 是否显示引导页
  static const String showGuide = 'show_guide';

  /// 语言设置
  static const String language = 'language';

  /// 主题模式（light/dark）
  static const String themeMode = 'theme_mode';

  // ==================== 缓存相关 ====================

  /// 训练计划缓存
  static const String trainingPlansCache = 'training_plans_cache';

  /// 饮食计划缓存
  static const String dietPlansCache = 'diet_plans_cache';

  /// 补剂计划缓存
  static const String supplementPlansCache = 'supplement_plans_cache';

  /// 训练记录缓存
  static const String trainingRecordsCache = 'training_records_cache';

  /// 缓存更新时间
  static const String cacheUpdateTime = 'cache_update_time';

  // ==================== 草稿相关 ====================

  /// 训练记录草稿
  static const String trainingDraft = 'training_draft';

  /// 饮食记录草稿
  static const String dietDraft = 'diet_draft';

  /// 补剂记录草稿
  static const String supplementDraft = 'supplement_draft';

  // ==================== 消息相关 ====================

  /// 未读消息数量
  static const String unreadMessageCount = 'unread_message_count';

  /// 最后消息ID
  static const String lastMessageId = 'last_message_id';

  /// 消息草稿
  static const String messageDraft = 'message_draft';

  // ==================== Hive Box名称 ====================

  /// 用户数据Box
  static const String userBox = 'user_box';

  /// 计划数据Box
  static const String planBox = 'plan_box';

  /// 训练记录Box
  static const String recordBox = 'record_box';

  /// 缓存数据Box
  static const String cacheBox = 'cache_box';
}
