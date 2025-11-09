import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';
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

      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('获取计划失败: 数据格式错误');
      }

      // 调试：打印返回的数据结构
      AppLogger.info('📦 后端返回的data字段: ${data.keys.toList()}');
      AppLogger.info('📦 exercise_plans字段类型: ${data['exercise_plans']?.runtimeType}');
      AppLogger.info('📦 diet_plans字段类型: ${data['diet_plans']?.runtimeType}');
      AppLogger.info('📦 supplement_plans字段类型: ${data['supplement_plans']?.runtimeType}');

      final plansModel = StudentPlansModel.fromJson(data);

      AppLogger.info('获取计划成功: ${plansModel.toString()}');

      return plansModel;
    } catch (e, stackTrace) {
      AppLogger.error('获取学生计划失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<StudentPlansModel> getAllPlans() async {
    try {
      AppLogger.info('获取学生所有计划（包括教练分配的和自己创建的）');

      final response = await CloudFunctionsService.getStudentAllPlans();

      if (response['status'] != 'success') {
        throw Exception('获取所有计划失败: ${response['message'] ?? '未知错误'}');
      }

      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('获取所有计划失败: 数据格式错误');
      }

      final plansModel = StudentPlansModel.fromJson(data);

      AppLogger.info('获取所有计划成功: 训练计划${plansModel.exercisePlans.length}个, 饮食计划${plansModel.dietPlans.length}个, 补剂计划${plansModel.supplementPlans.length}个');

      return plansModel;
    } catch (e, stackTrace) {
      AppLogger.error('获取学生所有计划失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateActivePlan(String planType, String planId) async {
    try {
      AppLogger.info('更新 Active Plan: type=$planType, id=$planId');

      final response = await CloudFunctionsService.updateActivePlan(
        planType: planType,
        planId: planId,
      );

      if (response['status'] != 'success') {
        throw Exception('更新 Active Plan 失败: ${response['message'] ?? '未知错误'}');
      }

      AppLogger.info('更新 Active Plan 成功');
    } catch (e, stackTrace) {
      AppLogger.error('更新 Active Plan 失败', e, stackTrace);
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

      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('获取训练记录失败: 数据格式错误');
      }

      final trainingData = safeMapCast(data['training'], 'training');

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
