import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/student/training/data/models/keyframe_model.dart';

/// 提取的关键帧数据模型
///
/// 存储在 dailyTraining 的 extractedKeyFrames 字段中
class ExtractedKeyFrameModel {
  final String exerciseName;
  final List<KeyframeModel> keyframes;
  final String method;

  const ExtractedKeyFrameModel({
    required this.exerciseName,
    required this.keyframes,
    this.method = 'mediapipe_pose',
  });

  factory ExtractedKeyFrameModel.fromJson(Map<String, dynamic> json) {
    final keyframesData = safeMapListCast(json['keyframes'], 'keyframes');

    return ExtractedKeyFrameModel(
      exerciseName: json['exerciseName'] as String? ?? '',
      keyframes: keyframesData.map((kf) => KeyframeModel.fromJson(kf)).toList(),
      method: json['method'] as String? ?? 'mediapipe_pose',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'keyframes': keyframes.map((kf) => kf.toJson()).toList(),
      'method': method,
    };
  }

  ExtractedKeyFrameModel copyWith({
    String? exerciseName,
    List<KeyframeModel>? keyframes,
    String? method,
  }) {
    return ExtractedKeyFrameModel(
      exerciseName: exerciseName ?? this.exerciseName,
      keyframes: keyframes ?? this.keyframes,
      method: method ?? this.method,
    );
  }

  @override
  String toString() {
    return 'ExtractedKeyFrameModel(exerciseName: $exerciseName, keyframes: ${keyframes.length}, method: $method)';
  }
}
