import 'package:coach_x/core/enums/app_status.dart';
import 'exercise_plan_model.dart';
import 'diet_plan_model.dart';
import 'supplement_plan_model.dart';
import 'plan_base_model.dart';

/// 计划管理页面状态
class PlansPageState {
  final LoadingStatus loadingStatus;
  final List<ExercisePlanModel> exercisePlans;
  final List<DietPlanModel> dietPlans;
  final List<SupplementPlanModel> supplementPlans;
  final String searchQuery;
  final String? errorMessage;

  const PlansPageState({
    required this.loadingStatus,
    required this.exercisePlans,
    required this.dietPlans,
    required this.supplementPlans,
    this.searchQuery = '',
    this.errorMessage,
  });

  /// 初始状态
  factory PlansPageState.initial() {
    return const PlansPageState(
      loadingStatus: LoadingStatus.initial,
      exercisePlans: [],
      dietPlans: [],
      supplementPlans: [],
      searchQuery: '',
      errorMessage: null,
    );
  }

  /// 获取当前tab的计划列表
  List<PlanBaseModel> getPlansForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return exercisePlans;
      case 1:
        return dietPlans;
      case 2:
        return supplementPlans;
      default:
        return [];
    }
  }

  /// 应用搜索过滤
  List<PlanBaseModel> getFilteredPlans(int tabIndex) {
    final plans = getPlansForTab(tabIndex);

    if (searchQuery.trim().isEmpty) {
      return plans;
    }

    final query = searchQuery.toLowerCase();
    return plans.where((plan) {
      return plan.name.toLowerCase().contains(query) ||
          plan.description.toLowerCase().contains(query);
    }).toList();
  }

  /// 根据planType获取计划列表
  List<PlanBaseModel> getPlansByType(String planType) {
    switch (planType) {
      case 'exercise':
        return exercisePlans;
      case 'diet':
        return dietPlans;
      case 'supplement':
        return supplementPlans;
      default:
        return [];
    }
  }

  /// 复制并修改状态
  PlansPageState copyWith({
    LoadingStatus? loadingStatus,
    List<ExercisePlanModel>? exercisePlans,
    List<DietPlanModel>? dietPlans,
    List<SupplementPlanModel>? supplementPlans,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PlansPageState(
      loadingStatus: loadingStatus ?? this.loadingStatus,
      exercisePlans: exercisePlans ?? this.exercisePlans,
      dietPlans: dietPlans ?? this.dietPlans,
      supplementPlans: supplementPlans ?? this.supplementPlans,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 清空搜索
  PlansPageState clearSearch() {
    return copyWith(searchQuery: '');
  }
}

