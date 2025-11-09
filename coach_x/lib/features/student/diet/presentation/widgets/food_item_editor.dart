import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import '../../data/models/recognized_food.dart';

/// 单个食物的可编辑卡片
class FoodItemEditor extends StatefulWidget {
  final RecognizedFood food;
  final ValueChanged<RecognizedFood> onChanged;

  const FoodItemEditor({
    super.key,
    required this.food,
    required this.onChanged,
  });

  @override
  State<FoodItemEditor> createState() => _FoodItemEditorState();
}

class _FoodItemEditorState extends State<FoodItemEditor> {
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _caloriesController;

  @override
  void initState() {
    super.initState();
    _proteinController = TextEditingController(
      text: widget.food.macros.protein.toStringAsFixed(1),
    );
    _carbsController = TextEditingController(
      text: widget.food.macros.carbs.toStringAsFixed(1),
    );
    _fatController = TextEditingController(
      text: widget.food.macros.fat.toStringAsFixed(1),
    );
    _caloriesController = TextEditingController(
      text: widget.food.macros.calories.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final calories = double.tryParse(_caloriesController.text) ?? 0.0;

    final updatedFood = widget.food.copyWith(
      macros: Macros(
        protein: protein,
        carbs: carbs,
        fat: fat,
        calories: calories,
      ),
    );

    widget.onChanged(updatedFood);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.dividerLight, width: 1.0),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 食物名称和重量
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.food.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  widget.food.estimatedWeight,
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // 营养数据输入网格
          Row(
            children: [
              Expanded(
                child: _buildMacroInput(
                  label: l10n.protein,
                  controller: _proteinController,
                  unit: 'g',
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildMacroInput(
                  label: l10n.carbs,
                  controller: _carbsController,
                  unit: 'g',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingS),

          Row(
            children: [
              Expanded(
                child: _buildMacroInput(
                  label: l10n.fat,
                  controller: _fatController,
                  unit: 'g',
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildMacroInput(
                  label: '卡路里',
                  controller: _caloriesController,
                  unit: 'kcal',
                  color: const Color(0xFF10B981),
                  isInteger: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput({
    required String label,
    required TextEditingController controller,
    required String unit,
    required Color color,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4.0),
        CupertinoTextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          textAlign: TextAlign.center,
          style: AppTextStyles.callout.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: color.withOpacity(0.3), width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingS,
          ),
          suffix: Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingS),
            child: Text(
              unit,
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          onChanged: (_) => _notifyChange(),
        ),
      ],
    );
  }
}
