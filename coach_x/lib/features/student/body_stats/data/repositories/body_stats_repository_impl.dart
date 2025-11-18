import 'dart:io';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';
import 'package:coach_x/features/student/body_stats/data/repositories/body_stats_repository.dart';

/// 身体测量数据仓库实现
class BodyStatsRepositoryImpl implements BodyStatsRepository {
  BodyStatsRepositoryImpl();

  @override
  Future<BodyMeasurementModel> saveMeasurement({
    required String recordDate,
    required double weight,
    required String weightUnit,
    double? bodyFat,
    List<String> photos = const [],
  }) async {
    try {
      AppLogger.info('💾 保存身体测量记录: $weight$weightUnit, 日期: $recordDate');

      // 调用 Cloud Function
      final response =
          await CloudFunctionsService.call('save_body_measurement', {
            'record_date': recordDate,
            'weight': weight,
            'weight_unit': weightUnit,
            if (bodyFat != null) 'body_fat': bodyFat,
            'photos': photos,
          });

      // 解析响应
      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('Invalid response data from save_body_measurement');
      }
      final measurement = BodyMeasurementModel.fromJson(data);

      AppLogger.info('✅ 身体测量记录保存成功: ${measurement.id}');
      return measurement;
    } catch (e, stack) {
      AppLogger.error('❌ 保存身体测量记录失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<BodyMeasurementModel>> fetchMeasurements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.info('📥 获取身体测量历史记录');

      // 构建请求参数
      final Map<String, dynamic> params = {};
      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      // 调用 Cloud Function
      final response = await CloudFunctionsService.call(
        'fetch_body_measurements',
        params,
      );

      // 解析响应
      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('Invalid response data from fetch_body_measurements');
      }
      final measurementsData = safeMapListCast(
        data['measurements'],
        'measurements',
      );

      final measurements = measurementsData
          .map((item) => BodyMeasurementModel.fromJson(item))
          .toList();

      AppLogger.info('✅ 获取到 ${measurements.length} 条身体测量记录');
      return measurements;
    } catch (e, stack) {
      AppLogger.error('❌ 获取身体测量记录失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<BodyMeasurementModel> updateMeasurement({
    required String measurementId,
    double? weight,
    String? weightUnit,
    double? bodyFat,
    List<String>? photos,
  }) async {
    try {
      AppLogger.info('🔄 更新身体测量记录: $measurementId');

      // 构建更新参数
      final Map<String, dynamic> params = {'measurement_id': measurementId};

      if (weight != null) params['weight'] = weight;
      if (weightUnit != null) params['weight_unit'] = weightUnit;
      if (bodyFat != null) params['body_fat'] = bodyFat;
      if (photos != null) params['photos'] = photos;

      // 调用 Cloud Function
      final response = await CloudFunctionsService.call(
        'update_body_measurement',
        params,
      );

      // 解析响应
      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('Invalid response data from update_body_measurement');
      }
      final measurement = BodyMeasurementModel.fromJson(data);

      AppLogger.info('✅ 身体测量记录更新成功: ${measurement.id}');
      return measurement;
    } catch (e, stack) {
      AppLogger.error('❌ 更新身体测量记录失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      AppLogger.info('🗑️ 删除身体测量记录: $measurementId');

      // 调用 Cloud Function
      await CloudFunctionsService.call('delete_body_measurement', {
        'measurement_id': measurementId,
      });

      AppLogger.info('✅ 身体测量记录删除成功: $measurementId');
    } catch (e, stack) {
      AppLogger.error('❌ 删除身体测量记录失败', e, stack);
      rethrow;
    }
  }

  @override
  Future<String> uploadPhoto(String localPath) async {
    try {
      AppLogger.info('📤 上传身体照片: $localPath');

      // 获取当前用户ID
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录，无法上传照片');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $localPath');
      }

      // 生成Storage路径：body_stats/{userId}/{fileName}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'body_stats_$timestamp.jpg';
      final storagePath = 'body_stats/$userId/$fileName';

      // 上传到Firebase Storage
      final downloadUrl = await StorageService.uploadFile(file, storagePath);

      AppLogger.info('✅ 身体照片上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e, stack) {
      AppLogger.error('❌ 上传身体照片失败', e, stack);
      rethrow;
    }
  }
}
