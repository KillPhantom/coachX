import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';

/// Diet Plan Suggestion Review Mode 状态管理
class DietSuggestionReviewNotifier
    extends StateNotifier<DietSuggestionReviewState?> {
  DietSuggestionReviewNotifier() : super(null);

  /// 开始 Review Mode
  void startReview(
    DietPlanEditSuggestion suggestion,
    DietPlanModel originalPlan,
  ) {
    AppLogger.info('🔍 开始饮食计划 Review Mode - ${suggestion.changes.length} 处修改');

    state = DietSuggestionReviewState.initial(
      changes: suggestion.changes,
      originalPlan: originalPlan,
    );
  }

  /// 接受当前修改
  Future<void> acceptCurrent() async {
    if (state == null || state!.currentChange == null) {
      AppLogger.warning('⚠️ 无当前修改可接受');
      return;
    }

    final change = state!.currentChange!;
    AppLogger.info('✅ 接受饮食计划修改: ${change.id} - ${change.description}');

    try {
      // 应用修改到 workingPlan
      final updatedPlan = _applySingleChange(state!.workingPlan, change);

      // 更新状态
      state = state!.acceptCurrentAndMoveNext(updatedPlan);
    } catch (e, stackTrace) {
      AppLogger.error('❌ 应用饮食计划修改失败', e, stackTrace);
    }
  }

  /// 拒绝当前修改
  void rejectCurrent() {
    if (state == null || state!.currentChange == null) {
      AppLogger.warning('⚠️ 无当前修改可拒绝');
      return;
    }

    final change = state!.currentChange!;
    AppLogger.info('❌ 拒绝饮食计划修改: ${change.id} - ${change.description}');

    state = state!.rejectCurrentAndMoveNext();
  }

  /// 移动到下一个
  void moveNext() {
    if (state == null) return;
    state = state!.moveNext();
  }

  /// 移动到上一个
  void movePrevious() {
    if (state == null) return;
    state = state!.movePrevious();
  }

  /// 接受所有剩余修改
  Future<void> acceptAll() async {
    if (state == null) return;

    AppLogger.info('✅ 接受所有剩余饮食计划修改');

    // 逐个应用所有未处理的修改
    DietPlanModel workingPlan = state!.workingPlan;
    for (final change in state!.allChanges) {
      if (!state!.acceptedIds.contains(change.id) &&
          !state!.rejectedIds.contains(change.id)) {
        try {
          workingPlan = _applySingleChange(workingPlan, change);
        } catch (e) {
          AppLogger.error('❌ 应用饮食计划修改失败: ${change.id}', e);
        }
      }
    }

    // 更新状态
    state = state!.acceptAllRemaining().copyWith(workingPlan: workingPlan);
  }

  /// 拒绝所有剩余修改
  void rejectAll() {
    if (state == null) return;

    AppLogger.info('❌ 拒绝所有剩余饮食计划修改');
    state = state!.rejectAllRemaining();
  }

  /// 结束 Review Mode 并返回最终计划
  DietPlanModel? finishReview() {
    if (state == null) return null;

    AppLogger.info(
      '🏁 完成饮食计划 Review - 接受: ${state!.acceptedCount}, 拒绝: ${state!.rejectedCount}',
    );

    final finalPlan = state!.workingPlan;
    state = null; // 清除状态
    return finalPlan;
  }

  /// 取消 Review Mode
  void cancelReview() {
    AppLogger.info('🚫 取消饮食计划 Review Mode');
    state = null;
  }

  /// 切换显示全部改动
  void toggleShowAllChanges() {
    if (state == null) return;

    final newValue = !state!.isShowingAllChanges;
    AppLogger.debug('🔄 切换显示全部改动: $newValue');

    state = state!.copyWith(isShowingAllChanges: newValue);
  }

  /// 应用单个修改到计划（核心逻辑）
  DietPlanModel _applySingleChange(DietPlanModel plan, DietPlanChange change) {
    AppLogger.debug(
      '📝 应用饮食计划修改: ${change.type.name} at day ${change.dayIndex}',
    );

    switch (change.type) {
      case DietChangeType.addDay:
        return _addDay(plan, change);
      case DietChangeType.removeDay:
        return _removeDay(plan, change);
      case DietChangeType.modifyDayName:
        return _modifyDayName(plan, change);
      case DietChangeType.addMeal:
        return _addMeal(plan, change);
      case DietChangeType.removeMeal:
        return _removeMeal(plan, change);
      case DietChangeType.modifyMeal:
        return _modifyMeal(plan, change);
      case DietChangeType.addFoodItem:
        return _addFoodItem(plan, change);
      case DietChangeType.removeFoodItem:
        return _removeFoodItem(plan, change);
      case DietChangeType.modifyFoodItem:
        return _modifyFoodItem(plan, change);
      case DietChangeType.adjustMacros:
        return _adjustMacros(plan, change);
      case DietChangeType.reorder:
      case DietChangeType.other:
        AppLogger.warning('⚠️ 暂不支持的饮食计划修改类型: ${change.type.name}');
        return plan;
    }
  }

  // ==================== 修改类型实现 ====================

  /// 添加饮食日
  DietPlanModel _addDay(DietPlanModel plan, DietPlanChange change) {
    final days = List<DietDay>.from(plan.days);

    final newDay = DietDay(
      day: days.length + 1,
      name: change.after as String? ?? 'Day ${days.length + 1}',
      meals: const [],
    );

    days.add(newDay);
    return plan.copyWith(days: days);
  }

  /// 删除饮食日
  DietPlanModel _removeDay(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;

    final days = List<DietDay>.from(plan.days);
    days.removeAt(change.dayIndex);

    // 重新编号
    for (int i = 0; i < days.length; i++) {
      days[i] = days[i].copyWith(day: i + 1);
    }

    return plan.copyWith(days: days);
  }

  /// 修改饮食日名称
  DietPlanModel _modifyDayName(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;

    final days = List<DietDay>.from(plan.days);
    days[change.dayIndex] = days[change.dayIndex].copyWith(
      name: change.after as String,
    );

    return plan.copyWith(days: days);
  }

  /// 添加餐次
  DietPlanModel _addMeal(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;

    final days = List<DietDay>.from(plan.days);
    final day = days[change.dayIndex];

    // 从 after 构建 Meal
    Meal newMeal;
    if (change.after is Map) {
      final data = Map<String, dynamic>.from(change.after as Map);
      newMeal = Meal(
        name: data['name'] as String? ?? 'New Meal',
        items: const [],
      );
    } else if (change.after is String) {
      newMeal = Meal(name: change.after as String, items: const []);
    } else {
      newMeal = const Meal(name: 'New Meal', items: []);
    }

    final updatedDay = day.copyWith(meals: [...day.meals, newMeal]);

    days[change.dayIndex] = updatedDay;
    return plan.copyWith(days: days);
  }

  /// 删除餐次
  DietPlanModel _removeMeal(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;
    if (change.mealIndex == null) return plan;

    final days = List<DietDay>.from(plan.days);
    final day = days[change.dayIndex];

    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length)
      return plan;

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals.removeAt(change.mealIndex!);

    final updatedDay = day.copyWith(meals: updatedMeals);
    days[change.dayIndex] = updatedDay;

    return plan.copyWith(days: days);
  }

  /// 修改餐次
  DietPlanModel _modifyMeal(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;
    if (change.mealIndex == null) return plan;

    final days = List<DietDay>.from(plan.days);
    final day = days[change.dayIndex];

    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length)
      return plan;

    final meal = day.meals[change.mealIndex!];
    final updatedMeal = meal.copyWith(name: change.after as String);

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);
    days[change.dayIndex] = updatedDay;

    return plan.copyWith(days: days);
  }

  /// 添加食物条目
  DietPlanModel _addFoodItem(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;
    if (change.mealIndex == null) return plan;

    final days = List<DietDay>.from(plan.days);
    final day = days[change.dayIndex];

    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length)
      return plan;

    final meal = day.meals[change.mealIndex!];

    // 从 after 构建 FoodItem
    FoodItem newItem;
    if (change.after is Map) {
      final data = Map<String, dynamic>.from(change.after as Map);
      newItem = FoodItem(
        food: data['food'] as String? ?? '',
        amount: data['amount'] as String? ?? '',
        protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
        calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      newItem = FoodItem.empty();
    }

    final updatedMeal = meal.copyWith(items: [...meal.items, newItem]);

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);
    days[change.dayIndex] = updatedDay;

    return plan.copyWith(days: days);
  }

  /// 删除食物条目
  DietPlanModel _removeFoodItem(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;
    if (change.mealIndex == null || change.foodItemIndex == null) return plan;

    final days = List<DietDay>.from(plan.days);
    final day = days[change.dayIndex];

    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length)
      return plan;

    final meal = day.meals[change.mealIndex!];

    if (change.foodItemIndex! < 0 || change.foodItemIndex! >= meal.items.length)
      return plan;

    final updatedItems = List<FoodItem>.from(meal.items);
    updatedItems.removeAt(change.foodItemIndex!);

    final updatedMeal = meal.copyWith(items: updatedItems);

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);
    days[change.dayIndex] = updatedDay;

    return plan.copyWith(days: days);
  }

  /// 修改食物条目
  DietPlanModel _modifyFoodItem(DietPlanModel plan, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= plan.days.length) return plan;
    if (change.mealIndex == null || change.foodItemIndex == null) return plan;

    final days = List<DietDay>.from(plan.days);
    final day = days[change.dayIndex];

    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length)
      return plan;

    final meal = day.meals[change.mealIndex!];

    if (change.foodItemIndex! < 0 || change.foodItemIndex! >= meal.items.length)
      return plan;

    final item = meal.items[change.foodItemIndex!];

    // 从 after 更新食物
    FoodItem updatedItem = item;
    if (change.after is Map) {
      final data = Map<String, dynamic>.from(change.after as Map);
      updatedItem = item.copyWith(
        food: data['food'] as String?,
        amount: data['amount'] as String?,
        protein: (data['protein'] as num?)?.toDouble(),
        carbs: (data['carbs'] as num?)?.toDouble(),
        fat: (data['fat'] as num?)?.toDouble(),
        calories: (data['calories'] as num?)?.toDouble(),
      );
    }

    final updatedItems = List<FoodItem>.from(meal.items);
    updatedItems[change.foodItemIndex!] = updatedItem;

    final updatedMeal = meal.copyWith(items: updatedItems);

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);
    days[change.dayIndex] = updatedDay;

    return plan.copyWith(days: days);
  }

  /// 调整营养比例
  DietPlanModel _adjustMacros(DietPlanModel plan, DietPlanChange change) {
    // 调整营养比例 - 可以是全局调整或针对特定餐次/食物
    // 这里简化实现，实际可以更复杂
    AppLogger.info('🔧 调整营养比例: ${change.description}');
    return plan;
  }
}
