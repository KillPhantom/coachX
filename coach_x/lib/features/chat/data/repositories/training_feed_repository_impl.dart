import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_feed_repository.dart';
import '../models/training_feed_item.dart';
import '../../../student/home/data/models/daily_training_model.dart';
import '../../../student/training/data/models/student_exercise_model.dart';
import '../../../student/diet/data/models/student_diet_record_model.dart';
import '../../../../core/models/video_model.dart';

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
    final exercises =
        (data['exercises'] as List<dynamic>?)
            ?.map(
              (e) => StudentExerciseModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];
    
    final dietData = data['diet'] as Map<String, dynamic>?;
    final diet = dietData != null ? StudentDietRecordModel.fromJson(dietData) : null;

    final feedItems = <TrainingFeedItem>[];
    final nonVideoExercises = <StudentExerciseModel>[];

    // 遍历 Exercises，生成 Feed Items
    for (final exercise in exercises) {
      // 跳过没有 exerciseTemplateId 的动作
      if (exercise.exerciseTemplateId == null) continue;

      if (exercise.videos.isNotEmpty) {
        // 有视频：每个视频生成一个 Feed Item
        for (var i = 0; i < exercise.videos.length; i++) {
          final video = VideoModel.fromVideoUploadState(exercise.videos[i]);
          feedItems.add(
            TrainingFeedItem.fromVideoModel(
              dailyTrainingId: dailyTrainingId,
              exerciseTemplateId: exercise.exerciseTemplateId!,
              exerciseName: exercise.name,
              video: video,
              videoIndex: i,
              totalVideos: exercise.videos.length,
            ),
          );
        }
      } else {
        // 无视频：收集到聚合列表
        nonVideoExercises.add(exercise);
      }
    }

    // 生成聚合的 Text Card (包含所有无视频动作 + 饮食记录)
    if (nonVideoExercises.isNotEmpty || (diet != null && diet.meals.isNotEmpty)) {
      final allExercisesReviewed = nonVideoExercises.every((e) => e.isReviewed);
      final dietReviewed = diet?.isReviewed ?? true;
      
      feedItems.add(
        TrainingFeedItem.aggregated(
          dailyTrainingId: dailyTrainingId,
          exercises: nonVideoExercises,
          diet: diet,
          isReviewed: allExercisesReviewed && dietReviewed,
        ),
      );
    }

    // 添加完成占位符
    feedItems.add(TrainingFeedItem.completion(dailyTrainingId));

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
}
