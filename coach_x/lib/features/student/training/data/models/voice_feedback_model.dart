import 'package:coach_x/core/utils/json_utils.dart';

/// 语音反馈模型
///
/// 用于记录学生对训练动作的语音反馈
class VoiceFeedbackModel {
  final String id;
  final String filePath; // Firebase Storage 路径
  final int duration; // 时长（秒）
  final int uploadTime; // 上传时间戳（毫秒）
  final String formatTime; // 格式化时间字符串
  final String tempUrl; // 临时下载 URL

  const VoiceFeedbackModel({
    required this.id,
    required this.filePath,
    required this.duration,
    required this.uploadTime,
    required this.formatTime,
    this.tempUrl = '',
  });

  /// 从 JSON 创建
  factory VoiceFeedbackModel.fromJson(Map<String, dynamic> json) {
    return VoiceFeedbackModel(
      id: json['id'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      duration: safeIntCast(json['duration'], 0, 'duration') ?? 0,
      uploadTime: safeIntCast(json['uploadTime'], 0, 'uploadTime') ?? 0,
      formatTime: json['formatTime'] as String? ?? '',
      tempUrl: json['tempUrl'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'duration': duration,
      'uploadTime': uploadTime,
      'formatTime': formatTime,
      'tempUrl': tempUrl,
    };
  }

  /// 复制并修改部分字段
  VoiceFeedbackModel copyWith({
    String? id,
    String? filePath,
    int? duration,
    int? uploadTime,
    String? formatTime,
    String? tempUrl,
  }) {
    return VoiceFeedbackModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      uploadTime: uploadTime ?? this.uploadTime,
      formatTime: formatTime ?? this.formatTime,
      tempUrl: tempUrl ?? this.tempUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceFeedbackModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath &&
          duration == other.duration &&
          uploadTime == other.uploadTime;

  @override
  int get hashCode =>
      id.hashCode ^ filePath.hashCode ^ duration.hashCode ^ uploadTime.hashCode;

  @override
  String toString() {
    return 'VoiceFeedbackModel(id: $id, duration: $duration, uploadTime: $uploadTime)';
  }
}
