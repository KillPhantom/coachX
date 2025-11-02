import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/services/conversation_storage_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/edit_diet_conversation_state.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';

/// 饮食计划编辑对话状态管理
class EditDietConversationNotifier extends StateNotifier<EditDietConversationState> {
  EditDietConversationNotifier() : super(const EditDietConversationState());

  // 当前编辑的计划 ID
  String? _currentPlanId;

  // 标记 notifier 是否已被 dispose
  bool _isMounted = true;

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  /// 初始化对话
  Future<void> initConversation(
    DietPlanModel currentPlan,
    String planId,
  ) async {
    _currentPlanId = planId;
    AppLogger.info('🆕 初始化饮食计划编辑对话 - 计划: ${currentPlan.name}');

    // 尝试加载历史对话
    final savedMessages = await ConversationStorageService.loadConversation(planId);

    if (savedMessages.isNotEmpty) {
      AppLogger.info('📂 恢复历史对话 - 消息数: ${savedMessages.length}');
      state = EditDietConversationState(
        currentPlan: currentPlan,
        messages: savedMessages,
        isAIResponding: false,
        currentTotalMacros: EditDietConversationState.calculatePlanMacros(currentPlan),
      );
    } else {
      state = EditDietConversationState.initial(currentPlan: currentPlan);
      AppLogger.info('🆕 开始新对话');
    }
  }

