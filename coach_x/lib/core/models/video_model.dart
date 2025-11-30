import 'media_upload_state.dart';

/// 标准化的视频/媒体数据模型
class VideoModel {
  /// 视频/媒体 URL
  final String videoUrl;

  /// 缩略图 URL
  final String? thumbnailUrl;

  /// 是否已批阅
  final bool isReviewed;

  /// 视频时长（秒）
  final int? duration;

  /// 媒体类型
  final MediaType type;

  const VideoModel({
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isReviewed,
    this.duration,
    this.type = MediaType.video,
  });

  /// 从 MediaUploadState 转换
  factory VideoModel.fromMediaUploadState(MediaUploadState state) {
    return VideoModel(
      videoUrl: state.downloadUrl ?? '',
      thumbnailUrl: state.thumbnailUrl,
      isReviewed: false, // 默认未批阅
      duration: null, // MediaUploadState 中没有 duration
      type: state.type,
    );
  }

  /// 从 JSON 转换
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    // 解析类型
    final typeStr = json['type'] as String?;
    final type = typeStr != null 
        ? MediaType.values.firstWhere(
            (e) => e.name == typeStr, 
            orElse: () => MediaType.video
          )
        : MediaType.video;

    return VideoModel(
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
      duration: json['duration'] as int?,
      type: type,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'isReviewed': isReviewed,
      'duration': duration,
      'type': type.name,
    };
  }

  /// 创建副本
  VideoModel copyWith({
    String? videoUrl,
    String? thumbnailUrl,
    bool? isReviewed,
    int? duration,
    MediaType? type,
  }) {
    return VideoModel(
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isReviewed: isReviewed ?? this.isReviewed,
      duration: duration ?? this.duration,
      type: type ?? this.type,
    );
  }
}
