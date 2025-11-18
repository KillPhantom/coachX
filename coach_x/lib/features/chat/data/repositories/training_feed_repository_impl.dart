import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_feed_repository.dart';
import '../models/training_feed_item.dart';
import '../models/feed_item_type.dart';
import '../../../student/home/data/models/daily_training_model.dart';
import '../../../student/training/data/models/student_exercise_model.dart';
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

    final feedItems = <TrainingFeedItem>[];

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
        // 无视频：生成图文 Feed Item
        feedItems.add(
          TrainingFeedItem.fromExerciseModel(
            dailyTrainingId: dailyTrainingId,
            exercise: exercise,
          ),
        );
      }
    }

    // 添加完成占位符
    feedItems.add(TrainingFeedItem.completion(dailyTrainingId));

    return feedItems;
  }

  @override
  Future<void> markFeedItemReviewed(
    String dailyTrainingId,
    String feedItemId,
  ) async {
    // 解析 feedItemId：{dailyTrainingId}_{type}_{exerciseTemplateId}_{videoIndex}
    final parts = feedItemId.split('_');
    final type = parts[1]; // 'video' | 'textCard'

    if (type == 'video') {
      final exerciseTemplateId = parts[2];
      final videoIndex = int.parse(parts[3]);
      await updateVideoReviewStatus(
        dailyTrainingId: dailyTrainingId,
        exerciseTemplateId: exerciseTemplateId,
        videoIndex: videoIndex,
        isReviewed: true,
      );
    } else if (type == 'textCard') {
      // 图文项：标记 exercise.isReviewed（如果 Exercise 有这个字段）
      // 或者不做任何操作（因为图文项的 isReviewed 是临时状态）
    }

    // 检查是否所有 Feed Items 已批阅
    await checkAndUpdateCompletionStatus(dailyTrainingId);
  }

  @override
  Future<void> updateVideoReviewStatus({
    required String dailyTrainingId,
    required String exerciseTemplateId,
    required int videoIndex,
    required bool isReviewed,
  }) async {
    final docRef = _firestore.collection('dailyTrainings').doc(dailyTrainingId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) return;

    final data = docSnapshot.data()!;
    final exercises = List<Map<String, dynamic>>.from(
      data['exercises'] as List,
    );

    // 找到对应的 Exercise
    final exerciseIdx = exercises.indexWhere(
      (e) => e['exerciseTemplateId'] == exerciseTemplateId,
    );
    if (exerciseIdx == -1) return;

    // 更新视频的 isReviewed
    final videos = List<Map<String, dynamic>>.from(
      exercises[exerciseIdx]['videos'] as List,
    );
    if (videoIndex < videos.length) {
      videos[videoIndex]['isReviewed'] = isReviewed;
      exercises[exerciseIdx]['videos'] = videos;

      await docRef.update({'exercises': exercises});
    }
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
          return DailyTrainingModel.fromJson(snapshot.data()!);
        });
  }

  @override
  Future<void> checkAndUpdateCompletionStatus(String dailyTrainingId) async {
    final feedItems = await generateFeedItems(dailyTrainingId);

    // 排除完成占位符
    final contentItems = feedItems
        .where((item) => item.type.isContentItem)
        .toList();

    // 检查是否所有内容项已批阅
    final allReviewed = contentItems.every((item) => item.isReviewed);

    if (allReviewed) {
      await _firestore.collection('dailyTrainings').doc(dailyTrainingId).update(
        {'isReviewed': true},
      );
    }
  }
}
