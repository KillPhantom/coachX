import '../models/student_plans_model.dart';
import '../models/daily_training_model.dart';

/// 学生首页Repository接口
abstract class StudentHomeRepository {
  /// 获取分配给学生的计划
  Future<StudentPlansModel> getAssignedPlans();

  /// 获取学生最新训练记录
  Future<DailyTrainingModel?> getLatestTraining();
}
