/// CoachX 应用级常量定义
class AppConstants {
  AppConstants._(); // 私有构造函数，防止实例化

  // ==================== 应用信息 ====================

  /// 应用名称
  static const String appName = 'CoachX';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 构建号
  static const String buildNumber = '1';

  // ==================== 网络配置 ====================

  /// 请求超时时间（毫秒）
  static const int connectionTimeout = 30000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 30000;

  /// 发送超时时间（毫秒）
  static const int sendTimeout = 30000;

  // ==================== 分页配置 ====================

  /// 默认每页数量
  static const int defaultPageSize = 20;

  /// 最大每页数量
  static const int maxPageSize = 50;

  // ==================== 文件上传配置 ====================

  /// 图片最大大小（字节）- 5MB
  static const int maxImageSize = 5 * 1024 * 1024;

  /// 视频最大大小（字节）- 50MB
  static const int maxVideoSize = 50 * 1024 * 1024;

  /// 图片最大宽度
  static const int maxImageWidth = 1920;

  /// 图片最大高度
  static const int maxImageHeight = 1920;

  /// 图片压缩质量 (0-100)
  static const int imageQuality = 85;

  /// 视频时长限制（秒）
  static const int maxVideoSeconds = 60;

  /// 视频压缩阈值（MB）
  static const int videoCompressionThresholdMB = 50;

  /// 每个动作最多上传视频数量
  static const int maxVideosPerExercise = 3;

  // ==================== 日期格式 ====================

  /// 日期格式 yyyy-MM-dd
  static const String dateFormat = 'yyyy-MM-dd';

  /// 时间格式 HH:mm
  static const String timeFormat = 'HH:mm';

  /// 日期时间格式 yyyy-MM-dd HH:mm
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  /// 日期时间秒格式 yyyy-MM-dd HH:mm:ss
  static const String dateTimeSecondFormat = 'yyyy-MM-dd HH:mm:ss';

  // ==================== 动画时长 ====================

  /// 短动画时长（毫秒）
  static const int animationDurationShort = 200;

  /// 中等动画时长（毫秒）
  static const int animationDurationMedium = 300;

  /// 长动画时长（毫秒）
  static const int animationDurationLong = 500;

  // ==================== 缓存配置 ====================

  /// 缓存过期时间（天）
  static const int cacheExpireDays = 7;

  /// 图片缓存最大数量
  static const int maxImageCacheCount = 200;

  // ==================== Firebase Emulator 配置 ====================

  /// Firebase Emulator 主机地址
  ///
  /// 📱 真实设备调试时的配置说明：
  /// 1. 获取你的 Mac 局域网 IP：终端运行 `ipconfig getifaddr en0`
  /// 2. 将下面的 IP 改为你的 Mac 局域网 IP（例如：'192.168.1.100'）
  /// 3. 确保 Firebase Emulator 绑定到 0.0.0.0（见 firebase.json）
  /// 4. 确保你的 iPhone 和 Mac 在同一局域网 (192.168.1.114)
  ///
  /// 💻 iOS 模拟器调试时：
  /// - 使用 '127.0.0.1' 即可
  static const String firebaseEmulatorHost = '192.168.1.114';

  /// Firebase Functions Emulator 端口
  static const int firebaseFunctionsEmulatorPort = 5001;

  /// Firebase Firestore Emulator 端口
  static const int firebaseFirestoreEmulatorPort = 8080;

  // ==================== 其他配置 ====================

  /// 密码最小长度
  static const int minPasswordLength = 6;

  /// 密码最大长度
  static const int maxPasswordLength = 20;

  /// 用户名最小长度
  static const int minUsernameLength = 2;

  /// 用户名最大长度
  static const int maxUsernameLength = 20;

  /// 邀请码长度
  static const int invitationCodeLength = 8;
}
