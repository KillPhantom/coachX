import 'dart:io';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'training_record_repository.dart';

/// 训练记录仓库实现
class TrainingRecordRepositoryImpl implements TrainingRecordRepository {
  @override
  Future<DailyTrainingModel?> fetchTodayTraining(String date) async {
    try {
      AppLogger.info('获取训练记录: $date');

      final response = await CloudFunctionsService.fetchTodayTraining(date);

      if (response['status'] != 'success') {
        throw Exception('获取训练记录失败: ${response['message'] ?? '未知错误'}');
      }

      final data = safeMapCast(response['data'], 'data');

      if (data == null) {
        AppLogger.info('未找到训练记录: $date');
        return null;
      }

      final trainingModel = DailyTrainingModel.fromJson(data);

      AppLogger.info('获取训练记录成功: ${trainingModel.toString()}');

      return trainingModel;
    } catch (e, stackTrace) {
      AppLogger.error('获取训练记录失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> upsertTodayTraining(DailyTrainingModel training) async {
    try {
      AppLogger.info('保存训练记录: ${training.date}');

      final trainingData = training.toJson();

      final response =
          await CloudFunctionsService.upsertTodayTraining(trainingData);

      if (response['status'] != 'success') {
        throw Exception('保存训练记录失败: ${response['message'] ?? '未知错误'}');
      }

      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('保存训练记录失败: 数据格式错误');
      }

      final docId = data['id'] as String;

      AppLogger.info('保存训练记录成功: $docId');

      return docId;
    } catch (e, stackTrace) {
      AppLogger.error('保存训练记录失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String path) async {
    try {
      AppLogger.info('上传训练视频: $path');

      final downloadUrl = await StorageService.uploadFile(videoFile, path);

      AppLogger.info('上传训练视频成功: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传训练视频失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadAudio(File audioFile, String path) async {
    try {
      AppLogger.info('上传语音反馈: $path');

      final downloadUrl = await StorageService.uploadFile(audioFile, path);

      AppLogger.info('上传语音反馈成功: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传语音反馈失败', e, stackTrace);
      rethrow;
    }
  }
}
