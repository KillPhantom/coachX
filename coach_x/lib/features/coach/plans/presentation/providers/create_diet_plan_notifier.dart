import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/features/coach/plans/data/models/create_diet_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/data/repositories/diet_plan_repository.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_import_stats.dart';
import 'package:coach_x/core/enums/ai_status.dart';

/// 创建饮食计划状态管理
class CreateDietPlanNotifier extends StateNotifier<CreateDietPlanState> {
  final DietPlanRepository _dietPlanRepository;

  CreateDietPlanNotifier(this._dietPlanRepository)
    : super(const CreateDietPlanState());

  // ==================== 基础字段更新 ====================

  /// 更新计划名称
  void updatePlanName(String name) {
    state = state.copyWith(planName: name);
  }

  /// 更新描述
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  // ==================== 饮食日管理 ====================

  /// 添加饮食日
  void addDay({String? name}) {
    final dayNumber = state.days.length + 1;
    final newDay = DietDay(
      day: dayNumber,
      name: name ?? 'Day $dayNumber',
      meals: const [],
      completed: false,
    );

    final updatedDays = [...state.days, newDay];
    state = state.copyWith(days: updatedDays);

    AppLogger.debug('➕ 添加饮食日 - Day $dayNumber');
  }

  /// 删除饮食日
  void removeDay(int index) {
    if (index < 0 || index >= state.days.length) return;

    final updatedDays = List<DietDay>.from(state.days);
    updatedDays.removeAt(index);

    // 重新编号
    for (int i = 0; i < updatedDays.length; i++) {
      updatedDays[i] = updatedDays[i].copyWith(day: i + 1);
    }

    state = state.copyWith(days: updatedDays);

    AppLogger.debug('🗑️ 删除饮食日 - Index $index');
  }

  /// 更新饮食日
  void updateDay(int index, DietDay day) {
    if (index < 0 || index >= state.days.length) return;

    final updatedDays = List<DietDay>.from(state.days);
    updatedDays[index] = day;

    state = state.copyWith(days: updatedDays);
  }

