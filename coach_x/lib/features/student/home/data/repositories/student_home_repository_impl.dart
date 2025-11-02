import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/student_plans_model.dart';
import '../models/daily_training_model.dart';
import 'student_home_repository.dart';

/// 学生首页Repository实现
class StudentHomeRepositoryImpl implements StudentHomeRepository {
  @override
  Future<StudentPlansModel> getAssignedPlans() async {
    try {
      AppLogger.info('获取学生分配的计划');

      final response = await CloudFunctionsService.getStudentAssignedPlans();

      if (response['status'] != 'success') {
        throw Exception('获取计划失败: ${response['message'] ?? '未知错误'}');
      }

      final data = response['data'] as Map<String, dynamic>;
      final plansModel = StudentPlansModel.fromJson(data);

      AppLogger.info('获取计划成功: ${plansModel.toString()}');

      return plansModel;
    } catch (e, stackTrace) {
      AppLogger.error('获取学生计划失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<DailyTrainingModel?> getLatestTraining() async {
    try {
      AppLogger.info('获取最新训练记录');

      final response = await CloudFunctionsService.fetchLatestTraining();

      if (response['status'] != 'success') {
        throw Exception('获取训练记录失败: ${response['message'] ?? '未知错误'}');
      }

      final data = response['data'] as Map<String, dynamic>;
      final trainingData = data['training'] as Map<String, dynamic>?;

      if (trainingData == null) {
        AppLogger.info('学生无训练记录');
        return null;
      }

      final trainingModel = DailyTrainingModel.fromJson(trainingData);

      AppLogger.info('获取最新训练记录成功: ${trainingModel.toString()}');

      return trainingModel;
    } catch (e, stackTrace) {
      AppLogger.error('获取最新训练记录失败', e, stackTrace);
      rethrow;
    }
  }
}
