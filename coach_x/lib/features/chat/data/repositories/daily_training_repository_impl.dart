import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'daily_training_repository.dart';

/// Daily Training Repository 实现类
class DailyTrainingRepositoryImpl implements DailyTrainingRepository {
  DailyTrainingRepositoryImpl();

  @override
  Future<DailyTrainingModel?> getDailyTraining(String dailyTrainingId) async {
    try {
      final doc = await FirestoreService.getDocument(
        'dailyTrainings',
        dailyTrainingId,
      );

      if (!doc.exists) {
        AppLogger.warning('Daily Training 不存在: $dailyTrainingId');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return DailyTrainingModel.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.error('获取 Daily Training 失败: $dailyTrainingId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<DailyTrainingModel?> watchDailyTraining(String dailyTrainingId) {
    try {
      return FirestoreService.watchDocument(
        'dailyTrainings',
        dailyTrainingId,
      ).map((doc) {
        if (!doc.exists) {
          AppLogger.warning('Daily Training 不存在: $dailyTrainingId');
          return null;
        }

        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DailyTrainingModel.fromJson(data);
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听 Daily Training 失败: $dailyTrainingId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> markAsReviewed(String dailyTrainingId) async {
    try {
      await FirestoreService.updateDocument('dailyTrainings', dailyTrainingId, {
        'isReviewed': true,
      });
      AppLogger.info('标记训练为已审核: $dailyTrainingId');
    } catch (e, stackTrace) {
      AppLogger.error('标记训练为已审核失败: $dailyTrainingId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateKeyframe(
    String dailyTrainingId,
    int exerciseIndex,
    int keyframeIndex,
    String newUrl,
    String? newLocalPath,
  ) async {
    try {
      AppLogger.info(
        '更新关键帧: $dailyTrainingId, exercise: $exerciseIndex, keyframe: $keyframeIndex',
      );

      // Get current document to read existing keyframe
      final doc = await FirestoreService.getDocument(
        'dailyTrainings',
        dailyTrainingId,
      );

      if (!doc.exists) {
        throw Exception('Daily Training 不存在: $dailyTrainingId');
      }

      final data = doc.data() as Map<String, dynamic>;
      final extractedKeyFrames =
          data['extractedKeyFrames'] as Map<String, dynamic>?;

      if (extractedKeyFrames == null) {
        throw Exception('extractedKeyFrames 不存在');
      }

      final exerciseIndexStr = exerciseIndex.toString();
      final exerciseData =
          extractedKeyFrames[exerciseIndexStr] as Map<String, dynamic>?;

      if (exerciseData == null) {
        throw Exception('Exercise $exerciseIndex 的关键帧不存在');
      }

      final keyframes = (exerciseData['keyframes'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>();

      if (keyframes == null || keyframeIndex >= keyframes.length) {
        throw Exception('Keyframe $keyframeIndex 不存在');
      }

      // Update specific keyframe (preserve timestamp)
      final currentKeyframe = keyframes[keyframeIndex];
      keyframes[keyframeIndex] = {
        'url': newUrl,
        'localPath': newLocalPath,
        'timestamp':
            currentKeyframe['timestamp'], // Preserve original timestamp
        'uploadStatus': 'uploaded',
      };

      // Update the entire extractedKeyFrames map
      await FirestoreService.updateDocument('dailyTrainings', dailyTrainingId, {
        'extractedKeyFrames': extractedKeyFrames,
      });

      AppLogger.info('关键帧更新成功: $dailyTrainingId');
    } catch (e, stackTrace) {
      AppLogger.error('更新关键帧失败: $dailyTrainingId', e, stackTrace);
      rethrow;
    }
  }
}
