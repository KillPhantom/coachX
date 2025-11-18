import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'today_training_repository.dart';

/// 今日训练记录Repository实现类
class TodayTrainingRepositoryImpl implements TodayTrainingRepository {
  TodayTrainingRepositoryImpl();

  @override
  Stream<DailyTrainingModel?> watchTodayTraining(String userId, String date) {
    try {
      AppLogger.info('开始监听今日训练记录: userId=$userId, date=$date');

      return FirestoreService.watchCollection(
        'dailyTrainings',
        where: [
          ['studentID', '==', userId],
          ['date', '==', date],
        ],
        limit: 1,
      ).map((snapshot) {
        if (snapshot.docs.isEmpty) {
          AppLogger.info('今日无训练记录: $date');
          return null;
        }

        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        final training = DailyTrainingModel.fromJson(data);
        AppLogger.info('今日训练记录更新: ${training.id}');
        return training;
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听今日训练记录失败: $date', e, stackTrace);
      rethrow;
    }
  }
}
