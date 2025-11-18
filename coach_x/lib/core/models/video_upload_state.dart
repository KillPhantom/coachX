/// 视频上传状态
enum VideoUploadStatus {
  pending, // 等待上传（压缩中）
  uploading, // 上传中
  completed, // 已完成
  error, // 上传失败
}

/// 视频上传状态模型
class VideoUploadState {
  /// 本地文件路径
  final String? localPath;

  /// 缩略图路径（本地临时文件）
  final String? thumbnailPath;

  /// Firebase Storage 下载 URL
  final String? downloadUrl;

  /// 缩略图下载 URL（Firebase Storage）
  final String? thumbnailUrl;

  /// 上传状态
  final VideoUploadStatus status;

  /// 上传进度 (0.0 - 1.0)
  final double progress;

  /// 错误信息
  final String? error;

  const VideoUploadState({
    this.localPath,
    this.thumbnailPath,
    this.downloadUrl,
    this.thumbnailUrl,
    required this.status,
    this.progress = 0.0,
    this.error,
  });

  /// 创建 pending 状态
  factory VideoUploadState.pending(String localPath, String? thumbnailPath) {
    return VideoUploadState(
      localPath: localPath,
      thumbnailPath: thumbnailPath,
      status: VideoUploadStatus.pending,
      progress: 0.0,
    );
  }

  /// 创建 completed 状态（从服务器加载）
  factory VideoUploadState.completed(
    String downloadUrl, {
    String? thumbnailUrl,
  }) {
    return VideoUploadState(
      downloadUrl: downloadUrl,
      thumbnailUrl: thumbnailUrl,
      status: VideoUploadStatus.completed,
      progress: 1.0,
    );
  }

  /// 复制并修改
  VideoUploadState copyWith({
    String? localPath,
    String? thumbnailPath,
    String? downloadUrl,
    String? thumbnailUrl,
    VideoUploadStatus? status,
    double? progress,
    String? error,
  }) {
    return VideoUploadState(
      localPath: localPath ?? this.localPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }

  /// 转换为 JSON（只保存已完成的视频）
  Map<String, dynamic>? toJson() {
    if (status == VideoUploadStatus.completed && downloadUrl != null) {
      return {'videoUrl': downloadUrl, 'thumbnailUrl': thumbnailUrl};
    }
    return null; // 未完成的不保存
  }

  /// 从 JSON 创建
  factory VideoUploadState.fromJson(Map<String, dynamic> data) {
    return VideoUploadState.completed(
      data['videoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
    );
  }
}
