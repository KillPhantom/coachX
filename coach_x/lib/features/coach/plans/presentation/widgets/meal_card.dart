import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 餐次卡片组件
class MealCard extends StatefulWidget {
  final Meal meal;
  final int index;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onNoteChanged;
  final VoidCallback? onAddFoodItem;
  final Widget? foodItemsWidget;

  // Review Mode 相关
  final DietPlanChange? activeSuggestion;
  final bool isHighlighted;

  const MealCard({
    super.key,
    required this.meal,
    required this.index,
    this.isExpanded = false,
    this.onTap,
    this.onDelete,
    this.onNameChanged,
    this.onNoteChanged,
    this.onAddFoodItem,
    this.foodItemsWidget,
    this.activeSuggestion,
    this.isHighlighted = false,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _noteController = TextEditingController(text: widget.meal.note);

    // 脉冲动画控制器
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = controller;

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    // 如果高亮，启动脉冲动画
    if (widget.isHighlighted) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.name != widget.meal.name &&
        _nameController.text != widget.meal.name) {
      _nameController.text = widget.meal.name;
    }
    if (oldWidget.meal.note != widget.meal.note &&
        _noteController.text != widget.meal.note) {
      _noteController.text = widget.meal.note;
    }

    // 控制脉冲动画的启动和停止
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _pulseController?.repeat(reverse: true);
    } else if (!widget.isHighlighted && oldWidget.isHighlighted) {
      _pulseController?.stop();
      _pulseController?.reset();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.meal.macros;
    final isExpanded = widget.isExpanded;

    Widget cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? CupertinoColors.systemBackground.resolveFrom(context)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.isHighlighted
            ? Border.all(color: AppColors.primary, width: 2.5)
            : null,
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.18),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  // Drag Handle
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        CupertinoIcons.bars,
                        color: CupertinoColors.systemGrey3,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Meal Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal Name and Kcal Badge Row
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.meal.name.isEmpty
                                    ? '未命名餐次'
                                    : widget.meal.name,
                                style: AppTextStyles.caption1.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: widget.meal.name.isEmpty
                                      ? CupertinoColors.placeholderText
                                            .resolveFrom(context)
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Kcal Badge (Inline next to name)
                            _buildMacroBadge(
                              context,
                              '${macros.calories.toStringAsFixed(0)} Kcal',
                              AppColors.secondaryPurple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Macro Summary Badges (Protein, Carbs, Fat)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildMacroBadge(
                              context,
                              '${macros.protein.toStringAsFixed(0)}g 蛋白',
                              AppColors.secondaryBlue,
                            ),
                            _buildMacroBadge(
                              context,
                              '${macros.carbs.toStringAsFixed(0)}g 碳水',
                              AppColors.secondaryOrange,
                            ),
                            _buildMacroBadge(
                              context,
                              '${macros.fat.toStringAsFixed(0)}g 脂肪',
                              AppColors.secondaryRed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Item Count & Expand Icon
                  Row(
                    children: [
                      Text(
                        '${widget.meal.items.length} Items',
                        style: AppTextStyles.caption1.copyWith(
                          color: CupertinoColors.secondaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        color: CupertinoColors.systemGrey3,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            Container(height: 1, color: CupertinoColors.systemGrey6),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Name Input
                  Text(
                    '餐次名称',
                    style: AppTextStyles.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: '例如：早餐、午餐、晚餐',
                    onChanged: widget.onNameChanged,
                    style: AppTextStyles.bodyMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey5),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note Input
                  Text(
                    '备注',
                    style: AppTextStyles.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _noteController,
                    placeholder: '例如：训练前、训练后',
                    onChanged: widget.onNoteChanged,
                    minLines: 1,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Food Items List
                  if (widget.foodItemsWidget != null)
                    widget.foodItemsWidget!
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '暂无食物条目',
                          style: AppTextStyles.caption1.copyWith(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Actions Row
                  Row(
                    children: [
                      // Add Food Button
                      if (widget.onAddFoodItem != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: widget.onAddFoodItem,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.add,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '添加食物',
                                  style: AppTextStyles.caption1.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Delete Meal Button
                      if (widget.onDelete != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.delete,
                              color: CupertinoColors.systemRed,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // Apply pulse animation if highlighted
    if (widget.isHighlighted && _pulseAnimation != null) {
      cardWidget = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnimation!.value, child: child);
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildMacroBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12), // Pill shape
      ),
      child: Text(
        text,
        style: AppTextStyles.caption2.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
