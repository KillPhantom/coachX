import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../../data/models/student_plans_model.dart';
import '../../data/models/daily_training_model.dart';
import '../../data/repositories/student_home_repository.dart';
import '../../data/repositories/student_home_repository_impl.dart';

// ==================== Repository Provider ====================

/// 学生首页Repository Provider
final studentHomeRepositoryProvider = Provider<StudentHomeRepository>((ref) {
  return StudentHomeRepositoryImpl();
});

// ==================== Data Providers ====================

/// 学生计划Provider
final studentPlansProvider = FutureProvider<StudentPlansModel>((ref) async {
  final repository = ref.watch(studentHomeRepositoryProvider);
  return await repository.getAssignedPlans();
});

/// 最新训练记录Provider
final latestTrainingProvider = FutureProvider<DailyTrainingModel?>((ref) async {
  final repository = ref.watch(studentHomeRepositoryProvider);
  return await repository.getLatestTraining();
});

// ==================== Computed Providers ====================

/// 当前Day Number Provider
///
/// 根据最新训练记录和计划，计算今天应该是第几天
/// 返回Map: {'exercise': dayNum, 'diet': dayNum, 'supplement': dayNum}
final currentDayNumbersProvider = Provider<Map<String, int>>((ref) {
  final plansAsync = ref.watch(studentPlansProvider);
  final latestTrainingAsync = ref.watch(latestTrainingProvider);

  // 如果任一数据还在加载中，返回空Map
  if (plansAsync.isLoading || latestTrainingAsync.isLoading) {
    return {};
  }

  // 如果有错误，返回空Map
  if (plansAsync.hasError || latestTrainingAsync.hasError) {
    AppLogger.error('计算Day Number失败', plansAsync.error ?? latestTrainingAsync.error);
    return {};
  }

  final plans = plansAsync.value;
  final latestTraining = latestTrainingAsync.value;

  if (plans == null || plans.hasNoPlan) {
    return {};
  }

  final Map<String, int> dayNumbers = {};

  // 计算训练计划的Day Number
  if (plans.exercisePlan != null) {
    final lastDayNum = latestTraining?.planSelection.exerciseDayNumber;
    final totalDays = plans.exercisePlan!.totalDays;
    dayNumbers['exercise'] = calculateNextDayNumber(lastDayNum, totalDays);
  }

  // 计算饮食计划的Day Number
  if (plans.dietPlan != null) {
    final lastDayNum = latestTraining?.planSelection.dietDayNumber;
    final totalDays = plans.dietPlan!.totalDays;
    dayNumbers['diet'] = calculateNextDayNumber(lastDayNum, totalDays);
  }

  // 计算补剂计划的Day Number
  if (plans.supplementPlan != null) {
    final lastDayNum = latestTraining?.planSelection.supplementDayNumber;
    final totalDays = plans.supplementPlan!.days.length;
    dayNumbers['supplement'] = calculateNextDayNumber(lastDayNum, totalDays);
  }

  AppLogger.info('计算Day Numbers: $dayNumbers');

  return dayNumbers;
});

// ==================== Helper Functions ====================

/// 计算下一个Day Number
///
/// 逻辑：
/// - 如果没有历史记录（lastDayNumber == null），返回 1
/// - 如果只有1天的计划，始终返回 1
/// - 否则循环：(lastDayNumber % totalDays) + 1
///
/// 例子：
/// - 上次Day 3，计划共7天 → 今天Day 4
/// - 上次Day 7，计划共7天 → 今天Day 1（循环）
/// - 上次Day 1，计划只有1天 → 今天Day 1（保持）
int calculateNextDayNumber(int? lastDayNumber, int totalDays) {
  // 无历史记录，从第1天开始
  if (lastDayNumber == null) {
    return 1;
  }

  // 只有1天的计划，始终是第1天
  if (totalDays == 1) {
    return 1;
  }

  // 循环逻辑
  return (lastDayNumber % totalDays) + 1;
}
