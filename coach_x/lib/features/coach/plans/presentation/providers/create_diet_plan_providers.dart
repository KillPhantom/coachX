import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/create_diet_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/create_plan_page_state.dart';
import 'package:coach_x/features/coach/plans/data/repositories/diet_plan_repository.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_notifier.dart';

/// 饮食计划仓库 Provider
final dietPlanRepositoryProvider = Provider<DietPlanRepository>((ref) {
  return DietPlanRepository();
});

/// 创建饮食计划状态管理 Provider
final AutoDisposeStateNotifierProvider<CreateDietPlanNotifier, CreateDietPlanState> createDietPlanNotifierProvider =
    StateNotifierProvider.autoDispose<CreateDietPlanNotifier, CreateDietPlanState>((ref) {
      final repository = ref.watch(dietPlanRepositoryProvider);
      return CreateDietPlanNotifier(repository);
    });

/// 页面状态 Provider（管理页面在不同创建方式之间的切换）
final createDietPlanPageStateProvider =
    StateProvider.autoDispose<CreatePlanPageState>((ref) {
  return CreatePlanPageState.initial;
});
