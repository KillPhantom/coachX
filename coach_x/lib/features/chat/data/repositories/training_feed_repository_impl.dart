import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_feed_repository.dart';
import '../models/training_feed_item.dart';
import '../../../student/home/data/models/daily_training_model.dart';
import '../../../student/training/data/models/student_exercise_model.dart';
import '../../../student/diet/data/models/student_diet_record_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../coach/plans/data/models/macros.dart';

class TrainingFeedRepositoryImpl implements TrainingFeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TrainingFeedItem>> generateFeedItems(
    String dailyTrainingId,
  ) async {
    final docSnapshot = await _firestore
        .collection('dailyTrainings')
        .doc(dailyTrainingId)
        .get();

    if (!docSnapshot.exists) {
      throw Exception('Daily training not found: $dailyTrainingId');
    }

    final data = docSnapshot.data()!;

    // 读取 isReviewed 状态，用于判断是否为二次编辑模式
    final isReviewed = data['isReviewed'] as bool? ?? false;

    final exercises =
        (data['exercises'] as List<dynamic>?)
            ?.map(
              (e) => StudentExerciseModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    final dietData = data['diet'] as Map<String, dynamic>?;
    final diet = dietData != null
        ? StudentDietRecordModel.fromJson(dietData)
        : null;

    final feedItems = <TrainingFeedItem>[];
    final nonVideoExercises = <StudentExerciseModel>[];

    // 遍历 Exercises，生成 Feed Items
    for (final exercise in exercises) {
      // 跳过没有 exerciseTemplateId 的动作
      if (exercise.exerciseTemplateId == null) continue;

      // 使用 media 字段 (原 videos)
      if (exercise.media.isNotEmpty) {
        // 有媒体：每个媒体生成一个 Feed Item
        for (var i = 0; i < exercise.media.length; i++) {
          final mediaItem = VideoModel.fromMediaUploadState(exercise.media[i]);
          feedItems.add(
            TrainingFeedItem.fromVideoModel(
              dailyTrainingId: dailyTrainingId,
              exerciseTemplateId: exercise.exerciseTemplateId!,
              exerciseName: exercise.name,
              video: mediaItem,
              videoIndex: i,
              totalVideos: exercise.media.length,
            ),
          );
        }
      } else {
        // 无媒体：收集到聚合列表
        nonVideoExercises.add(exercise);
      }
    }

    // 生成聚合的 Text Card (包含所有无视频动作 + 饮食记录)
    if (nonVideoExercises.isNotEmpty ||
        (diet != null && diet.meals.isNotEmpty)) {
      final allExercisesReviewed = nonVideoExercises.every((e) => e.isReviewed);
      final dietReviewed = diet?.isReviewed ?? true;

      // 获取 actual macros
      final actualMacros = diet?.macros;

      // 获取 target macros
      final studentId = data['studentID'] as String?;
      Macros? targetMacros;
      if (studentId != null) {
        targetMacros = await _fetchTargetMacros(studentId);
      }

      feedItems.add(
        TrainingFeedItem.aggregated(
          dailyTrainingId: dailyTrainingId,
          exercises: nonVideoExercises,
          diet: diet,
          isReviewed: allExercisesReviewed && dietReviewed,
          actualMacros: actualMacros,
          targetMacros: targetMacros,
        ),
      );
    }

    // 仅在首次批阅时添加完成占位符（二次编辑时不显示）
    if (!isReviewed) {
      feedItems.add(TrainingFeedItem.completion(dailyTrainingId));
    }

    return feedItems;
  }

  @override
  Stream<DailyTrainingModel> watchDailyTraining(String dailyTrainingId) {
    return _firestore
        .collection('dailyTrainings')
        .doc(dailyTrainingId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Daily training not found');
          }
          final data = Map<String, dynamic>.from(snapshot.data()!);
          data['id'] = snapshot.id; // 添加文档 ID
          return DailyTrainingModel.fromJson(data);
        });
  }

  /// 获取学生的目标 Macros（从 active diet plan）
  Future<Macros?> _fetchTargetMacros(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('dietPlans')
          .where('studentID', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final planData = querySnapshot.docs.first.data();
      final totalMacrosData = planData['totalMacros'] as Map<String, dynamic>?;

      if (totalMacrosData == null) {
        return null;
      }

      return Macros.fromJson(totalMacrosData);
    } catch (e) {
      // 查询失败时返回 null，不影响主流程
      return null;
    }
  }
}
