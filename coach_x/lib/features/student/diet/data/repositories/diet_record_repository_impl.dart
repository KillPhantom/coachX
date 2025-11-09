import 'dart:io';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'diet_record_repository.dart';

/// 饮食记录Repository实现
class DietRecordRepositoryImpl implements DietRecordRepository {
  @override
  Future<DailyTrainingModel?> getTodayTraining(String date) async {
    try {
      AppLogger.info('获取今日训练记录: $date');

      final response = await CloudFunctionsService.fetchTodayTraining(date);

      if (response['status'] != 'success') {
        throw Exception('获取训练记录失败: ${response['message'] ?? '未知错误'}');
      }

      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        AppLogger.info('今日无训练记录: $date');
        return null;
      }

      final trainingModel = DailyTrainingModel.fromJson(data);
      AppLogger.info('获取今日训练记录成功: $trainingModel');

      return trainingModel;
    } catch (e, stackTrace) {
      AppLogger.error('获取今日训练记录失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> saveDietRecord(DailyTrainingModel training) async {
    try {
      AppLogger.info('保存饮食记录: ${training.date}');

      final response = await CloudFunctionsService.upsertTodayTraining(
        training.toJson(),
      );

      if (response['status'] != 'success') {
        throw Exception('保存饮食记录失败: ${response['message'] ?? '未知错误'}');
      }

      AppLogger.info('保存饮食记录成功: ${training.date}');
    } catch (e, stackTrace) {
      AppLogger.error('保存饮食记录失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadDietImage(File image) async {
    try {
      AppLogger.info('上传饮食图片');

      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = image.path.split('.').last;
      final path = 'diet_images/$userId/$timestamp.$extension';

      final url = await StorageService.uploadFile(image, path);

      AppLogger.info('上传饮食图片成功: $url');
      return url;
    } catch (e, stackTrace) {
      AppLogger.error('上传饮食图片失败', e, stackTrace);
      rethrow;
    }
  }
}