  /// 发送用户消息
  Future<void> sendMessage(
    String message,
    String planId,
  ) async {
    if (!_isMounted) return;

    if (state.currentPlan == null) {
      AppLogger.error('❌ 当前计划为空，无法发送消息');
      if (_isMounted) {
        state = state.copyWith(error: '当前计划为空');
      }
      return;
    }

    if (!state.canSendMessage) {
      AppLogger.warning('⚠️ 无法发送消息：AI 正在响应中');
      return;
    }

    try {
      AppLogger.info('📤 发送用户消息: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');

      // 1. 添加用户消息
      final userMessage = LLMChatMessage.user(content: message);
      if (!_isMounted) return;
      state = state.addMessage(userMessage).copyWith(
        isAIResponding: true,
        clearError: true,
      );

      // 2. 添加 AI 加载消息
      final loadingMessage = LLMChatMessage.aiLoading();
      if (!_isMounted) return;
      state = state.addMessage(loadingMessage);

      // 3. 调用 AI Service 流式生成
      String analysisContent = '';
      List<DietPlanChange>? changes;
      String? summary;
      MacrosChange? macrosChange;

      await for (final event in AIService.editDietPlanConversation(
        planId: planId,
        userMessage: message,
        currentPlan: state.currentPlan!,
      )) {
        if (!_isMounted) return;

        // 🆕 添加详细日志
        AppLogger.debug('🔔 收到事件: type=${event.type}, hasData=${event.data != null}, hasContent=${event.content != null}');
        if (event.data != null) {
          AppLogger.debug('📦 事件数据: ${event.data.toString().substring(0, event.data.toString().length > 200 ? 200 : event.data.toString().length)}...');
        }

        if (event.isThinking) {
          // 思考过程
          if (event.content != null) {
            if (!_isMounted) return;
            analysisContent += event.content!;

            final aiMessage = LLMChatMessage.ai(content: analysisContent);
            state = state.updateLastMessage(aiMessage);
          }
        } else if (event.isAnalysis) {
          // 分析阶段
          if (event.content != null) {
            AppLogger.info('📊 AI 分析: ${event.content}');
          }
        } else if (event.isSuggestion) {
          // 收到建议
          AppLogger.info('💡 检测到建议事件，开始解析...');

          if (event.data != null) {
            try {
              AppLogger.info('📝 解析 DietPlanEditSuggestion from data');

              final suggestion = DietPlanEditSuggestion.fromJson(
                Map<String, dynamic>.from(event.data as Map),
              );

              changes = suggestion.changes;
              summary = suggestion.summary;
              macrosChange = suggestion.macrosChange;

              AppLogger.info('✅ 解析成功 - ${changes?.length ?? 0} 个修改');

              // 更新最后一条消息，附加建议
              final aiMessage = LLMChatMessage.ai(
                content: analysisContent,
                suggestion: suggestion,
              );

              if (!_isMounted) return;
              state = state.updateLastMessage(aiMessage).copyWith(
                isAIResponding: false,
                pendingSuggestion: suggestion,
              );

              AppLogger.info('🎯 pendingSuggestion 已设置');
            } catch (e, stackTrace) {
              AppLogger.error('❌ 解析建议失败', e, stackTrace);
            }
          } else {
            AppLogger.warning('⚠️ 建议事件但没有 data 字段');
          }
        } else if (event.isComplete) {
          AppLogger.info('✅ AI 响应完成');

          if (!_isMounted) return;

          // 🆕 检查 complete 事件是否包含修改数据
          if (event.data != null && event.data!.containsKey('changes')) {
            AppLogger.info('🔧 complete 事件包含修改数据，尝试解析');

            try {
              final suggestion = DietPlanEditSuggestion.fromJson(
                Map<String, dynamic>.from(event.data as Map),
              );

              changes = suggestion.changes;
              summary = suggestion.summary;
              macrosChange = suggestion.macrosChange;

              AppLogger.info('✅ 从 complete 事件解析成功 - ${changes?.length ?? 0} 个修改');

              // 更新最后一条消息，附加建议
              final aiMessage = LLMChatMessage.ai(
                content: analysisContent,
                suggestion: suggestion,
              );

              if (!_isMounted) return;
              state = state.updateLastMessage(aiMessage).copyWith(
                isAIResponding: false,
                pendingSuggestion: suggestion,
              );

              AppLogger.info('🎯 pendingSuggestion 已设置（来自 complete 事件）');
            } catch (e, stackTrace) {
              AppLogger.error('❌ 从 complete 事件解析建议失败', e, stackTrace);
            }
          }

          // 如果没有使用 tool，说明是纯对话
          if (changes == null) {
            final aiMessage = LLMChatMessage.ai(content: analysisContent);
            state = state.updateLastMessage(aiMessage).copyWith(
              isAIResponding: false,
            );
          }
        } else if (event.isError) {
          AppLogger.error('❌ AI 响应错误: ${event.error}');

          if (!_isMounted) return;
          state = state.copyWith(
            isAIResponding: false,
            error: event.error,
          );
        } else {
          // 🆕 未识别的事件类型
          AppLogger.warning('⚠️ 未识别的事件类型: ${event.type}');

          // 尝试检查是否包含建议数据（可能是 tool_use 或其他类型）
          if (event.data != null && event.data!.containsKey('changes')) {
            AppLogger.info('🔧 检测到包含 changes 的未知事件类型，尝试作为建议处理');

            try {
              final suggestion = DietPlanEditSuggestion.fromJson(
                Map<String, dynamic>.from(event.data as Map),
              );

              changes = suggestion.changes;
              summary = suggestion.summary;
              macrosChange = suggestion.macrosChange;

              AppLogger.info('✅ 解析成功 - ${changes?.length ?? 0} 个修改');

              // 更新最后一条消息，附加建议
              final aiMessage = LLMChatMessage.ai(
                content: analysisContent,
                suggestion: suggestion,
              );

              if (!_isMounted) return;
              state = state.updateLastMessage(aiMessage).copyWith(
                isAIResponding: false,
                pendingSuggestion: suggestion,
              );

              AppLogger.info('🎯 pendingSuggestion 已设置（来自未知事件类型）');
            } catch (e, stackTrace) {
              AppLogger.error('❌ 解析建议失败（来自未知事件类型）', e, stackTrace);
            }
          }
        }
      }

      // 保存对话历史
      if (_currentPlanId != null) {
        await ConversationStorageService.saveConversation(_currentPlanId!, state.messages);
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 发送消息失败', e, stackTrace);
      if (!_isMounted) return;
      state = state.copyWith(
        isAIResponding: false,
        error: '发送失败: $e',
      );
    }
  }

  /// 应用建议
  Future<void> applySuggestion() async {
    if (!_isMounted) return;

    if (state.pendingSuggestion == null || state.currentPlan == null) {
      AppLogger.warning('⚠️ 没有待应用的建议');
      return;
    }

    try {
      AppLogger.info('✅ 应用修改建议 - ${state.pendingSuggestion!.changes.length} 个修改');

      // 应用修改到当前计划
      final updatedPlan = _applyChangesToPlan(
        state.currentPlan!,
        state.pendingSuggestion!.changes,
      );

      if (!_isMounted) return;

      // 更新状态
      state = state.copyWith(
        currentPlan: updatedPlan,
        clearSuggestion: true,
        currentTotalMacros: EditDietConversationState.calculatePlanMacros(updatedPlan),
      );

      AppLogger.info('✅ 修改已应用');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 应用修改失败', e, stackTrace);
      if (!_isMounted) return;
      state = state.copyWith(error: '应用修改失败: $e');
    }
  }

  /// 拒绝建议
  Future<void> rejectSuggestion() async {
    if (!_isMounted) return;

    AppLogger.info('❌ 拒绝修改建议');

    state = state.copyWith(clearSuggestion: true);
  }

  /// 应用修改到计划
  DietPlanModel _applyChangesToPlan(
    DietPlanModel plan,
    List<DietPlanChange> changes,
  ) {
    var updatedDays = List<DietDay>.from(plan.days);

    for (final change in changes) {
      try {
        switch (change.type) {
          case DietChangeType.addDay:
            updatedDays = _applyAddDay(updatedDays, change);
            break;
          case DietChangeType.removeDay:
            updatedDays = _applyRemoveDay(updatedDays, change);
            break;
          case DietChangeType.modifyDayName:
            updatedDays = _applyModifyDayName(updatedDays, change);
            break;
          case DietChangeType.addMeal:
            updatedDays = _applyAddMeal(updatedDays, change);
            break;
          case DietChangeType.removeMeal:
            updatedDays = _applyRemoveMeal(updatedDays, change);
            break;
          case DietChangeType.modifyMeal:
            updatedDays = _applyModifyMeal(updatedDays, change);
            break;
          case DietChangeType.addFoodItem:
            updatedDays = _applyAddFoodItem(updatedDays, change);
            break;
          case DietChangeType.removeFoodItem:
            updatedDays = _applyRemoveFoodItem(updatedDays, change);
            break;
          case DietChangeType.modifyFoodItem:
            updatedDays = _applyModifyFoodItem(updatedDays, change);
            break;
          case DietChangeType.adjustMacros:
            updatedDays = _applyAdjustMacros(updatedDays, change);
            break;
          default:
            AppLogger.warning('⚠️ 未处理的修改类型: ${change.type}');
        }
      } catch (e) {
        AppLogger.error('❌ 应用修改失败: ${change.type}', e);
      }
    }

    return plan.copyWith(days: updatedDays);
  }

  // ==================== 各种修改操作的实现 ====================

  List<DietDay> _applyAddDay(List<DietDay> days, DietPlanChange change) {
    final newDay = DietDay(
      day: days.length + 1,
      name: change.after as String? ?? 'Day ${days.length + 1}',
      meals: const [],
    );
    return [...days, newDay];
  }

  List<DietDay> _applyRemoveDay(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;

    final updatedDays = List<DietDay>.from(days);
    updatedDays.removeAt(change.dayIndex);

    // 重新编号
    for (int i = 0; i < updatedDays.length; i++) {
      updatedDays[i] = updatedDays[i].copyWith(day: i + 1);
    }

    return updatedDays;
  }

  List<DietDay> _applyModifyDayName(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDays[change.dayIndex].copyWith(
      name: change.after as String,
    );

    return updatedDays;
  }

  List<DietDay> _applyAddMeal(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;

    final day = days[change.dayIndex];
    final newMeal = Meal(
      name: change.after as String? ?? 'New Meal',
      items: const [],
    );

    final updatedDay = day.copyWith(
      meals: [...day.meals, newMeal],
    );

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDay;

    return updatedDays;
  }

  List<DietDay> _applyRemoveMeal(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;
    if (change.mealIndex == null) return days;

    final day = days[change.dayIndex];
    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length) return days;

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals.removeAt(change.mealIndex!);

    final updatedDay = day.copyWith(meals: updatedMeals);

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDay;

    return updatedDays;
  }

