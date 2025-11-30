import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import '../../data/models/student_plans_model.dart';
import '../../data/models/daily_training_model.dart';
import '../../data/models/weekly_stats_model.dart';
import '../../data/repositories/student_home_repository.dart';
import '../../data/repositories/student_home_repository_impl.dart';
import '../../data/repositories/today_training_repository.dart';
import '../../data/repositories/today_training_repository_impl.dart';

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

/// 本周首页统计数据Provider
///
/// 包含:
/// - 本周训练打卡状态（7天）
/// - 体重变化统计
/// - 卡路里摄入统计
/// - Volume PR 统计
final weeklyStatsProvider = FutureProvider<WeeklyStatsModel>((ref) async {
  final repository = ref.watch(studentHomeRepositoryProvider);
  return await repository.getWeeklyHomeStats();
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
    final isLastRecordToday =
        latestTraining != null && _isToday(latestTraining.date);
    dayNumbers['exercise'] = calculateNextDayNumber(
      lastDayNum,
      totalDays,
      isLastRecordToday,
    );
  }

  // 计算饮食计划的Day Number
  if (plans.dietPlan != null) {
    final lastDayNum = latestTraining?.planSelection.dietDayNumber;
    final totalDays = plans.dietPlan!.totalDays;
    final isLastRecordToday =
        latestTraining != null && _isToday(latestTraining.date);
    dayNumbers['diet'] = calculateNextDayNumber(
      lastDayNum,
      totalDays,
      isLastRecordToday,
    );
  }

  // 计算补剂计划的Day Number
  if (plans.supplementPlan != null) {
    final lastDayNum = latestTraining?.planSelection.supplementDayNumber;
    final totalDays = plans.supplementPlan!.days.length;
    final isLastRecordToday =
        latestTraining != null && _isToday(latestTraining.date);
    dayNumbers['supplement'] = calculateNextDayNumber(
      lastDayNum,
      totalDays,
      isLastRecordToday,
    );
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
    error: (_, _) => null,
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
    error: (_, _) => null,
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
    error: (_, _) => null,
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
    activePlans['exercisePlan'] = plans.getActiveExercisePlan(
      activeExercisePlanId,
    );
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
    activePlans['supplementPlan'] = plans.getActiveSupplementPlan(
      activeSupplementPlanId,
    );
  } else if (plans.supplementPlans.isNotEmpty) {
    // 如果没有选中的计划但列表不为空，默认选择第一个
    activePlans['supplementPlan'] = plans.supplementPlans.first;
  }

  AppLogger.info(
    '当前选中的计划: exercise=${activePlans['exercisePlan']?.id}, '
    'diet=${activePlans['dietPlan']?.id}, '
    'supplement=${activePlans['supplementPlan']?.id}',
  );

  return activePlans;
});

// ==================== Helper Functions ====================

/// 计算今天应该做的Day Number
///
/// 逻辑：
/// - 如果没有历史记录（lastDayNumber == null），返回 1（Case 3）
/// - 如果最后一次记录是今天（isLastRecordToday == true），返回当天day number（Case 2）
/// - 如果最后一次记录不是今天（isLastRecordToday == false），返回下一天（Case 1）
/// - 特殊情况：只有1天的计划，始终返回 1
///
/// 例子：
/// - 无历史记录，计划共7天 → Day 1
/// - 上次Day 3（今天），计划共7天 → Day 3（不变）
/// - 上次Day 3（昨天），计划共7天 → Day 4
/// - 上次Day 7（昨天），计划共7天 → Day 1（循环）
int calculateNextDayNumber(
  int? lastDayNumber,
  int totalDays,
  bool isLastRecordToday,
) {
  // 无历史记录，从第1天开始
  if (lastDayNumber == null) {
    return 1;
  }

  // 只有1天的计划，始终是第1天
  if (totalDays == 1) {
    return 1;
  }

  // 如果最后一次记录是今天，返回当天day number
  if (isLastRecordToday) {
    return lastDayNumber;
  }

  // 如果最后一次记录不是今天，返回下一天
  return (lastDayNumber % totalDays) + 1;
}

/// 判断日期是否为今天
///
/// 参数 dateString 格式: "yyyy-MM-dd"
bool _isToday(String dateString) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  try {
    final date = DateTime.parse(dateString);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isAtSameMomentAs(today);
  } catch (e) {
    return false;
  }
}

/// 获取当前日期字符串 (格式: "yyyy-MM-dd")
String _getTodayDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

// ==================== Today Training Providers ====================

/// 今日训练记录Repository Provider
final todayTrainingRepositoryProvider = Provider<TodayTrainingRepository>((
  ref,
) {
  return TodayTrainingRepositoryImpl();
});

