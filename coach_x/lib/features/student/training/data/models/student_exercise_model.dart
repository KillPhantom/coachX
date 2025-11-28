import 'package:coach_x/core/enums/exercise_type.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/core/models/video_upload_state.dart';
import 'keyframe_model.dart';

/// 学生训练动作模型
///
/// 用于 dailyTraining 中记录学生完成的训练动作
class StudentExerciseModel {
  final String name;
  final String note;
  final ExerciseType type;
  final List<TrainingSet> sets;
  final bool completed;
  final List<VideoUploadState> videos; // 学生上传的视频状态
  final List<KeyframeModel> keyframes; // 视频关键帧（带时间戳）
  final int? timeSpent; // 动作耗时（秒数），nullable
  final String? exerciseTemplateId; // 关联的动作模板 ID
  final bool isReviewed; // 是否已批阅

  const StudentExerciseModel({
    required this.name,
    this.note = '',
    this.type = ExerciseType.strength,
    required this.sets,
    this.completed = false,
    this.videos = const [],
    this.keyframes = const [],
    this.timeSpent,
    this.exerciseTemplateId,
    this.isReviewed = false,
  });

  /// 创建空的 StudentExercise
  factory StudentExerciseModel.empty() {
    return StudentExerciseModel(
      name: '',
      note: '',
      type: ExerciseType.strength,
      sets: [TrainingSet.empty()],
      completed: false,
      videos: const [],
      keyframes: const [],
      timeSpent: null,
      isReviewed: false,
    );
  }