  List<DietDay> _applyModifyMeal(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;
    if (change.mealIndex == null) return days;

    final day = days[change.dayIndex];
    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length) return days;

    final meal = day.meals[change.mealIndex!];
    final updatedMeal = meal.copyWith(
      name: change.after as String,
    );

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDay;

    return updatedDays;
  }

  List<DietDay> _applyAddFoodItem(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;
    if (change.mealIndex == null) return days;

    final day = days[change.dayIndex];
    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length) return days;

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

    final updatedMeal = meal.copyWith(
      items: [...meal.items, newItem],
    );

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDay;

    return updatedDays;
  }

  List<DietDay> _applyRemoveFoodItem(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;
    if (change.mealIndex == null || change.foodItemIndex == null) return days;

    final day = days[change.dayIndex];
    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length) return days;

    final meal = day.meals[change.mealIndex!];
    if (change.foodItemIndex! < 0 || change.foodItemIndex! >= meal.items.length) return days;

    final updatedItems = List<FoodItem>.from(meal.items);
    updatedItems.removeAt(change.foodItemIndex!);

    final updatedMeal = meal.copyWith(items: updatedItems);

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[change.mealIndex!] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDay;

    return updatedDays;
  }

  List<DietDay> _applyModifyFoodItem(List<DietDay> days, DietPlanChange change) {
    if (change.dayIndex < 0 || change.dayIndex >= days.length) return days;
    if (change.mealIndex == null || change.foodItemIndex == null) return days;

    final day = days[change.dayIndex];
    if (change.mealIndex! < 0 || change.mealIndex! >= day.meals.length) return days;

    final meal = day.meals[change.mealIndex!];
    if (change.foodItemIndex! < 0 || change.foodItemIndex! >= meal.items.length) return days;

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

    final updatedDays = List<DietDay>.from(days);
    updatedDays[change.dayIndex] = updatedDay;

    return updatedDays;
  }

  List<DietDay> _applyAdjustMacros(List<DietDay> days, DietPlanChange change) {
    // 调整营养比例 - 可以是全局调整或针对特定餐次/食物
    // 这里简化实现，实际可以更复杂
    AppLogger.info('🔧 调整营养比例: ${change.description}');
    return days;
  }

  /// 清除错误
  void clearError() {
    if (!_isMounted) return;
    state = state.copyWith(clearError: true);
  }
}
