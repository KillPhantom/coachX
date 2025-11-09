import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/ai_food_analysis_state.dart';
import '../../data/models/recognized_food.dart';
import '../../data/models/food_record_mode.dart';
import '../../data/repositories/ai_food_repository.dart';
import '../../data/repositories/ai_food_repository_impl.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';
import 'package:coach_x/features/student/home/presentation/providers/student_home_providers.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/student/diet/data/models/student_diet_record_model.dart';
import 'package:coach_x/features/student/diet/data/repositories/diet_record_repository.dart';
import 'package:coach_x/features/student/diet/data/repositories/diet_record_repository_impl.dart';
import 'package:coach_x/app/providers.dart' as app_providers;

/// AI食物扫描状态管理
class AIFoodScannerNotifier extends StateNotifier<AIFoodAnalysisState> {
  final Ref ref;
  final AIFoodRepository _aiFoodRepository = AIFoodRepositoryImpl();
  final DietRecordRepository _dietRecordRepository = DietRecordRepositoryImpl();

  AIFoodScannerNotifier(this.ref) : super(AIFoodAnalysisState.initial());

  /// 设置记录模式
  void setRecordMode(FoodRecordMode mode) {
    state = state.copyWith(recordMode: mode);
    AppLogger.info('✅ 切换记录模式: $mode');
  }

