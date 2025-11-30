/// 媒体类型
enum MediaType {
  video,
  image,
}

/// 媒体上传状态
enum MediaUploadStatus {
  pending, // 等待处理
  compressing, // 压缩中（仅视频）
  uploading, // 上传中
  completed, // 已完成
  error, // 上传失败
}

/// 媒体上传状态模型
class MediaUploadState {
  /// 本地文件路径
  final String? localPath;

  /// 缩略图路径（本地临时文件，仅视频）
  final String? thumbnailPath;

  /// Firebase Storage 下载 URL
  final String? downloadUrl;

  /// 缩略图下载 URL（Firebase Storage，仅视频）
  final String? thumbnailUrl;

  /// 上传状态
  final MediaUploadStatus status;

  /// 上传进度 (0.0 - 1.0)
  final double progress;

  /// 错误信息
  final String? error;

  /// 媒体类型
  final MediaType type;

  const MediaUploadState({
    this.localPath,
    this.thumbnailPath,
    this.downloadUrl,
    this.thumbnailUrl,
    required this.status,
    this.progress = 0.0,
    this.error,
    this.type = MediaType.video,
  });

  /// 创建 pending 状态
  factory MediaUploadState.pending({
    required String localPath,
    String? thumbnailPath,
    required MediaType type,
  }) {
    return MediaUploadState(
      localPath: localPath,
      thumbnailPath: thumbnailPath,
      status: MediaUploadStatus.pending,
      progress: 0.0,
      type: type,
    );
  }

  /// 创建 completed 状态（从服务器加载）
  factory MediaUploadState.completed({
    required String downloadUrl,
    String? thumbnailUrl,
    MediaType type = MediaType.video,
  }) {
    return MediaUploadState(
      downloadUrl: downloadUrl,
      thumbnailUrl: thumbnailUrl,
      status: MediaUploadStatus.completed,
      progress: 1.0,
      type: type,
    );
  }

  /// 复制并修改
  MediaUploadState copyWith({
    String? localPath,
    String? thumbnailPath,
    String? downloadUrl,
    String? thumbnailUrl,
    MediaUploadStatus? status,
    double? progress,
    String? error,
    MediaType? type,
  }) {
    return MediaUploadState(
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      type: type ?? this.type,
    );
  }

  /// 转换为 JSON（只保存已完成的媒体）
  Map<String, dynamic>? toJson() {
    if (status == MediaUploadStatus.completed && downloadUrl != null) {
      return {
        'url': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
        'type': type.name,
      };
    }
    return null; // 未完成的不保存
  }

  /// 从 JSON 创建
  factory MediaUploadState.fromJson(Map<String, dynamic> data) {
    // 兼容旧的 videoUrl 字段
    // 安全地获取 URL，如果都为 null 则使用空字符串
    final url = data['url'] as String? ?? data['videoUrl'] as String? ?? '';
    
    // 解析类型，默认为 video (兼容旧数据)
    final typeStr = data['type'] as String?;
    final type = typeStr != null 
        ? MediaType.values.firstWhere(
            (e) => e.name == typeStr, 
            orElse: () => MediaType.video
          )
        : MediaType.video;

    return MediaUploadState.completed(
      downloadUrl: url,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      type: type,
    );
  }
}

