import 'package:coach_x/core/utils/json_utils.dart';

/// 训练反馈模型
///
/// 对应后端 dailyTrainingFeedback collection
/// 支持：
/// - 整体训练反馈（exerciseIndex = null）
/// - 针对具体 exercise 的反馈（exerciseIndex = 0, 1, 2...）
/// - 按 exerciseName 查询历史反馈
class TrainingFeedbackModel {
  // === 核心关联 ===
  final String id;
  final String dailyTrainingId; // 关联到 dailyTraining 记录
  final String studentId;
  final String coachId;
  final String trainingDate; // 格式: "yyyy-MM-dd"

  // === Exercise 关联（可选）===
  final String? exerciseTemplateId; // 可选，视频项填写，图文项不填
  final String? exerciseName; // "深蹲", "卧推" - 冗余存储，方便历史查询

  // === 反馈内容 ===
  final String feedbackType; // "text" | "voice" | "image"
  final String? textContent; // 文字反馈内容
  final String? voiceUrl; // 语音文件URL
  final int? voiceDuration; // 语音时长（秒）
  final String? imageUrl; // 图片URL
  final String? videoUrl; // 视频URL
  final String? videoThumbnailUrl; // 视频缩略图URL
  final int? videoDuration; // 视频时长（秒）

  // === 元数据 ===
  final int createdAt; // 反馈创建时间（毫秒时间戳）
  final bool isRead; // 学生是否已读

  const TrainingFeedbackModel({
    required this.id,
    required this.dailyTrainingId,
    required this.studentId,
    required this.coachId,
    required this.trainingDate,
    this.exerciseTemplateId,
    this.exerciseName,
    required this.feedbackType,
    this.textContent,
    this.voiceUrl,
    this.voiceDuration,
    this.imageUrl,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoDuration,
    required this.createdAt,
    this.isRead = false,
  });

  /// 从 JSON 创建
  factory TrainingFeedbackModel.fromJson(Map<String, dynamic> json) {
    return TrainingFeedbackModel(
      id: json['id'] as String? ?? '',
      dailyTrainingId: json['dailyTrainingId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      trainingDate: json['trainingDate'] as String? ?? '',
      exerciseTemplateId: json['exerciseTemplateId'] as String?,
      exerciseName: json['exerciseName'] as String?,
      feedbackType: json['feedbackType'] as String? ?? 'text',
      textContent: json['textContent'] as String?,
      voiceUrl: json['voiceUrl'] as String?,
      voiceDuration: safeIntCast(json['voiceDuration'], null, 'voiceDuration'),
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoThumbnailUrl: json['videoThumbnailUrl'] as String?,
      videoDuration: safeIntCast(json['videoDuration'], null, 'videoDuration'),
      createdAt: safeIntCast(json['createdAt'], 0, 'createdAt') ?? 0,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dailyTrainingId': dailyTrainingId,
      'studentId': studentId,
      'coachId': coachId,
      'trainingDate': trainingDate,
      'exerciseTemplateId': exerciseTemplateId,
      'exerciseName': exerciseName,
      'feedbackType': feedbackType,
      'textContent': textContent,
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
      'videoDuration': videoDuration,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  /// 复制并修改部分字段
  TrainingFeedbackModel copyWith({
    String? id,
    String? dailyTrainingId,
    String? studentId,
    String? coachId,
    String? trainingDate,
    String? exerciseTemplateId,
    String? exerciseName,
    String? feedbackType,
    String? textContent,
    String? voiceUrl,
    int? voiceDuration,
    String? imageUrl,
    String? videoUrl,
    String? videoThumbnailUrl,
    int? videoDuration,
    int? createdAt,
    bool? isRead,
  }) {
    return TrainingFeedbackModel(
      id: id ?? this.id,
      dailyTrainingId: dailyTrainingId ?? this.dailyTrainingId,
      studentId: studentId ?? this.studentId,
      coachId: coachId ?? this.coachId,
      trainingDate: trainingDate ?? this.trainingDate,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      exerciseName: exerciseName ?? this.exerciseName,
      feedbackType: feedbackType ?? this.feedbackType,
      textContent: textContent ?? this.textContent,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// 是否为整体反馈（不针对特定 exercise）
  bool get isOverallFeedback => exerciseTemplateId == null;

  /// 是否为 exercise 级别的反馈
  bool get isExerciseFeedback => exerciseTemplateId != null;

  /// 获取创建时间的 DateTime 对象
  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingFeedbackModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TrainingFeedbackModel(id: $id, dailyTrainingId: $dailyTrainingId, '
        'exerciseTemplateId: $exerciseTemplateId, exerciseName: $exerciseName, '
        'feedbackType: $feedbackType, trainingDate: $trainingDate)';
  }
}
