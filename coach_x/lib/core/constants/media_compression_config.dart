/// 媒体压缩配置
///
/// 统一管理所有图片和视频的压缩参数
class MediaCompressionConfig {
  MediaCompressionConfig._();

  // ==================== 图片压缩配置 ====================

  /// AI 识别用图片压缩配置（优先速度，降低质量）
  ///
  /// 用于：食物识别、训练动作识别等 AI 分析场景
  /// - 质量：70% (足够 AI 识别，Claude Vision 推荐)
  /// - 尺寸：1024px (降低文件大小，加快上传)
  static const int aiFoodImageQuality = 70;
  static const int aiFoodImageMaxSize = 1024;

  /// 用户查看用图片压缩配置（平衡质量和速度）
  ///
  /// 用于：身体测量照片、训练记录照片等用户需要查看的场景
  /// - 质量：80% (保持较好的视觉效果)
  /// - 尺寸：1280px (适合手机屏幕查看)
  static const int userImageQuality = 80;
  static const int userImageMaxSize = 1280;

  /// 缩略图压缩配置（最小化文件大小）
  ///
  /// 用于：视频缩略图、列表预览图等
  /// - 质量：75%
  /// - 尺寸：512px (缩略图不需要高分辨率)
  static const int thumbnailQuality = 75;
  static const int thumbnailMaxSize = 512;

  /// 视频帧提取配置
  ///
  /// 用于：训练视频关键帧提取
  /// - 质量：70% (足够识别动作)
  /// - 尺寸：1024px
  static const int videoFrameQuality = 70;
  static const int videoFrameMaxSize = 1024;

  // ==================== 上传配置 ====================

  /// 最大重试次数
  static const int maxUploadRetries = 3;

  /// 上传总超时时间
  static const Duration uploadTimeout = Duration(seconds: 30);

  /// 进度停滞超时时间（如果在此时间内进度无更新，则认为上传卡住）
  static const Duration progressStaleTimeout = Duration(seconds: 30);

  /// 重试延迟基数（指数退避：2^attempt 秒）
  static const int retryDelayBase = 2;
}
