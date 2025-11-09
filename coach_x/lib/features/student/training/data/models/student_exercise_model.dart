import 'package:coach_x/core/enums/exercise_type.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'voice_feedback_model.dart';

/// 学生训练动作模型
///
/// 用于 dailyTraining 中记录学生完成的训练动作
class StudentExerciseModel {
  final String name;
  final String note;
  final ExerciseType type;
  final List<TrainingSet> sets;
  final bool completed;
  final List<String> videos; // 学生上传的视频 URL
  final List<VoiceFeedbackModel> voiceFeedbacks; // 语音反馈
  final int? timeSpent; // 动作耗时（秒数），nullable

  const StudentExerciseModel({
    required this.name,
    this.note = '',
    this.type = ExerciseType.strength,
    required this.sets,
    this.completed = false,
    this.videos = const [],
    this.voiceFeedbacks = const [],
    this.timeSpent,
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
      voiceFeedbacks: const [],
      timeSpent: null,
    );
  }

  /// 从 JSON 创建
  factory StudentExerciseModel.fromJson(Map<String, dynamic> json) {
    final setsData = safeMapListCast(json['sets'], 'sets');
    final sets = setsData.map((setJson) => TrainingSet.fromJson(setJson)).toList();

    final voiceFeedbacksData = safeMapListCast(json['voiceFeedbacks'], 'voiceFeedbacks');
    final voiceFeedbacks = voiceFeedbacksData
        .map((feedbackJson) => VoiceFeedbackModel.fromJson(feedbackJson))
        .toList();

    return StudentExerciseModel(
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      type: exerciseTypeFromString(json['type'] as String? ?? 'strength'),
      sets: sets.isNotEmpty ? sets : [TrainingSet.empty()],
      completed: json['completed'] as bool? ?? false,
      videos: (json['videos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      voiceFeedbacks: voiceFeedbacks,
      timeSpent: json['timeSpent'] as int?,
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
      'videos': videos,
      'voiceFeedbacks': voiceFeedbacks.map((feedback) => feedback.toJson()).toList(),
      'timeSpent': timeSpent,
    };
  }

  /// 复制并修改部分字段
  StudentExerciseModel copyWith({
    String? name,
    String? note,
    ExerciseType? type,
    List<TrainingSet>? sets,
    bool? completed,
    List<String>? videos,
    List<VoiceFeedbackModel>? voiceFeedbacks,
    int? timeSpent,
  }) {
    return StudentExerciseModel(
      name: name ?? this.name,
      note: note ?? this.note,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      completed: completed ?? this.completed,
      videos: videos ?? this.videos,
      voiceFeedbacks: voiceFeedbacks ?? this.voiceFeedbacks,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  /// 添加视频
  StudentExerciseModel addVideo(String videoUrl) {
    return copyWith(videos: [...videos, videoUrl]);
  }

  /// 删除视频
  StudentExerciseModel removeVideo(int index) {
    if (index < 0 || index >= videos.length) return this;
    final newVideos = List<String>.from(videos);
    newVideos.removeAt(index);
    return copyWith(videos: newVideos);
  }

  /// 添加语音反馈
  StudentExerciseModel addVoiceFeedback(VoiceFeedbackModel feedback) {
    return copyWith(voiceFeedbacks: [...voiceFeedbacks, feedback]);
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
          completed == other.completed;

  @override
  int get hashCode =>
      name.hashCode ^ note.hashCode ^ type.hashCode ^ completed.hashCode;

  @override
  String toString() {
    return 'StudentExerciseModel(name: $name, type: $type, sets: ${sets.length}, completed: $completed, videos: ${videos.length}, timeSpent: $timeSpent)';
  }
}
