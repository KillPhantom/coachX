import 'package:coach_x/core/enums/exercise_type.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/core/models/media_upload_state.dart';
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
  final List<MediaUploadState> media; // 学生上传的媒体（视频/图片）
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
    this.media = const [],
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
      media: const [],
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
      media:
          ((json['medias']) as List<dynamic>?)?.map((data) {
            final mapData = safeMapCast(data);
            
            if (mapData != null) {
              // 尝试获取嵌套的 media 
              final innerData = safeMapCast(mapData['media']);
              // 如果有嵌套对象则使用嵌套对象
              return MediaUploadState.fromJson(innerData ?? mapData);
            }
            
            return MediaUploadState.completed(downloadUrl: ''); // 降级处理
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
      'medias': media.map((m) => {'media': m.toJson()}).toList(),
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
    List<MediaUploadState>? media,
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
      media: media ?? this.media,
      keyframes: keyframes ?? this.keyframes,
      timeSpent: timeSpent ?? this.timeSpent,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  /// 添加待上传媒体
  StudentExerciseModel addPendingMedia(
    String localPath,
    MediaType type, {
    String? thumbnailPath,
  }) {
    final newMedia = MediaUploadState.pending(
        localPath: localPath, 
        thumbnailPath: thumbnailPath,
        type: type,
    );
    return copyWith(media: [...media, newMedia]);
  }

  /// 更新媒体上传进度
  StudentExerciseModel updateMediaProgress(int index, double progress) {
    if (index < 0 || index >= media.length) return this;

    final updatedMedia = List<MediaUploadState>.from(media);
    updatedMedia[index] = media[index].copyWith(
      status: MediaUploadStatus.uploading,
      progress: progress,
    );
    return copyWith(media: updatedMedia);
  }

  /// 完成媒体上传
  StudentExerciseModel completeMediaUpload(
    int index,
    String downloadUrl, {
    String? thumbnailUrl,
  }) {
    if (index < 0 || index >= media.length) return this;

    final updatedMedia = List<MediaUploadState>.from(media);
    updatedMedia[index] = media[index].copyWith(
      status: MediaUploadStatus.completed,
      downloadUrl: downloadUrl,
      thumbnailUrl: thumbnailUrl,
      progress: 1.0,
    );
    return copyWith(media: updatedMedia);
  }

  /// 标记媒体上传失败
  StudentExerciseModel failMediaUpload(int index, String error) {
    if (index < 0 || index >= media.length) return this;

    final updatedMedia = List<MediaUploadState>.from(media);
    updatedMedia[index] = media[index].copyWith(
      status: MediaUploadStatus.error,
      error: error,
    );
    return copyWith(media: updatedMedia);
  }

  /// 删除媒体
  StudentExerciseModel removeMedia(int index) {
    if (index < 0 || index >= media.length) return this;

    final updatedMedia = List<MediaUploadState>.from(media);
    updatedMedia.removeAt(index);
    return copyWith(media: updatedMedia);
  }

  /// 重试失败的上传
  StudentExerciseModel retryMediaUpload(int index) {
    if (index < 0 || index >= media.length) return this;

    final item = media[index];
    if (item.status != MediaUploadStatus.error) return this;

    final updatedMedia = List<MediaUploadState>.from(media);
    updatedMedia[index] = item.copyWith(
      status: MediaUploadStatus.pending,
      progress: 0.0,
      error: null,
    );
    return copyWith(media: updatedMedia);
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
    return 'StudentExerciseModel(name: $name, type: $type, sets: ${sets.length}, completed: $completed, media: ${media.length}, keyframes: ${keyframes.length}, timeSpent: $timeSpent, isReviewed: $isReviewed)';
  }
}
