import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/plans_page_state.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/plan_repository_impl.dart';
import 'plans_notifier.dart';

/// 计划仓库Provider
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepositoryImpl();
});

/// 计划状态管理Provider
final plansNotifierProvider =
    StateNotifierProvider<PlansNotifier, PlansPageState>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return PlansNotifier(repository);
});

