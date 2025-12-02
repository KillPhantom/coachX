import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// 饮食日编辑面板
class DietDayEditor extends StatelessWidget {
  final VoidCallback? onAddMeal;
  final Widget? mealsWidget;
  final Macros? totalMacros;
  final ValueChanged<double>? onProteinChanged;
  final ValueChanged<double>? onCarbsChanged;
  final ValueChanged<double>? onFatChanged;

  const DietDayEditor({
    super.key,
    this.onAddMeal,
    this.mealsWidget,
    this.totalMacros,
    this.onProteinChanged,
    this.onCarbsChanged,
    this.onFatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Total Macros Summary
          if (totalMacros != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                border: Border.all(
                  color: AppColors.borderColor,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Title - Kcal
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar_circle_fill,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Total',
                        style: AppTextStyles.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Calories Badge (Read-only, Calculated)
                      _buildMacroBadge(
                        context,
                        '${(totalMacros!.protein * 4 + totalMacros!.carbs * 4 + totalMacros!.fat * 9).toStringAsFixed(0)} Kcal',
                        AppColors.secondaryPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Macros Row: Protein, Carbs, Fat
                  Row(
                    children: [
                      Expanded(
                        child: _EditableMacroBadge(
                          value: totalMacros!.protein,
                          label: '蛋白质',
                          color: AppColors.secondaryBlue,
                          onChanged: onProteinChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EditableMacroBadge(
                          value: totalMacros!.carbs,
                          label: '碳水',
                          color: AppColors.secondaryOrange,
                          onChanged: onCarbsChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EditableMacroBadge(
                          value: totalMacros!.fat,
                          label: '脂肪',
                          color: AppColors.secondaryRed,
                          onChanged: onFatChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Meals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '餐次列表 (Meals)',
                style: AppTextStyles.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onAddMeal != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onAddMeal,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '添加',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Meals List
          if (mealsWidget != null) mealsWidget!,
        ],
      ),
    );
  }

  Widget _buildMacroBadge(BuildContext context, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: AppTextStyles.caption1.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _EditableMacroBadge extends StatefulWidget {
  final double value;
  final String label;
  final Color color;
  final ValueChanged<double>? onChanged;

  const _EditableMacroBadge({
    required this.value,
    required this.label,
    required this.color,
    this.onChanged,
  });

  @override
  State<_EditableMacroBadge> createState() => _EditableMacroBadgeState();
}

class _EditableMacroBadgeState extends State<_EditableMacroBadge> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableMacroBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        widget.value != double.tryParse(_controller.text)) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // On blur, ensure the text matches the current value format
      _controller.text = widget.value.toStringAsFixed(1);
    } else {
      // On focus, select all text for easy replacement
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoTextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: null,
            style: AppTextStyles.caption1.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            onChanged: (value) {
              final newValue = double.tryParse(value);
              if (newValue != null && widget.onChanged != null) {
                widget.onChanged!(newValue);
              }
            },
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: AppTextStyles.caption2.copyWith(
              color: CupertinoColors.secondaryLabel,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