  /// 后台上传图片
  Future<void> uploadImage(String imagePath) async {
    try {
      AppLogger.info('📤 开始后台上传图片: $imagePath');

      // 获取用户信息
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'food_images/${user.uid}/$fileName';

      final imageFile = File(imagePath);
      final imageUrl = await StorageService.uploadFile(imageFile, storagePath);

      AppLogger.info('✅ 图片上传成功: $imageUrl');

      // 更新状态：保存图片URL
      state = state.copyWith(imageUrl: imageUrl);

      // AI Scanner模式下自动分析
      if (state.recordMode == FoodRecordMode.aiScanner) {
        AppLogger.info('🤖 AI Scanner模式，自动开始分析');
        await analyzeImageWithAI();
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 图片上传失败', e, stackTrace);
      state = AIFoodAnalysisState.error(error: '图片上传失败: $e');
    }
  }

  /// 更新本餐进度（输入框值）
  void updateCurrentMacros({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    state = state.copyWith(
      currentCalories: calories ?? state.currentCalories,
      currentProtein: protein ?? state.currentProtein,
      currentCarbs: carbs ?? state.currentCarbs,
      currentFat: fat ?? state.currentFat,
    );
    AppLogger.info('✅ 更新本餐进度: [$calories, $protein, $carbs, $fat]');
  }

  /// AI分析图片（使用已上传的imageUrl）
  Future<void> analyzeImageWithAI() async {
    try {
      if (state.imageUrl == null) {
        throw Exception('图片尚未上传完成');
      }

      AppLogger.info('🤖 开始AI分析图片: ${state.imageUrl}');

      // 设置分析中状态
      state = state.copyWith(isAnalyzing: true, progress: 0.5);

      // 调用AI分析
      final foods = await _aiFoodRepository.analyzeFoodImage(
        imageUrl: state.imageUrl!,
        language: '中文',
      );

      AppLogger.info('✅ AI分析完成，识别到 ${foods.length} 种食物');

      // 计算所有食物的营养总和
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      final foodNotes = <String>[];

      for (var food in foods) {
        totalCalories += food.macros.calories;
        totalProtein += food.macros.protein;
        totalCarbs += food.macros.carbs;
        totalFat += food.macros.fat;
        foodNotes.add('• ${food.name} ${food.estimatedWeight}');
      }

      // 生成食物备注
      final aiDetectedFoods = foodNotes.join('\n');

      // 更新状态：自动填入输入框 + 保存识别结果
      state = state.copyWith(
        isAnalyzing: false,
        progress: 1.0,
        foods: foods,
        currentCalories: totalCalories,
        currentProtein: totalProtein,
        currentCarbs: totalCarbs,
        currentFat: totalFat,
        aiDetectedFoods: aiDetectedFoods,
      );

      AppLogger.info('✅ 自动填入营养数据: [$totalCalories kcal, $totalProtein g, $totalCarbs g, $totalFat g]');
    } catch (e, stackTrace) {
      AppLogger.error('❌ AI分析失败', e, stackTrace);
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'AI分析失败: $e',
      );
    }
  }

  /// 更新单个食物的营养数据
  void updateFoodMacros(int index, RecognizedFood updatedFood) {
    if (index < 0 || index >= state.foods.length) {
      AppLogger.warning('⚠️ 更新食物索引越界: $index');
      return;
    }

    final updatedFoods = List<RecognizedFood>.from(state.foods);
    updatedFoods[index] = updatedFood;

    state = state.copyWith(foods: updatedFoods);
    AppLogger.info('✅ 更新食物数据: ${updatedFood.name}');
  }

  /// 选择保存到的meal
  void selectMeal(String mealName) {
    state = state.copyWith(selectedMealName: mealName);
    AppLogger.info('✅ 选择meal: $mealName');

    // 从 studentPlansProvider 获取该 meal 的计划值，初始化输入框
    final plansAsync = ref.read(studentPlansProvider);
    final dayNumbers = ref.read(currentDayNumbersProvider);

    // 处理异步状态
    if (plansAsync.value == null || plansAsync.value!.dietPlan == null) {
      AppLogger.warning('⚠️ 饮食计划未加载');
      return;
    }

    final plans = plansAsync.value!;
    final dayNum = dayNumbers['diet'] ?? 1;

    try {
      final dietDay = plans.dietPlan!.days.firstWhere(
        (day) => day.day == dayNum,
        orElse: () => plans.dietPlan!.days.first,
      );

      final targetMeal = dietDay.meals.firstWhere(
        (meal) => meal.name == mealName,
      );

      // 使用计划值初始化输入框
      state = state.copyWith(
        currentCalories: targetMeal.macros.calories,
        currentProtein: targetMeal.macros.protein,
        currentCarbs: targetMeal.macros.carbs,
        currentFat: targetMeal.macros.fat,
      );

      AppLogger.info(
        '✅ 初始化本餐进度为计划值: [${targetMeal.macros.calories}, ${targetMeal.macros.protein}, ${targetMeal.macros.carbs}, ${targetMeal.macros.fat}]',
      );
    } catch (e) {
      AppLogger.warning('⚠️ 未找到meal: $mealName');
    }
  }

  /// 保存食物到饮食记录
  Future<void> saveFoodsToMeal() async {
    try {
      // 1. 验证输入
      if (state.selectedMealName == null || state.selectedMealName!.isEmpty) {
        throw Exception('请选择要保存到的餐次');
      }

      if (state.currentCalories == null) {
        // AI Scanner模式下，必须有AI识别的营养数据
        if (state.recordMode == FoodRecordMode.aiScanner && state.foods.isEmpty) {
          throw Exception('请等待AI分析完成');
        }
        // Simple Record模式下，必须有手动输入的营养数据
        if (state.recordMode == FoodRecordMode.simpleRecord) {
          throw Exception('请输入营养数据');
        }
      }

      AppLogger.info('💾 保存食物记录到meal: ${state.selectedMealName} (模式: ${state.recordMode})');

      // 2. 获取今日日期
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 3. 获取今日训练记录
      DailyTrainingModel? todayTraining =
          await _dietRecordRepository.getTodayTraining(date);

      // 4. 如果不存在，创建新记录
      if (todayTraining == null) {
        AppLogger.info('创建新的今日训练记录');

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('用户未登录');
        }

        // 获取用户信息（包含 coachId）
        final userAsync = ref.read(app_providers.currentUserProvider);
        final userInfo = userAsync.value;
        if (userInfo == null || userInfo.coachId == null) {
          throw Exception('未找到教练信息，请确保已绑定教练');
        }

        // 获取计划信息
        final plansAsync = ref.read(studentPlansProvider);
        final plans = plansAsync.value;
        if (plans == null || plans.dietPlan == null) {
          throw Exception('未找到饮食计划');
        }

        final dayNumbers = ref.read(currentDayNumbersProvider);

        // 创建空的 StudentDietRecordModel（使用计划中的 meals 结构）
        final dayNum = dayNumbers['diet'] ?? 1;
        final dietDay = plans.dietPlan!.days.firstWhere(
          (day) => day.day == dayNum,
          orElse: () => plans.dietPlan!.days.first,
        );

        todayTraining = DailyTrainingModel(
          id: '', // 后端会生成ID
          studentId: user.uid,
          coachId: userInfo.coachId!,
          date: date,
          planSelection: TrainingDaySelection(
            exercisePlanId: plans.exercisePlan?.id,
            exerciseDayNumber: dayNumbers['exercise'],
            dietPlanId: plans.dietPlan?.id,
            dietDayNumber: dayNum,
            supplementPlanId: plans.supplementPlan?.id,
            supplementDayNumber: dayNumbers['supplement'],
          ),
          diet: StudentDietRecordModel(
            macros: dietDay.macros,
            meals: dietDay.meals,
            studentFeedback: '',
            coachFeedback: '',
          ),
        );
      }

      // 5. 找到对应的 Meal 并添加 FoodItem
      final currentDiet = todayTraining.diet;
      if (currentDiet == null) {
        throw Exception('饮食记录为空');
      }

      final targetMeal = currentDiet.meals.firstWhere(
        (meal) => meal.name == state.selectedMealName,
        orElse: () => throw Exception('未找到指定的餐次'),
      );

      // 创建 FoodItem 保存用户输入的营养值
      final foodItem = FoodItem(
        food: state.aiDetectedFoods != null ? 'AI识别食物' : '手动记录',
        amount: state.aiDetectedFoods ?? '',
        protein: state.currentProtein ?? 0.0,
        carbs: state.currentCarbs ?? 0.0,
        fat: state.currentFat ?? 0.0,
        calories: state.currentCalories ?? 0.0,
        isCustomInput: true,
      );

      final updatedMeal = targetMeal.copyWith(
        items: [...targetMeal.items, foodItem],
        images: state.imageUrl != null
            ? [...targetMeal.images, state.imageUrl!]
            : targetMeal.images,
      );

      // 6. 更新 diet
      final updatedMeals = currentDiet.meals.map((meal) {
        return meal.name == state.selectedMealName ? updatedMeal : meal;
      }).toList();

      final updatedDiet = currentDiet.copyWith(meals: updatedMeals);

      final updatedTraining = DailyTrainingModel(
        id: todayTraining.id,
        studentId: todayTraining.studentId,
        coachId: todayTraining.coachId,
        date: todayTraining.date,
        planSelection: todayTraining.planSelection,
        diet: updatedDiet,
        exercises: todayTraining.exercises,
        supplements: todayTraining.supplements,
        completionStatus: todayTraining.completionStatus,
        isReviewed: todayTraining.isReviewed,
      );

      // 7. 保存到后端
      await _dietRecordRepository.saveDietRecord(updatedTraining);

      AppLogger.info('✅ 食物记录已保存到后端');
      AppLogger.info(
        '   营养值: [${state.currentCalories} kcal, ${state.currentProtein}g, ${state.currentCarbs}g, ${state.currentFat}g]',
      );

      // 8. 刷新首页数据
      ref.invalidate(latestTrainingProvider);

      AppLogger.info('✅ 刷新首页数据');

      // 9. 重置分析状态
      state = AIFoodAnalysisState.initial();
    } catch (e, stackTrace) {
      AppLogger.error('❌ 保存食物失败', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// 重置状态
  void reset() {
    state = AIFoodAnalysisState.initial();
    AppLogger.info('🔄 重置AI扫描状态');
  }
}
