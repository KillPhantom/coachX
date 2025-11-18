import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import '../providers/ai_food_scanner_providers.dart';

/// 餐次营养进度输入卡片
///
/// 左侧显示计划营养（只读），右侧显示本餐进度（可编辑输入框）
class MealProgressInputCard extends ConsumerWidget {
  final Meal planMeal; // 计划中的meal（包含目标值）

  const MealProgressInputCard({super.key, required this.planMeal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(aiFoodScannerProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.plannedNutrition,
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.mealProgress,
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.dividerLight),

          // 营养数据行
          _buildNutritionRow(
            context,
            ref,
            icon: l10n.calories,
            label: l10n.caloriesInput,
            planValue: planMeal.macros.calories,
            currentValue: state.currentCalories,
            onChanged: (value) {
              final calories = double.tryParse(value);
              if (calories != null) {
                ref
                    .read(aiFoodScannerProvider.notifier)
                    .updateCurrentMacros(calories: calories);
              }
            },
          ),

          _buildNutritionRow(
            context,
            ref,
            icon: l10n.protein,
            label: l10n.proteinInput,
            planValue: planMeal.macros.protein,
            currentValue: state.currentProtein,
            onChanged: (value) {
              final protein = double.tryParse(value);
              if (protein != null) {
                ref
                    .read(aiFoodScannerProvider.notifier)
                    .updateCurrentMacros(protein: protein);
              }
            },
          ),

          _buildNutritionRow(
            context,
            ref,
            icon: l10n.carbohydrates,
            label: l10n.carbsInput,
            planValue: planMeal.macros.carbs,
            currentValue: state.currentCarbs,
            onChanged: (value) {
              final carbs = double.tryParse(value);
              if (carbs != null) {
                ref
                    .read(aiFoodScannerProvider.notifier)
                    .updateCurrentMacros(carbs: carbs);
              }
            },
          ),

          _buildNutritionRow(
            context,
            ref,
            icon: l10n.fat,
            label: l10n.fatInput,
            planValue: planMeal.macros.fat,
            currentValue: state.currentFat,
            onChanged: (value) {
              final fat = double.tryParse(value);
              if (fat != null) {
                ref
                    .read(aiFoodScannerProvider.notifier)
                    .updateCurrentMacros(fat: fat);
              }
            },
            isLast: true,
          ),

          // AI检测食物备注（如果有）
          if (state.aiDetectedFoods != null &&
              state.aiDetectedFoods!.isNotEmpty)
            _buildAIFoodNotes(context, l10n, state.aiDetectedFoods!),
        ],
      ),
    );
  }

  /// 构建单行营养数据（左侧计划值 + 右侧输入框）
  Widget _buildNutritionRow(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String label,
    required double planValue,
    required double? currentValue,
    required Function(String) onChanged,
    bool isLast = false,
  }) {
    final hasAIValue = ref.watch(aiFoodScannerProvider).foods.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          child: Row(
            children: [
              // 左侧：计划值（只读）
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      icon,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${planValue.toStringAsFixed(0)} ${_getUnit(label)}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // 右侧：可编辑输入框
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      child: CupertinoTextField(
                        placeholder: '0',
                        controller: TextEditingController(
                          text: currentValue?.toStringAsFixed(0) ?? '',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,1}'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: AppDimensions.spacingS,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hasAIValue
                                ? AppColors.primaryColor
                                : AppColors.dividerLight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                    if (hasAIValue)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppDimensions.spacingS,
                        ),
                        child: Text(
                          '✓',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.dividerLight),
      ],
    );
  }

  /// 构建AI识别食物备注
  Widget _buildAIFoodNotes(
    BuildContext context,
    AppLocalizations l10n,
    String aiDetectedFoods,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: AppTextStyles.callout),
              const SizedBox(width: 8),
              Text(
                l10n.aiDetectedFoods,
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            aiDetectedFoods,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取单位
  String _getUnit(String label) {
    if (label.contains('Calorie') || label.contains('热量')) {
      return 'kcal';
    }
    return 'g';
  }
}
