import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../providers/ai_food_scanner_providers.dart';
import '../../../home/presentation/providers/student_home_providers.dart';
import 'meal_progress_input_card.dart';
import '../../data/models/food_record_mode.dart';
import '../../data/models/ai_food_analysis_state.dart';

/// 食物分析Bottom Sheet（重构版 - 支持两种模式）
///
/// AI Scanner模式: 显示照片 → 自动AI分析 → 显示结果 → 选择餐次 → 保存
/// Simple Record模式: 显示照片 → 选择餐次 → 手动输入营养 → 保存
class FoodAnalysisBottomSheet extends ConsumerStatefulWidget {
  final String imagePath;
  final FoodRecordMode recordMode;
  final VoidCallback onComplete;

  const FoodAnalysisBottomSheet({
    super.key,
    required this.imagePath,
    required this.recordMode,
    required this.onComplete,
  });

  @override
  ConsumerState<FoodAnalysisBottomSheet> createState() =>
      _FoodAnalysisBottomSheetState();
}

class _FoodAnalysisBottomSheetState
    extends ConsumerState<FoodAnalysisBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 设置记录模式
      ref.read(aiFoodScannerProvider.notifier).setRecordMode(widget.recordMode);

      // 上传图片（AI模式会自动分析，Simple模式不会）
      ref.read(aiFoodScannerProvider.notifier).uploadImage(widget.imagePath);
    });
  }

  /// 保存记录
  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(aiFoodScannerProvider);

    try {
      // AI Scanner模式：如果没有选择餐次，先显示选择器
      if (state.recordMode == FoodRecordMode.aiScanner &&
          state.selectedMealName == null) {
        await _showMealPickerForAIMode();
        return;
      }

      // 确保有图片URL（必需）
      if (state.imageUrl == null || state.imageUrl!.isEmpty) {
        throw Exception('图片尚未上传完成，请稍候再试');
      }

      // 执行保存
      await ref.read(aiFoodScannerProvider.notifier).saveFoodsToMeal();

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(l10n.recordSaved),
            content: Text(l10n.recordSavedSuccess),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  widget.onComplete();
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ 保存食物失败', e);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(l10n.recordSaveFailed),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 显示餐次选择器（AI模式专用）
  Future<void> _showMealPickerForAIMode() async {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.read(studentPlansProvider);
    final dayNumbers = ref.read(currentDayNumbersProvider);

    if (plansAsync.value == null || plansAsync.value!.dietPlan == null) {
      throw Exception('未找到饮食计划');
    }

    final plans = plansAsync.value!;
    final dayNum = dayNumbers['diet'] ?? 1;

    // 查找当前天数的dietDay
    final dietDayIndex = plans.dietPlan!.days.indexWhere(
      (day) => day.day == dayNum,
    );
    final dietDay = dietDayIndex != -1
        ? plans.dietPlan!.days[dietDayIndex]
        : plans.dietPlan!.days.first;

    final availableMeals = dietDay.meals;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: AppColors.backgroundWhite,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(l10n.cancel, style: AppTextStyles.callout),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text(
                    l10n.ok,
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 选择完成后自动保存
                    _handleSave();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40.0,
                onSelectedItemChanged: (int index) {
                  ref
                      .read(aiFoodScannerProvider.notifier)
                      .selectMeal(availableMeals[index].name);
                },
                children: availableMeals.map<Widget>((meal) {
                  return Center(
                    child: Text(meal.name, style: AppTextStyles.body),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(aiFoodScannerProvider);
    final plansAsync = ref.watch(studentPlansProvider);

    return plansAsync.when(
      loading: () => _buildLoadingView(context),
      error: (error, stack) => _buildErrorView(context, error.toString()),
      data: (plans) {
        if (plans.dietPlan == null) {
          return _buildNoPlanView(context, l10n);
        }

        // 根据记录模式显示不同内容
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildNavigationBar(context, l10n),
                Expanded(
                  child: state.recordMode == FoodRecordMode.aiScanner
                      ? _buildAIScannerContent(context, l10n, state, plans)
                      : _buildSimpleRecordContent(context, l10n, state, plans),
                ),
                _buildSaveButton(l10n, state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(BuildContext context, String error) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Center(
        child: Text(
          '加载计划失败: $error',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  /// 构建无计划视图
  Widget _buildNoPlanView(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildNavigationBar(context, l10n),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  margin: const EdgeInsets.all(AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      Text(
                        '未找到今日饮食计划',
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildNavigationBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.xmark,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          Text(l10n.addFoodRecord, style: AppTextStyles.navTitle),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// 构建AI Scanner模式内容
  Widget _buildAIScannerContent(
    BuildContext context,
    AppLocalizations l10n,
    state,
    plans,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      children: [
        // 照片预览
        _buildPhotoPreview(),
        const SizedBox(height: AppDimensions.spacingL),

        // AI分析中
        if (state.isAnalyzing) _buildAIProgressBar(l10n, state.progress),

        // AI分析结果
        if (!state.isAnalyzing && state.foods.isNotEmpty)
          _buildAIResultsView(l10n, state),

        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  /// 构建Simple Record模式内容
  Widget _buildSimpleRecordContent(
    BuildContext context,
    AppLocalizations l10n,
    state,
    plans,
  ) {
    final dayNumbers = ref.watch(currentDayNumbersProvider);
    final dayNum = dayNumbers['diet'] ?? 1;

    // 查找当前天数的dietDay
    final dietDayIndex = plans.dietPlan!.days.indexWhere(
      (day) => day.day == dayNum,
    );
    final dietDay = dietDayIndex != -1
        ? plans.dietPlan!.days[dietDayIndex]
        : plans.dietPlan!.days.first;

    final availableMeals = dietDay.meals;

    // 查找选中的meal
    final selectedMeal = state.selectedMealName != null
        ? availableMeals.cast<dynamic>().firstWhere(
            (meal) => meal.name == state.selectedMealName,
            orElse: () => availableMeals.first,
          )
        : null;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      children: [
        // 照片预览
        _buildPhotoPreview(),
        const SizedBox(height: AppDimensions.spacingL),

        // 餐次选择
        _buildMealSelector(l10n, availableMeals, state),

        // 营养输入卡片
        if (selectedMeal != null) ...[
          const SizedBox(height: AppDimensions.spacingL),
          MealProgressInputCard(planMeal: selectedMeal),
        ],

        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  /// 构建照片预览
  Widget _buildPhotoPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Image.file(
        File(widget.imagePath),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 构建AI进度条
  Widget _buildAIProgressBar(AppLocalizations l10n, double progress) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        children: [
          const CupertinoActivityIndicator(radius: 16.0),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.aiAnalyzing,
            style: AppTextStyles.callout.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.dividerLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryColor,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建AI分析结果视图
  Widget _buildAIResultsView(AppLocalizations l10n, state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 识别食物列表
        _buildFoodsList(l10n, state.foods),
        const SizedBox(height: AppDimensions.spacingL),

        // 总营养值
        _buildTotalMacros(l10n, state),
      ],
    );
  }

  /// 构建识别食物列表
  Widget _buildFoodsList(AppLocalizations l10n, List foods) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiDetectedFoods,
            style: AppTextStyles.callout.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          ...foods.map((food) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingXS,
                ),
                child: Text(
                  '• ${food.name} ${food.estimatedWeight}',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// 构建总营养值
  Widget _buildTotalMacros(AppLocalizations l10n, state) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalNutrition,
            style: AppTextStyles.callout.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem(
                '🔥',
                '${state.currentCalories?.toStringAsFixed(0) ?? 0}',
                'kcal',
              ),
              _buildMacroItem(
                '💪',
                '${state.currentProtein?.toStringAsFixed(0) ?? 0}',
                'g',
              ),
              _buildMacroItem(
                '🍚',
                '${state.currentCarbs?.toStringAsFixed(0) ?? 0}',
                'g',
              ),
              _buildMacroItem(
                '🥑',
                '${state.currentFat?.toStringAsFixed(0) ?? 0}',
                'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个营养指标
  Widget _buildMacroItem(String emoji, String value, String unit) {
    return Column(
      children: [
        Text(emoji, style: AppTextStyles.title3),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          value,
          style: AppTextStyles.title3.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建餐次选择器
  Widget _buildMealSelector(
    AppLocalizations l10n,
    List meals,
    state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectMeal,
          style: AppTextStyles.callout.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dividerLight, width: 1.0),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            onPressed: () => _showMealPicker(meals),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.selectedMealName ?? l10n.selectMealToAnalyze,
                  style: AppTextStyles.callout.copyWith(
                    color: state.selectedMealName != null
                        ? AppColors.primaryText
                        : AppColors.textSecondary,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 显示餐次选择器
  void _showMealPicker(List meals) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: AppColors.backgroundWhite,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: AppTextStyles.callout,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text(
                    AppLocalizations.of(context)!.ok,
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40.0,
                onSelectedItemChanged: (int index) {
                  ref
                      .read(aiFoodScannerProvider.notifier)
                      .selectMeal(meals[index].name);
                },
                children: meals.map<Widget>((meal) {
                  return Center(
                    child: Text(meal.name, style: AppTextStyles.body),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(AppLocalizations l10n, state) {
    final canSave = _canSave(state);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: canSave ? AppColors.primaryColor : AppColors.dividerLight,
          onPressed: canSave ? _handleSave : null,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Text(
            l10n.saveToMeal,
            style: AppTextStyles.buttonMedium.copyWith(
              color: canSave ? AppColors.primaryText : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// 判断是否可以保存
  bool _canSave(AIFoodAnalysisState state) {
    if (state.isAnalyzing) return false;

    if (state.recordMode == FoodRecordMode.aiScanner) {
      // AI模式：需要有AI分析结果
      return state.foods.isNotEmpty && state.currentCalories != null;
    } else {
      // Simple模式：需要选择餐次且输入营养数据
      return state.selectedMealName != null && state.currentCalories != null;
    }
  }
}
