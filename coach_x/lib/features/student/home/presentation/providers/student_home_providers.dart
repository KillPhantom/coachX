import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_plan_model.dart';
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

/// 学生计划Provider（获取所有计划：教练分配的 + 自己创建的）
final studentPlansProvider = FutureProvider<StudentPlansModel>((ref) async {
  final repository = ref.watch(studentHomeRepositoryProvider);
  return await repository.getAllPlans();
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
    AppLogger.error(
      '计算Day Number失败',
      plansAsync.error ?? latestTrainingAsync.error,
    );
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

// ==================== Active Plan ID Providers ====================

/// Active Exercise Plan ID Provider
///
/// 从当前用户数据中获取选中的训练计划ID
final activeExercisePlanIdProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user?.activeExercisePlanId,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Active Diet Plan ID Provider
///
/// 从当前用户数据中获取选中的饮食计划ID
final activeDietPlanIdProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user?.activeDietPlanId,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Active Supplement Plan ID Provider
///
/// 从当前用户数据中获取选中的补剂计划ID
final activeSupplementPlanIdProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user?.activeSupplementPlanId,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ==================== Current Active Plans Provider ====================

/// 当前选中的计划集合 Provider
///
/// 根据 active plan IDs 从计划列表中找到对应的计划对象
/// 返回结构：
/// {
///   'exercisePlan': ExercisePlanModel?,
///   'dietPlan': DietPlanModel?,
///   'supplementPlan': SupplementPlanModel?
/// }
final currentActivePlansProvider = Provider<Map<String, dynamic>>((ref) {
  final plansAsync = ref.watch(studentPlansProvider);
  final activeExercisePlanId = ref.watch(activeExercisePlanIdProvider);
  final activeDietPlanId = ref.watch(activeDietPlanIdProvider);
  final activeSupplementPlanId = ref.watch(activeSupplementPlanIdProvider);

  // 如果计划数据还在加载中，返回空Map
  if (plansAsync.isLoading) {
    return {};
  }

  // 如果有错误，返回空Map
  if (plansAsync.hasError) {
    AppLogger.error('获取当前选中计划失败', plansAsync.error);
    return {};
  }

  final plans = plansAsync.value;
  if (plans == null) {
    return {};
  }

  final Map<String, dynamic> activePlans = {};

  // 获取选中的训练计划
  if (activeExercisePlanId != null) {
    activePlans['exercisePlan'] =
        plans.getActiveExercisePlan(activeExercisePlanId);
  } else if (plans.exercisePlans.isNotEmpty) {
    // 如果没有选中的计划但列表不为空，默认选择第一个
    activePlans['exercisePlan'] = plans.exercisePlans.first;
  }

  // 获取选中的饮食计划
  if (activeDietPlanId != null) {
    activePlans['dietPlan'] = plans.getActiveDietPlan(activeDietPlanId);
  } else if (plans.dietPlans.isNotEmpty) {
    // 如果没有选中的计划但列表不为空，默认选择第一个
    activePlans['dietPlan'] = plans.dietPlans.first;
  }

  // 获取选中的补剂计划
  if (activeSupplementPlanId != null) {
    activePlans['supplementPlan'] =
        plans.getActiveSupplementPlan(activeSupplementPlanId);
  } else if (plans.supplementPlans.isNotEmpty) {
    // 如果没有选中的计划但列表不为空，默认选择第一个
    activePlans['supplementPlan'] = plans.supplementPlans.first;
  }

  AppLogger.info('当前选中的计划: exercise=${activePlans['exercisePlan']?.id}, '
      'diet=${activePlans['dietPlan']?.id}, '
      'supplement=${activePlans['supplementPlan']?.id}');

  return activePlans;
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
