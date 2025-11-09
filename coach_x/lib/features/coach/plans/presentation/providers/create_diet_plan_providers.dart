import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/create_diet_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/repositories/diet_plan_repository.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_notifier.dart';

/// 饮食计划仓库 Provider
final dietPlanRepositoryProvider = Provider<DietPlanRepository>((ref) {
  return DietPlanRepository();
});

/// 创建饮食计划状态管理 Provider
final createDietPlanNotifierProvider =
    StateNotifierProvider<CreateDietPlanNotifier, CreateDietPlanState>((ref) {
      final repository = ref.watch(dietPlanRepositoryProvider);
      return CreateDietPlanNotifier(repository);
    });
