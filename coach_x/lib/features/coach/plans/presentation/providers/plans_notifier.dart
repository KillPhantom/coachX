import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/enums/app_status.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../../data/models/plans_page_state.dart';
import '../../data/repositories/plan_repository.dart';

/// 计划管理状态管理
class PlansNotifier extends StateNotifier<PlansPageState> {
  final PlanRepository _repository;

  PlansNotifier(this._repository) : super(PlansPageState.initial());

  /// 加载计划列表
  Future<void> loadPlans() async {
    if (state.loadingStatus == LoadingStatus.loading) {
      return; // 防止重复加载
    }

    state = state.copyWith(
      loadingStatus: LoadingStatus.loading,
      errorMessage: null,
    );

    try {
      final plansData = await _repository.fetchAllPlans();

      state = state.copyWith(
        loadingStatus: LoadingStatus.success,
        exercisePlans: plansData.exercisePlans,
        dietPlans: plansData.dietPlans,
        supplementPlans: plansData.supplementPlans,
        errorMessage: null,
      );
    } catch (e) {
      AppLogger.error('加载计划失败: $e');
      state = state.copyWith(
        loadingStatus: LoadingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 刷新计划列表
  Future<void> refreshPlans() async {
    try {
      final plansData = await _repository.fetchAllPlans();

      state = state.copyWith(
        loadingStatus: LoadingStatus.success,
        exercisePlans: plansData.exercisePlans,
        dietPlans: plansData.dietPlans,
        supplementPlans: plansData.supplementPlans,
        errorMessage: null,
      );
    } catch (e) {
      AppLogger.error('刷新计划失败: $e');
      // 刷新失败不改变loading状态，保持列表显示
      state = state.copyWith(errorMessage: e.toString());
      rethrow; // 让UI层显示错误提示
    }
  }

  /// 搜索计划
  void searchPlans(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 清空搜索
  void clearSearch() {
    state = state.clearSearch();
  }

  /// 删除计划
  Future<void> deletePlan(String planId, String planType) async {
    try {
      await _repository.deletePlan(planId, planType);

      // 从列表中移除已删除的计划
      switch (planType) {
        case 'exercise':
          state = state.copyWith(
            exercisePlans: state.exercisePlans
                .where((plan) => plan.id != planId)
                .toList(),
          );
          break;
        case 'diet':
          state = state.copyWith(
            dietPlans: state.dietPlans
                .where((plan) => plan.id != planId)
                .toList(),
          );
          break;
        case 'supplement':
          state = state.copyWith(
            supplementPlans: state.supplementPlans
                .where((plan) => plan.id != planId)
                .toList(),
          );
          break;
      }

      AppLogger.debug('✅ 删除计划成功并更新列表');
    } catch (e) {
      AppLogger.error('删除计划失败: $e');
      rethrow;
    }
  }

  /// 复制计划
  Future<String> copyPlan(String planId, String planType) async {
    try {
      final newPlanId = await _repository.copyPlan(planId, planType);

      // 刷新列表以显示新复制的计划
      await refreshPlans();

      AppLogger.debug('✅ 复制计划成功: $newPlanId');
      return newPlanId;
    } catch (e) {
      AppLogger.error('复制计划失败: $e');
      rethrow;
    }
  }

  /// 分配计划给学生
  Future<void> assignPlan({
    required String planId,
    required String planType,
    required List<String> studentIds,
    required bool unassign,
  }) async {
    try {
      await _repository.assignPlanToStudents(
        planId: planId,
        planType: planType,
        studentIds: studentIds,
        unassign: unassign,
      );

      // 刷新列表以更新学生数量
      await refreshPlans();

      AppLogger.debug('✅ ${unassign ? '取消分配' : '分配'}计划成功');
    } catch (e) {
      AppLogger.error('分配计划失败: $e');
      rethrow;
    }
  }
}