  /// 从 JSON 创建
  factory StudentExerciseModel.fromJson(Map<String, dynamic> json) {
    final setsData = safeMapListCast(json['sets'], 'sets');
    final sets = setsData
        .map((setJson) => TrainingSet.fromJson(setJson))
        .toList();

    return StudentExerciseModel(
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      type: exerciseTypeFromString(json['type'] as String? ?? 'strength'),
      sets: sets.isNotEmpty ? sets : [TrainingSet.empty()],
      completed: json['completed'] as bool? ?? false,
      videos:
          (json['videos'] as List<dynamic>?)?.map((data) {
            final videoData = safeMapCast(data, 'video');
            return videoData != null
                ? VideoUploadState.fromJson(videoData)
                : VideoUploadState.completed(''); // 降级处理
          }).toList() ??
          [],
      keyframes:
          (json['keyframes'] as List<dynamic>?)?.map((e) {
            if (e is String) {
              // 兼容旧格式：纯URL字符串
              return KeyframeModel(url: e, timestamp: 0.0);
            } else if (e is Map) {
              // 新格式：带时间戳的对象
              final keyframeData = safeMapCast(e, 'keyframe');
              return keyframeData != null
                  ? KeyframeModel.fromJson(keyframeData)
                  : KeyframeModel(url: '', timestamp: 0.0);
            }
            return KeyframeModel(url: '', timestamp: 0.0);
          }).toList() ??
          [],
      timeSpent: json['timeSpent'] as int?,
      exerciseTemplateId: json['exerciseTemplateId'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'note': note,
      'type': type.toJsonString(),
      'sets': sets.map((set) => set.toJson()).toList(),
      'completed': completed,
      'videos': videos
          .map((v) => v.toJson())
          .where((url) => url != null) // 只保存已完成的
          .toList(),
      'keyframes': keyframes.map((kf) => kf.toJson()).toList(),
      'timeSpent': timeSpent,
      if (exerciseTemplateId != null) 'exerciseTemplateId': exerciseTemplateId,
      'isReviewed': isReviewed,
    };
  }

  /// 复制并修改部分字段
  StudentExerciseModel copyWith({
    String? name,
    String? note,
    ExerciseType? type,
    List<TrainingSet>? sets,
    bool? completed,
    List<VideoUploadState>? videos,
    List<KeyframeModel>? keyframes,
    int? timeSpent,
    String? exerciseTemplateId,
    bool? isReviewed,
  }) {
    return StudentExerciseModel(
      name: name ?? this.name,
      note: note ?? this.note,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      completed: completed ?? this.completed,
      videos: videos ?? this.videos,
      keyframes: keyframes ?? this.keyframes,
      timeSpent: timeSpent ?? this.timeSpent,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  /// 添加待上传视频
  StudentExerciseModel addPendingVideo(
    String localPath,
    String? thumbnailPath,
  ) {
    final newVideo = VideoUploadState.pending(localPath, thumbnailPath);
    return copyWith(videos: [...videos, newVideo]);
  }

  /// 更新视频上传进度
  StudentExerciseModel updateVideoProgress(int index, double progress) {
    if (index < 0 || index >= videos.length) return this;

    final updatedVideos = List<VideoUploadState>.from(videos);
    updatedVideos[index] = videos[index].copyWith(
      status: VideoUploadStatus.uploading,
      progress: progress,
    );
    return copyWith(videos: updatedVideos);
  }

  /// 完成视频上传
  StudentExerciseModel completeVideoUpload(
    int index,
    String downloadUrl, {
    String? thumbnailUrl,
  }) {
    if (index < 0 || index >= videos.length) return this;

    final updatedVideos = List<VideoUploadState>.from(videos);
    updatedVideos[index] = videos[index].copyWith(
      status: VideoUploadStatus.completed,
      downloadUrl: downloadUrl,
      thumbnailUrl: thumbnailUrl,
      progress: 1.0,
    );
    return copyWith(videos: updatedVideos);
  }

  /// 标记视频上传失败
  StudentExerciseModel failVideoUpload(int index, String error) {
    if (index < 0 || index >= videos.length) return this;

    final updatedVideos = List<VideoUploadState>.from(videos);
    updatedVideos[index] = videos[index].copyWith(
      status: VideoUploadStatus.error,
      error: error,
    );
    return copyWith(videos: updatedVideos);
  }

  /// 删除视频
  StudentExerciseModel removeVideo(int index) {
    if (index < 0 || index >= videos.length) return this;

    final updatedVideos = List<VideoUploadState>.from(videos);
    updatedVideos.removeAt(index);
    return copyWith(videos: updatedVideos);
  }

  /// 重试失败的上传
  StudentExerciseModel retryVideoUpload(int index) {
    if (index < 0 || index >= videos.length) return this;

    final video = videos[index];
    if (video.status != VideoUploadStatus.error) return this;

    final updatedVideos = List<VideoUploadState>.from(videos);
    updatedVideos[index] = video.copyWith(
      status: VideoUploadStatus.pending,
      progress: 0.0,
      error: null,
    );
    return copyWith(videos: updatedVideos);
  }

  /// 切换完成状态
  StudentExerciseModel toggleComplete() {
    return copyWith(completed: !completed);
  }

  /// 更新某个 Set
  StudentExerciseModel updateSet(int index, TrainingSet set) {
    if (index < 0 || index >= sets.length) return this;
    final newSets = List<TrainingSet>.from(sets);
    newSets[index] = set;
    return copyWith(sets: newSets);
  }

  /// 添加 Set
  StudentExerciseModel addSet(TrainingSet set) {
    return copyWith(sets: [...sets, set]);
  }

  /// 删除 Set
  StudentExerciseModel removeSet(int index) {
    if (index < 0 || index >= sets.length) return this;
    final newSets = List<TrainingSet>.from(sets);
    newSets.removeAt(index);
    // 至少保留一个 Set
    return copyWith(sets: newSets.isEmpty ? [TrainingSet.empty()] : newSets);
  }

  /// 是否有效（name 不为空）
  bool get isValid => name.trim().isNotEmpty;

  /// 获取已完成的 Sets 数量
  int get completedSetsCount => sets.where((set) => set.completed).length;

  /// 获取总 Sets 数量
  int get totalSets => sets.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentExerciseModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          note == other.note &&
          type == other.type &&
          completed == other.completed &&
          isReviewed == other.isReviewed;

  @override
  int get hashCode =>
      name.hashCode ^
      note.hashCode ^
      type.hashCode ^
      completed.hashCode ^
      isReviewed.hashCode;

  @override
  String toString() {
    return 'StudentExerciseModel(name: $name, type: $type, sets: ${sets.length}, completed: $completed, videos: ${videos.length}, keyframes: ${keyframes.length}, timeSpent: $timeSpent, isReviewed: $isReviewed)';
  }
}
