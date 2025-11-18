/// 视频关键帧模型
class KeyframeModel {
  final String? url; // 远程URL（可能为null，如果还未上传）
  final String? localPath; // 本地文件路径（可能为null，如果是远程的）
  final double timestamp; // 时间戳（秒）
  final String? uploadStatus; // 上传状态：pending/uploading/uploaded/failed

  const KeyframeModel({
    this.url,
    this.localPath,
    required this.timestamp,
    this.uploadStatus,
  });

  /// 从 JSON 创建
  factory KeyframeModel.fromJson(Map<String, dynamic> json) {
    return KeyframeModel(
      url: json['url'] as String?,
      localPath: json['localPath'] as String?,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      uploadStatus: json['uploadStatus'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'localPath': localPath,
      'timestamp': timestamp,
      'uploadStatus': uploadStatus,
    };
  }

  /// 格式化时间戳为 mm:ss 格式
  String get formattedTimestamp {
    final minutes = (timestamp ~/ 60).toString().padLeft(2, '0');
    final seconds = (timestamp % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 复制并修改
  KeyframeModel copyWith({
    String? url,
    String? localPath,
    double? timestamp,
    String? uploadStatus,
  }) {
    return KeyframeModel(
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      timestamp: timestamp ?? this.timestamp,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  @override
  String toString() {
    return 'KeyframeModel(url: $url, localPath: $localPath, timestamp: $timestamp, uploadStatus: $uploadStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KeyframeModel &&
        other.url == url &&
        other.localPath == localPath &&
        other.timestamp == timestamp &&
        other.uploadStatus == uploadStatus;
  }

  @override
  int get hashCode =>
      url.hashCode ^
      localPath.hashCode ^
      timestamp.hashCode ^
      uploadStatus.hashCode;
}