/// 今日训练记录Stream Provider
///
/// 监听今日训练记录的实时变化
final todayTrainingStreamProvider = StreamProvider<DailyTrainingModel?>((ref) {
  final repository = ref.watch(todayTrainingRepositoryProvider);
  final userId = AuthService.currentUserId;

  if (userId == null) {
    AppLogger.warning('用户未登录，无法监听今日训练记录');
    return Stream.value(null);
  }

  final today = _getTodayDateString();
  return repository.watchTodayTraining(userId, today);
});

/// 优化的今日训练记录 Provider (性能优化)
///
/// 优先使用 latestTrainingProvider 的数据（如果是今天）
/// 否则使用 todayTrainingStreamProvider 的实时数据
final optimizedTodayTrainingProvider =
    Provider<AsyncValue<DailyTrainingModel?>>((ref) {
      final latestTrainingAsync = ref.watch(latestTrainingProvider);
      final todayTrainingStreamAsync = ref.watch(todayTrainingStreamProvider);

      // 如果 latestTraining 数据可用且是今天，优先使用
      if (latestTrainingAsync.hasValue) {
        final latestTraining = latestTrainingAsync.value;
        if (latestTraining != null && _isToday(latestTraining.date)) {
          AppLogger.info('使用 latestTraining 数据（性能优化）: ${latestTraining.date}');
          return latestTrainingAsync;
        }
      }

      // 否则使用今日 Stream 数据
      AppLogger.info('使用 todayTrainingStream 数据');
      return todayTrainingStreamAsync;
    });

/// 实际饮食营养数据 Provider
///
/// 从今日训练记录中提取实际摄入的营养数据
/// 返回: Macros? (无记录时返回 null)
final actualDietMacrosProvider = Provider<Macros?>((ref) {
  final todayTrainingAsync = ref.watch(optimizedTodayTrainingProvider);

  // 数据加载中或有错误，返回 null
  if (todayTrainingAsync.isLoading || todayTrainingAsync.hasError) {
    return null;
  }

  final todayTraining = todayTrainingAsync.value;

  // 无今日记录，返回 null
  if (todayTraining == null || todayTraining.diet == null) {
    return null;
  }

  // 返回今日饮食记录的总营养数据
  return todayTraining.diet!.macros;
});

/// 饮食进度 Provider
///
/// 计算今日饮食记录相对于计划的进度
/// 返回: {'calories': 0.75, 'protein': 0.8, 'carbs': 0.7, 'fat': 0.83}
/// 如果无数据返回 null
final dietProgressProvider = Provider<Map<String, double>?>((ref) {
  final todayTrainingAsync = ref.watch(optimizedTodayTrainingProvider);
  final plansAsync = ref.watch(studentPlansProvider);
  final dayNumbers = ref.watch(currentDayNumbersProvider);

  // 数据加载中或有错误，返回 null
  if (todayTrainingAsync.isLoading || plansAsync.isLoading) {
    return null;
  }

  if (todayTrainingAsync.hasError || plansAsync.hasError) {
    return null;
  }

  final todayTraining = todayTrainingAsync.value;
  final plans = plansAsync.value;

  // 无今日记录或无计划，返回 null
  if (todayTraining == null || plans == null || plans.dietPlan == null) {
    return null;
  }

  // 从 meals 计算今日实际摄入的营养
  final meals = todayTraining.diet?.meals ?? [];
  final actualMacros = meals.isNotEmpty ? _calculateActualIntake(meals) : null;

  // 获取计划的目标营养（处理 days 为空的情况）
  final dayNum = dayNumbers['diet'] ?? 1;
  Macros targetMacros;

  if (plans.dietPlan!.days.isEmpty) {
    // 教练未设置具体餐次，使用 dietPlan 的 targetMacros 或返回零值
    targetMacros = Macros.zero();
  } else {
    final dietDay = plans.dietPlan!.days.firstWhere(
      (day) => day.day == dayNum,
      orElse: () => plans.dietPlan!.days.first,
    );
    targetMacros = dietDay.macros;
  }

  // 计算进度
  return _calculateDietProgress(actualMacros, targetMacros);
});

/// 计算实际摄入的营养
///
/// 遍历所有 meals，累加每个 meal 的 macros（自动从 food items 计算）
/// [meals] 学生记录的餐次列表
/// 返回总营养摄入
Macros _calculateActualIntake(List<Meal> meals) {
  return meals.fold(Macros.zero(), (sum, meal) => sum + meal.macros);
}

/// 计算饮食进度辅助函数
///
/// [actual] 实际摄入的营养
/// [target] 目标营养
/// 返回进度 Map，每个值范围 [0.0, ∞)
Map<String, double> _calculateDietProgress(Macros? actual, Macros target) {
  if (actual == null) {
    return {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
  }

  return {
    'calories': target.calories > 0 ? actual.calories / target.calories : 0.0,
    'protein': target.protein > 0 ? actual.protein / target.protein : 0.0,
    'carbs': target.carbs > 0 ? actual.carbs / target.carbs : 0.0,
    'fat': target.fat > 0 ? actual.fat / target.fat : 0.0,
  };
}