  /// 更新饮食日名称
  void updateDayName(int dayIndex, String name) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final updatedDay = day.copyWith(name: name);
    updateDay(dayIndex, updatedDay);
  }

  /// 更新饮食日目标宏量营养素
  void updateDayTargetMacros(
    int dayIndex, {
    double? protein,
    double? carbs,
    double? fat,
  }) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final currentTarget = day.targetMacros ?? day.macros;

    final newProtein = protein ?? currentTarget.protein;
    final newCarbs = carbs ?? currentTarget.carbs;
    final newFat = fat ?? currentTarget.fat;
    final newCalories = (newProtein * 4) + (newCarbs * 4) + (newFat * 9);

    final updatedTarget = currentTarget.copyWith(
      protein: newProtein,
      carbs: newCarbs,
      fat: newFat,
      calories: newCalories,
    );

    final updatedDay = day.copyWith(targetMacros: updatedTarget);
    updateDay(dayIndex, updatedDay);
  }

  // ==================== 餐次管理 ====================

  /// 添加餐次
  void addMeal(int dayIndex, {Meal? meal}) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final newMeal = meal ?? Meal.empty();
    final updatedMeals = [...day.meals, newMeal];
    final updatedDay = day.copyWith(meals: updatedMeals);

    updateDay(dayIndex, updatedDay);

    AppLogger.debug('➕ 添加餐次 - Day ${dayIndex + 1}');
  }

  /// 删除餐次
  void removeMeal(int dayIndex, int mealIndex) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals.removeAt(mealIndex);
    final updatedDay = day.copyWith(meals: updatedMeals);

    updateDay(dayIndex, updatedDay);

    AppLogger.debug('🗑️ 删除餐次 - Day ${dayIndex + 1}, Meal ${mealIndex + 1}');
  }

  /// 更新餐次
  void updateMeal(int dayIndex, int mealIndex, Meal meal) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[mealIndex] = meal;
    final updatedDay = day.copyWith(meals: updatedMeals);

    updateDay(dayIndex, updatedDay);
  }

  /// 更新餐次名称
  void updateMealName(int dayIndex, int mealIndex, String name) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final meal = day.meals[mealIndex];
    final updatedMeal = meal.copyWith(name: name);
    updateMeal(dayIndex, mealIndex, updatedMeal);
  }

  /// 更新餐次备注
  void updateMealNote(int dayIndex, int mealIndex, String note) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final meal = day.meals[mealIndex];
    final updatedMeal = meal.copyWith(note: note);
    updateMeal(dayIndex, mealIndex, updatedMeal);
  }

  // ==================== 食物条目管理 ====================

  /// 添加食物条目
  void addFoodItem(int dayIndex, int mealIndex, {FoodItem? item}) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final meal = day.meals[mealIndex];
    final newItem = item ?? FoodItem.empty();
    final updatedItems = [...meal.items, newItem];
    final updatedMeal = meal.copyWith(items: updatedItems);

    updateMeal(dayIndex, mealIndex, updatedMeal);

    AppLogger.debug('➕ 添加食物条目 - Day ${dayIndex + 1}, Meal ${mealIndex + 1}');
  }

  /// 删除食物条目
  void removeFoodItem(int dayIndex, int mealIndex, int itemIndex) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final meal = day.meals[mealIndex];
    if (itemIndex < 0 || itemIndex >= meal.items.length) return;

    final updatedItems = List<FoodItem>.from(meal.items);
    updatedItems.removeAt(itemIndex);
    final updatedMeal = meal.copyWith(items: updatedItems);

    updateMeal(dayIndex, mealIndex, updatedMeal);

    AppLogger.debug(
      '🗑️ 删除食物条目 - Day ${dayIndex + 1}, Meal ${mealIndex + 1}, Item ${itemIndex + 1}',
    );
  }

  /// 更新食物条目
  void updateFoodItem(
    int dayIndex,
    int mealIndex,
    int itemIndex,
    FoodItem item,
  ) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final meal = day.meals[mealIndex];
    if (itemIndex < 0 || itemIndex >= meal.items.length) return;

    final updatedItems = List<FoodItem>.from(meal.items);
    updatedItems[itemIndex] = item;
    final updatedMeal = meal.copyWith(items: updatedItems);

    updateMeal(dayIndex, mealIndex, updatedMeal);
  }

  /// 更新食物条目的单个字段
  void updateFoodItemField(
    int dayIndex,
    int mealIndex,
    int itemIndex, {
    String? food,
    String? amount,
    double? protein,
    double? carbs,
    double? fat,
    double? calories,
  }) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (mealIndex < 0 || mealIndex >= day.meals.length) return;

    final meal = day.meals[mealIndex];
    if (itemIndex < 0 || itemIndex >= meal.items.length) return;

    final item = meal.items[itemIndex];
    final updatedItem = item.copyWith(
      food: food,
      amount: amount,
      protein: protein,
      carbs: carbs,
      fat: fat,
      calories: calories,
    );

    updateFoodItem(dayIndex, mealIndex, itemIndex, updatedItem);
  }

  // ==================== 验证 ====================

  /// 验证当前计划
  void validate() {
    final errors = <String>[];

    // 验证计划名称
    if (state.planName.trim().isEmpty) {
      errors.add('计划名称不能为空');
    }

    // 验证至少有一个饮食日
    if (state.days.isEmpty) {
      errors.add('至少需要添加一个饮食日');
    }

    // 验证每个饮食日
    for (int i = 0; i < state.days.length; i++) {
      final day = state.days[i];
      // 验证每个餐次
      for (int j = 0; j < day.meals.length; j++) {
        final meal = day.meals[j];

        // 验证餐次名称
        if (meal.name.trim().isEmpty) {
          errors.add('第 ${i + 1} 天的第 ${j + 1} 个餐次需要名称');
        }

        // 验证至少有一个食物条目
        if (meal.items.isEmpty) {
          errors.add('第 ${i + 1} 天的第 ${j + 1} 个餐次至少需要添加一个食物条目');
        }

        // 验证每个食物条目
        for (int k = 0; k < meal.items.length; k++) {
          final item = meal.items[k];

          if (item.food.trim().isEmpty) {
            errors.add('第 ${i + 1} 天的第 ${j + 1} 个餐次的第 ${k + 1} 个食物需要名称');
          }

          if (item.amount.trim().isEmpty) {
            errors.add('第 ${i + 1} 天的第 ${j + 1} 个餐次的第 ${k + 1} 个食物需要分量');
          }
        }
      }
    }

    state = state.copyWith(validationErrors: errors);

    if (errors.isNotEmpty) {
      AppLogger.warning('⚠️ 验证失败: ${errors.first}');
    }
  }

  // ==================== 保存与加载 ====================

  /// 加载现有计划
  Future<bool> loadPlan(String planId) async {
    try {
      state = state.copyWith(isLoading: true);

      AppLogger.info('📖 加载饮食计划 - ID: $planId');

      // 从Repository加载计划
      final plan = await _dietPlanRepository.getPlan(planId);

      if (plan == null) {
        throw Exception('计划不存在');
      }

      // 生成初始快照 JSON
      final initialDaysJson = jsonEncode(plan.days.map((d) => d.toJson()).toList());

      // 更新状态（包含初始快照）
      state = state.copyWith(
        planId: plan.id,
        planName: plan.name,
        description: plan.description,
        days: plan.days,
        isLoading: false,
        isEditMode: true,
        initialPlanName: plan.name,
        initialDescription: plan.description,
        initialDaysJson: initialDaysJson,
      );

      AppLogger.info('✅ 饮食计划加载成功: ${plan.name}');

      return true;
    } catch (e) {
      AppLogger.error('❌ 加载饮食计划失败', e);

      state = state.copyWith(isLoading: false, errorMessage: '加载失败: $e');

      return false;
    }
  }

  /// 保存计划
  Future<bool> savePlan() async {
    try {
      // 验证
      validate();
      if (state.validationErrors.isNotEmpty) {
        state = state.copyWith(errorMessage: state.validationErrors.first);
        return false;
      }

      state = state.copyWith(isLoading: true);

      AppLogger.info('💾 保存饮食计划: ${state.planName}');

      // 创建计划对象
      final plan = DietPlanModel(
        id: state.planId ?? '', // 编辑模式使用现有ID
        name: state.planName,
        description: state.description,
        ownerId: '', // 服务端填充
        studentIds: const [],
        createdAt: 0, // 服务端填充
        updatedAt: 0, // 服务端填充
        days: state.days,
      );

      // 根据是否有planId判断是创建还是更新
      String planId;
      if (state.isEditMode &&
          state.planId != null &&
          state.planId!.isNotEmpty) {
        // 更新现有计划
        await _dietPlanRepository.updatePlan(plan);
        planId = state.planId!;
        AppLogger.info('✅ 饮食计划更新成功 - ID: $planId');
      } else {
        // 创建新计划
        planId = await _dietPlanRepository.createPlan(plan);
        AppLogger.info('✅ 饮食计划创建成功 - ID: $planId');
      }

      state = state.copyWith(isLoading: false, planId: planId);

      return true;
    } catch (e) {
      AppLogger.error('❌ 保存饮食计划失败', e);

      state = state.copyWith(isLoading: false, errorMessage: '保存失败: $e');

      return false;
    }
  }

  // ==================== AI 流式生成步骤管理 ====================

  /// 更新流式生成步骤
  void _updateStep(int step, double progress) {
    state = state.copyWith(
      currentStep: step,
      currentStepProgress: progress,
    );
    AppLogger.debug('📊 Diet Streaming Step: $step, Progress: $progress%');
  }

  /// 计算饮食统计数据（BMR, TDEE, 目标热量）
  DietPlanImportStats _calculateDietStats(DietPlanGenerationParams params) {
    // 计算 BMR (Basal Metabolic Rate) 使用 Mifflin-St Jeor 公式
    double bmr;
    if (params.gender == 'male') {
      bmr = (10 * params.weightKg) +
          (6.25 * params.heightCm) -
          (5 * params.age) +
          5;
    } else {
      bmr = (10 * params.weightKg) +
          (6.25 * params.heightCm) -
          (5 * params.age) -
          161;
    }

    // 计算 TDEE (Total Daily Energy Expenditure)
    double activityMultiplier;
    switch (params.activityLevel.name) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'veryActive':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.2;
    }
    final tdee = bmr * activityMultiplier;

    // 根据饮食目标计算目标热量
    double targetCalories;
    switch (params.goal.name) {
      case 'muscleGain':
        targetCalories = tdee * 1.1; // +10% 增肌
        break;
      case 'fatLoss':
        targetCalories = tdee * 0.85; // -15% 减脂
        break;
      case 'maintenance':
        targetCalories = tdee; // 维持
        break;
      default:
        targetCalories = tdee;
    }

    final totalDays = state.days.length;
    final totalMeals = state.days.fold<int>(
      0,
      (sum, day) => sum + day.meals.length,
    );

    return DietPlanImportStats(
      totalDays: totalDays,
      totalMeals: totalMeals,
      bmr: bmr.roundToDouble(),
      tdee: tdee.roundToDouble(),
      targetCalories: targetCalories.roundToDouble(),
    );
  }

  // ==================== AI 生成 ====================

  /// 流式生成饮食计划
  ///
  /// 使用 AI 实时接收生成进度
  /// [params] 结构化参数
  Future<void> generateFromParamsStreaming(DietPlanGenerationParams params) async {
    try {
      AppLogger.info('🔄 开始流式生成饮食计划');

      // Step 1: 分析饮食要求 (0-20%)
      _updateStep(1, 0);
      await Future.delayed(const Duration(milliseconds: 300));
      _updateStep(1, 20);

      // 清空现有数据
      state = state.copyWith(
        days: [],
        aiStatus: AIGenerationStatus.generating,
        errorMessage: '',
        currentDayInProgress: null,
      );

      // 延迟让用户看到 Step 1
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: 生成饮食计划 (20% → 85%)
      _updateStep(2, 20);

      // 调用 AI Service 生成
      final result = await AIService.generateDietPlanWithSkill(
        params: params.toJson(),
      );

      // 模拟进度更新
      _updateStep(2, 50);
      await Future.delayed(const Duration(milliseconds: 300));

      // 解析返回的数据
      final name = result['name'] as String;
      final description = result['description'] as String;
      final daysData = result['days'] as List;

      // 转换为 DietDay 列表
      final days = daysData.map((dayJson) {
        return DietDay.fromJson(Map<String, dynamic>.from(dayJson as Map));
      }).toList();

      _updateStep(2, 85);
      await Future.delayed(const Duration(milliseconds: 300));

      AppLogger.info('✅ AI 生成完成 - ${days.length} 天');

      // 更新状态
      state = state.copyWith(
        planName: name,
        description: description,
        days: days,
      );

      // Step 3: 计算营养数据 (85% → 95%)
      _updateStep(3, 85);
      await Future.delayed(const Duration(milliseconds: 300));

      // 计算统计
      final stats = _calculateDietStats(params);
      state = state.copyWith(dietStreamingStats: stats);

      _updateStep(3, 95);
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: 完成生成 (100%)
      _updateStep(4, 100);

      state = state.copyWith(
        aiStatus: AIGenerationStatus.success,
        currentDayInProgress: null,
      );

      AppLogger.info('🎉 流式生成完成 - 共 ${state.days.length} 天');

      // 保持在当前状态，等待用户点击"查看完整计划"按钮
    } catch (e, stackTrace) {
      AppLogger.error('❌ 流式生成饮食计划失败', e, stackTrace);

      state = state.copyWith(
        aiStatus: AIGenerationStatus.error,
        errorMessage: 'AI 生成失败: $e',
        currentDayInProgress: null,
      );
    }
  }

  /// 从文本导入饮食计划
  ///
  /// [textContent] 文本内容（OCR 提取或用户粘贴）
  Future<void> importFromText(String textContent) async {
    try {
      AppLogger.info('📥 开始从文本导入饮食计划');

      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        aiStatus: AIGenerationStatus.generating,
      );

      // TODO: 实现文本解析逻辑
      // 目前暂时抛出未实现错误
      throw UnimplementedError('文本导入功能待实现');

      // 预期流程：
      // 1. 调用 AI Service 解析文本
      // 2. 转换为 DietDay 列表
      // 3. 计算统计数据
      // 4. 更新状态
    } catch (e, stackTrace) {
      AppLogger.error('❌ 文本导入失败', e, stackTrace);

      state = state.copyWith(
        isLoading: false,
        aiStatus: AIGenerationStatus.error,
        errorMessage: '文本导入失败: $e',
      );
    }
  }

  /// 使用 Claude Skill 生成饮食计划（旧方法，保留兼容）
  Future<void> generateFromSkill(DietPlanGenerationParams params) async {
    try {
      // 清除之前的错误并设置加载状态
      state = CreateDietPlanState(
        planId: state.planId,
        planName: state.planName,
        description: state.description,
        days: state.days,
        isLoading: true,
        isEditMode: state.isEditMode,
        errorMessage: null,
        validationErrors: const [],
      );

      AppLogger.info('🤖 调用 AI 生成饮食计划');

      // 调用 AI Service
      final result = await AIService.generateDietPlanWithSkill(
        params: params.toJson(),
      );

      // 解析返回的数据
      final name = result['name'] as String;
      final description = result['description'] as String;
      final daysData = result['days'] as List;

      // 转换为 DietDay 列表
      final days = daysData.map((dayJson) {
        // 显式转换嵌套的 Map 类型
        return DietDay.fromJson(Map<String, dynamic>.from(dayJson as Map));
      }).toList();

      AppLogger.info('✅ AI 生成完成 - ${days.length} 天');

      // 更新状态（成功时清除错误）
      state = CreateDietPlanState(
        planId: state.planId,
        planName: name,
        description: description,
        days: days,
        isLoading: false,
        isEditMode: state.isEditMode,
        errorMessage: null,
        validationErrors: const [],
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ AI 生成饮食计划失败', e, stackTrace);

      state = state.copyWith(isLoading: false, errorMessage: 'AI 生成失败: $e');
    }
  }

  // ==================== 应用修改后的计划 ====================

  /// 应用 AI 修改后的计划
  ///
  /// 用于从 Review Mode 应用最终的修改后计划
  void applyModifiedPlan(DietPlanModel modifiedPlan) {
    AppLogger.info('✅ 应用 AI 修改后的饮食计划 - ${modifiedPlan.days.length} 天');

    state = state.copyWith(
      planName: modifiedPlan.name,
      description: modifiedPlan.description,
      days: modifiedPlan.days,
    );
  }

  // ==================== 重置 ====================

  /// 重置状态
  void reset() {
    state = const CreateDietPlanState();
    AppLogger.debug('🔄 重置创建饮食计划状态');
  }

  /// 保存当前状态为初始快照（用于判断是否有修改）
  void saveInitialSnapshot() {
    final initialDaysJson = jsonEncode(state.days.map((d) => d.toJson()).toList());
    state = state.copyWith(
      initialPlanName: state.planName,
      initialDescription: state.description,
      initialDaysJson: initialDaysJson,
    );
    AppLogger.debug('📸 保存初始快照 - days: ${state.days.length}');
  }

  /// 清空错误
  void clearError() {
    state = state.clearError();
  }
}
