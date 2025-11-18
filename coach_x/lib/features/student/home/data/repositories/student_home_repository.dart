import '../models/student_plans_model.dart';
import '../models/daily_training_model.dart';
import '../models/weekly_stats_model.dart';

/// 学生首页Repository接口
abstract class StudentHomeRepository {
  /// 获取分配给学生的计划
  Future<StudentPlansModel> getAssignedPlans();

  /// 获取学生所有计划（包括教练分配的和自己创建的）
  Future<StudentPlansModel> getAllPlans();

  /// 更新学生的 Active Plan
  ///
  /// [planType] 计划类型：'exercise', 'diet', 'supplement'
  /// [planId] 计划ID
  Future<void> updateActivePlan(String planType, String planId);

  /// 获取学生最新训练记录
  Future<DailyTrainingModel?> getLatestTraining();

  /// 获取本周首页统计数据
  Future<WeeklyStatsModel> getWeeklyHomeStats();
}
