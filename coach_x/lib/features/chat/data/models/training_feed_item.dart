import 'feed_item_type.dart';
import '../../../student/training/data/models/student_exercise_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../student/diet/data/models/student_diet_record_model.dart';
import '../../../coach/plans/data/models/macros.dart';

/// Feed 流的基本单元
class TrainingFeedItem {
  /// 唯一标识：{dailyTrainingId}_{type}_{index}
  final String id;

  /// Feed 类型
  final FeedItemType type;

  /// 关联的训练记录 ID
  final String dailyTrainingId;

  /// 关联的 教练动作库 Exercise ID（video/textCard 有值）
  final String? exerciseTemplateId;

  /// Exercise 名称
  final String? exerciseName;

  /// 是否已批阅
  final bool isReviewed;

  /// 额外数据
  /// - video: {videoUrl, thumbnailUrl, videoIndex, duration}
  /// - textCard: {sets, totalSets, completedSets, avgWeight, totalReps}
  /// - aggregated textCard: {exercises: [], meals: [], actualMacros: {}, targetMacros: {}, isAggregated: true}
  final Map<String, dynamic>? metadata;

  const TrainingFeedItem({
    required this.id,
    required this.type,
    required this.dailyTrainingId,
    this.exerciseTemplateId,
    this.exerciseName,
    required this.isReviewed,
    this.metadata,
  });

  /// 从视频数据创建 Feed Item
  factory TrainingFeedItem.fromVideoModel({
    required String dailyTrainingId,
    required String exerciseTemplateId,
    required String exerciseName,
    required VideoModel video,
    required int videoIndex,
    required int totalVideos,
  }) {
    return TrainingFeedItem(
      id: '${dailyTrainingId}_video_${exerciseTemplateId}_$videoIndex',
      type: FeedItemType.video,
      dailyTrainingId: dailyTrainingId,
      exerciseTemplateId: exerciseTemplateId,
      exerciseName: exerciseName,
      isReviewed: video.isReviewed,
      metadata: {
        'videoUrl': video.videoUrl,
        'thumbnailUrl': video.thumbnailUrl,
        'videoIndex': videoIndex,
        'totalVideos': totalVideos,
        'duration': video.duration,
      },
    );
  }

  /// 从无视频 Exercise 创建图文 Feed Item (Deprecated: Use aggregated instead)
  factory TrainingFeedItem.fromExerciseModel({
    required String dailyTrainingId,
    required StudentExerciseModel exercise,
  }) {
    // 计算汇总数据
    final totalSets = exercise.sets.length;
    final completedSets = exercise.sets.where((s) => s.completed).length;
    final avgWeight = exercise.sets.isEmpty
        ? 0.0
        : exercise.sets
                  .map<double>((s) => double.tryParse(s.weight) ?? 0.0)
                  .reduce((a, b) => a + b) /
              exercise.sets.length;
    final totalReps = exercise.sets.fold<int>(
      0,
      (sum, s) => sum + (int.tryParse(s.reps) ?? 0),
    );

    return TrainingFeedItem(
      id: '${dailyTrainingId}_textCard_${exercise.exerciseTemplateId}',
      type: FeedItemType.textCard,
      dailyTrainingId: dailyTrainingId,
      exerciseTemplateId: exercise.exerciseTemplateId,
      exerciseName: exercise.name,
      isReviewed: exercise.isReviewed,
      metadata: {
        'sets': exercise.sets.map((s) => s.toJson()).toList(),
        'totalSets': totalSets,
        'completedSets': completedSets,
        'avgWeight': avgWeight,
        'totalReps': totalReps,
      },
    );
  }

  /// 创建聚合的图文 Feed Item
  factory TrainingFeedItem.aggregated({
    required String dailyTrainingId,
    required List<StudentExerciseModel> exercises,
    required StudentDietRecordModel? diet,
    required bool isReviewed,
    Macros? actualMacros,
    Macros? targetMacros,
  }) {
    return TrainingFeedItem(
      id: '${dailyTrainingId}_aggregated',
      type: FeedItemType.textCard,
      dailyTrainingId: dailyTrainingId,
      exerciseName: 'Daily Summary', // Display name for the card
      isReviewed: isReviewed,
      metadata: {
        'isAggregated': true,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'meals': diet?.meals.map((m) => m.toJson()).toList() ?? [],
        if (actualMacros != null) 'actualMacros': actualMacros.toJson(),
        if (targetMacros != null) 'targetMacros': targetMacros.toJson(),
      },
    );
  }

  /// 创建完成占位符 Feed Item
  factory TrainingFeedItem.completion(String dailyTrainingId) {
    return TrainingFeedItem(
      id: '${dailyTrainingId}_completion',
      type: FeedItemType.completion,
      dailyTrainingId: dailyTrainingId,
      isReviewed: true, // 占位符默认已批阅
    );
  }

  /// 创建副本，更新 isReviewed 状态
  TrainingFeedItem copyWith({bool? isReviewed}) {
    return TrainingFeedItem(
      id: id,
      type: type,
      dailyTrainingId: dailyTrainingId,
      exerciseTemplateId: exerciseTemplateId,
      exerciseName: exerciseName,
      isReviewed: isReviewed ?? this.isReviewed,
      metadata: metadata,
    );
  }
}
