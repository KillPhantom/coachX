import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/create_supplement_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/repositories/supplement_plan_repository.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_supplement_plan_notifier.dart';

/// 补剂计划仓库 Provider
final supplementPlanRepositoryProvider = Provider<SupplementPlanRepository>((
  ref,
) {
  return SupplementPlanRepository();
});

/// 创建补剂计划状态管理 Provider
final createSupplementPlanNotifierProvider =
    StateNotifierProvider<
      CreateSupplementPlanNotifier,
      CreateSupplementPlanState
    >((ref) {
      final repository = ref.watch(supplementPlanRepositoryProvider);
      return CreateSupplementPlanNotifier(repository);
    });
