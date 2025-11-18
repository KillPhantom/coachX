import 'video_upload_state.dart';

/// 标准化的视频数据模型
class VideoModel {
  /// 视频 URL
  final String videoUrl;

  /// 缩略图 URL
  final String? thumbnailUrl;

  /// 是否已批阅
  final bool isReviewed;

  /// 视频时长（秒）
  final int? duration;

  const VideoModel({
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isReviewed,
    this.duration,
  });

  /// 从 VideoUploadState 转换
  factory VideoModel.fromVideoUploadState(VideoUploadState state) {
    return VideoModel(
      videoUrl: state.downloadUrl ?? '',
      thumbnailUrl: state.thumbnailUrl,
      isReviewed: false, // 默认未批阅
      duration: null, // VideoUploadState 中没有 duration
    );
  }

  /// 从 JSON 转换
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
      duration: json['duration'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'isReviewed': isReviewed,
      'duration': duration,
    };
  }

  /// 创建副本
  VideoModel copyWith({
    String? videoUrl,
    String? thumbnailUrl,
    bool? isReviewed,
    int? duration,
  }) {
    return VideoModel(
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isReviewed: isReviewed ?? this.isReviewed,
      duration: duration ?? this.duration,
    );
  }
}
