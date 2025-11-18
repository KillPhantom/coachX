/// 视频源选项
///
/// 用于配置视频上传组件支持的视频源
enum VideoSource {
  /// 支持相机录制和相册选择
  both,

  /// 仅支持相机录制
  cameraOnly,

  /// 仅支持从相册选择
  galleryOnly,
}
