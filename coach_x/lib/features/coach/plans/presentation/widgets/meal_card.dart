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

    Widget cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? CupertinoColors.systemBackground.resolveFrom(context)
            : CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: widget.isHighlighted
            ? Border.all(color: AppColors.primary, width: 2.5)
            : (widget.isExpanded
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null),
        boxShadow: widget.isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // 餐次信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 餐次名称
                        Text(
                          widget.meal.name.isEmpty ? '未命名餐次' : widget.meal.name,
                          style: AppTextStyles.footnote.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.meal.name.isEmpty
                                ? CupertinoColors.placeholderText.resolveFrom(
                                    context,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // 营养汇总
                        Row(
                          children: [
                            _buildMacroChip(
                              context,
                              '${macros.protein.toStringAsFixed(0)}g 蛋白',
                              CupertinoIcons.bolt_fill,
                              AppColors.secondaryBlue,
                            ),
                            const SizedBox(width: 6),
                            _buildMacroChip(
                              context,
                              '${macros.carbs.toStringAsFixed(0)}g 碳水',
                              CupertinoIcons.flame_fill,
                              AppColors.secondaryOrange,
                            ),
                            const SizedBox(width: 6),
                            _buildMacroChip(
                              context,
                              '${macros.fat.toStringAsFixed(0)}g 脂肪',
                              CupertinoIcons.drop_fill,
                              AppColors.secondaryRed,
                            ),
                            const SizedBox(width: 6),
                            _buildMacroChip(
                              context,
                              '${macros.calories.toStringAsFixed(0)} 卡路里',
                              CupertinoIcons.drop_fill,
                              AppColors.secondaryPurple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 删除按钮
                  if (widget.onDelete != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: widget.onDelete,
                      child: Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed.resolveFrom(context),
                        size: 18,
                      ),
                    ),

                  // 展开图标
                  Icon(
                    widget.isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (widget.isExpanded) ...[
            Container(
              height: 1,
              color: CupertinoColors.separator.resolveFrom(context),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 餐次名称输入
                  Text(
                    '餐次名称',
                    style: AppTextStyles.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: '例如：早餐、午餐、晚餐',
                    onChanged: widget.onNameChanged,
                    style: AppTextStyles.caption1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 备注输入
                  Text(
                    '备注',
                    style: AppTextStyles.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _noteController,
                    placeholder: '例如：训练前、训练后',
                    onChanged: widget.onNoteChanged,
                    minLines: 1,
                    maxLines: 3,
                    style: AppTextStyles.caption1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 食物条目标题 & 添加按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '食物条目',
                        style: AppTextStyles.callout.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.onAddFoodItem != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: widget.onAddFoodItem,
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.add_circled_solid,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '添加',
                                style: AppTextStyles.callout.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 食物条目列表
                  if (widget.foodItemsWidget != null)
                    widget.foodItemsWidget!
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '暂无食物条目，点击"添加"按钮添加',
                        style: AppTextStyles.caption1.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // 应用脉冲动画（如果高亮）
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

  Widget _buildMacroChip(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 2),
          Text(text, style: AppTextStyles.tabLabel.copyWith(color: color)),
        ],
      ),
    );
  }
}
