import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/set_row.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/enums/exercise_type.dart';

/// 动作卡片组件
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final int index;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onNoteChanged;
  final VoidCallback? onAddSet;
  final VoidCallback? onUploadGuide;
  final Widget? setsWidget;

  // Review Mode 相关
  final PlanChange? activeSuggestion;          // 当前激活的建议
  final bool isHighlighted;                    // 是否被高亮
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onRejectSuggestion;
  final VoidCallback? onAcceptAll;
  final VoidCallback? onRejectAll;
  final String? suggestionProgress;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    this.isExpanded = false,
    this.onTap,
    this.onDelete,
    this.onNameChanged,
    this.onNoteChanged,
    this.onAddSet,
    this.onUploadGuide,
    this.setsWidget,
    this.activeSuggestion,
    this.isHighlighted = false,
    this.onAcceptSuggestion,
    this.onRejectSuggestion,
    this.onAcceptAll,
    this.onRejectAll,
    this.suggestionProgress,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _noteController = TextEditingController(text: widget.exercise.note);

    // 脉冲动画控制器
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = controller;

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    // 如果高亮，启动脉冲动画
    if (widget.isHighlighted) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.name != widget.exercise.name &&
        _nameController.text != widget.exercise.name) {
      _nameController.text = widget.exercise.name;
    }
    if (oldWidget.exercise.note != widget.exercise.note &&
        _noteController.text != widget.exercise.note) {
      _noteController.text = widget.exercise.note;
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
    Widget cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 5),
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
              padding: const EdgeInsets.all(7),
              child: Row(
                children: [
                  // Exercise Number
                  Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Exercise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        _buildExerciseNameDisplay(context),
                        const SizedBox(height: 1),
                        // Type & Sets
                        Row(
                          children: [
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: widget.exercise.type == ExerciseType.strength
                                    ? CupertinoColors.systemBlue.withOpacity(0.15)
                                    : CupertinoColors.systemRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                widget.exercise.type.displayName,
                                style: AppTextStyles.tabLabel.copyWith(
                                  color: widget.exercise.type == ExerciseType.strength
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.systemRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Sets Count
                            Text(
                              '${widget.exercise.totalSets} 组',
                              style: AppTextStyles.caption2.copyWith(
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete Button
                  if (widget.onDelete != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: widget.onDelete,
                      child: Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed.resolveFrom(context),
                        size: 14,
                      ),
                    ),

                  // Expand Icon
                  Icon(
                    widget.isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    size: 14,
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
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Name Input
                  Text(
                    '动作名称',
                    style: AppTextStyles.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    style: AppTextStyles.caption1,
                    placeholder: '例如：深蹲、卧推',
                    controller: _nameController,
                    onChanged: widget.onNameChanged,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Exercise Note Input
                  Text(
                    '备注',
                    style: AppTextStyles.caption1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 备注对比显示（Review Mode）
                  _buildNoteDisplay(context),

                  const SizedBox(height: 7),

                  // Sets Title & Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '训练组',
                        style: AppTextStyles.caption1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.onAddSet != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: widget.onAddSet,
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.add_circled_solid,
                                color: AppColors.primary,
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '添加组',
                                style: AppTextStyles.caption1.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Sets List
                  if (widget.isHighlighted && widget.activeSuggestion != null)
                    _buildReviewModeSets(widget.activeSuggestion!)
                  else if (widget.setsWidget != null)
                    widget.setsWidget!,

                  const SizedBox(height: 7),

                  // Upload Guide Placeholder
                  if (widget.onUploadGuide != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onUploadGuide,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5.resolveFrom(context),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: CupertinoColors.separator.resolveFrom(context),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.cloud_upload,
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              size: 8,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '上传指导图片/视频（预留）',
                              style: AppTextStyles.caption1.copyWith(
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
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
          return Transform.scale(
            scale: _pulseAnimation!.value,
            child: child,
          );
        },
        child: cardWidget,
      );
    }

    // 移除了 SuggestionOverlay，因为 Review Mode 已经有主要的修改详情卡片
    // 显示在 exercise_card 上方的小卡片会遮挡内容

    return cardWidget;
  }

  /// 构建 Review Mode 下的 Sets 显示（before/after 对比）
  Widget _buildReviewModeSets(PlanChange suggestion) {
    List? beforeSets;
    List? afterSets;

    // modifyExerciseSets 类型：直接使用 before/after 数组
    if (suggestion.type == ChangeType.modifyExerciseSets) {
      beforeSets = suggestion.before as List?;
      afterSets = suggestion.after as List?;
    }
    // modifyExercise 类型：从对象中提取 sets 字段
    else if (suggestion.type == ChangeType.modifyExercise) {
      if (suggestion.before is Map && suggestion.after is Map) {
        beforeSets = (suggestion.before as Map)['sets'] as List?;
        afterSets = (suggestion.after as Map)['sets'] as List?;
      }
    }
    // 其他类型：使用正常的 setsWidget
    else {
      return widget.setsWidget ?? const SizedBox.shrink();
    }

    if (beforeSets == null || afterSets == null) {
      return widget.setsWidget ?? const SizedBox.shrink();
    }

    final maxLength = max(beforeSets.length, afterSets.length);
    List<Widget> setRows = [];

    for (int i = 0; i < maxLength; i++) {
      final hasBefore = i < beforeSets.length;
      final hasAfter = i < afterSets.length;

      SetChangeType changeType;
      TrainingSet? beforeSet;
      TrainingSet currentSet;

      if (hasBefore && hasAfter) {
        // 修改
        changeType = SetChangeType.modified;
        final beforeData = beforeSets[i] as Map;
        final afterData = afterSets[i] as Map;

        beforeSet = TrainingSet(
          reps: beforeData['reps']?.toString() ?? '10',
          weight: beforeData['weight']?.toString() ?? '0kg',
        );
        currentSet = TrainingSet(
          reps: afterData['reps']?.toString() ?? '10',
          weight: afterData['weight']?.toString() ?? '0kg',
        );
      } else if (!hasBefore && hasAfter) {
        // 新增
        changeType = SetChangeType.added;
        final afterData = afterSets[i] as Map;
        currentSet = TrainingSet(
          reps: afterData['reps']?.toString() ?? '10',
          weight: afterData['weight']?.toString() ?? '0kg',
        );
      } else {
        // 删除
        changeType = SetChangeType.deleted;
        final beforeData = beforeSets[i] as Map;
        beforeSet = TrainingSet(
          reps: beforeData['reps']?.toString() ?? '10',
          weight: beforeData['weight']?.toString() ?? '0kg',
        );
        currentSet = beforeSet; // 占位
      }

      setRows.add(
        SetRow(
          set: currentSet,
          index: i,
          beforeSet: beforeSet,
          changeType: changeType,
          isInReviewMode: true,
          onDelete: null, // Review Mode 下禁用删除
        ),
      );
    }

    return Column(children: setRows);
  }

  /// 构建备注显示（支持 Review Mode 的 before/after 对比）
  Widget _buildNoteDisplay(BuildContext context) {
    // 判断是否是 Review Mode 下的 modifyExercise 类型
    if (widget.isHighlighted &&
        widget.activeSuggestion != null &&
        widget.activeSuggestion!.type == ChangeType.modifyExercise) {
      final before = widget.activeSuggestion!.before;
      final after = widget.activeSuggestion!.after;

      // 提取 before/after 备注（仅支持对象格式）
      if (before is Map && after is Map) {
        final beforeNote = before['note'] as String?;
        final afterNote = after['note'] as String?;

        // 如果备注有变化，显示对比
        if (beforeNote != null && afterNote != null && beforeNote != afterNote) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Before (红色删除线)
                Text(
                  beforeNote,
                  style: AppTextStyles.caption1.copyWith(
                    color: CupertinoColors.systemRed.resolveFrom(context),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                // After (绿色)
                Text(
                  afterNote,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    // 默认显示：正常输入框
    return CupertinoTextField(
      placeholder: '例如：注意膝盖不要超过脚尖',
      controller: _noteController,
      onChanged: widget.onNoteChanged,
      minLines: 1,
      maxLines: null,
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 5,
      ),
      style: AppTextStyles.caption1,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// 构建动作名称显示（支持 Review Mode 的 before/after 对比）
  Widget _buildExerciseNameDisplay(BuildContext context) {
    // 判断是否是 Review Mode 下的 modifyExercise 类型
    if (widget.isHighlighted &&
        widget.activeSuggestion != null &&
        widget.activeSuggestion!.type == ChangeType.modifyExercise) {
      final before = widget.activeSuggestion!.before;
      final after = widget.activeSuggestion!.after;

      // 提取 before/after 名称（支持字符串或对象格式）
      String? beforeName;
      String? afterName;

      if (before is String) {
        beforeName = before;
      } else if (before is Map && before['name'] != null) {
        beforeName = before['name'] as String;
      }

      if (after is String) {
        afterName = after;
      } else if (after is Map && after['name'] != null) {
        afterName = after['name'] as String;
      }

      // 如果成功提取到名称，显示对比
      if (beforeName != null && afterName != null) {
        return Row(
          children: [
            // Before (红色删除线)
            Text(
              beforeName,
              style: AppTextStyles.caption1.copyWith(
                color: CupertinoColors.systemRed.resolveFrom(context),
                decoration: TextDecoration.lineThrough,
              ),
            ),

            // 箭头
            Text(
              ' → ',
              style: AppTextStyles.caption1.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),

            // After (绿色加粗)
            Text(
              afterName,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }
    }

    // 默认显示：普通名称
    return Text(
      widget.exercise.name.isEmpty ? '未命名动作' : widget.exercise.name,
      style: AppTextStyles.caption1.copyWith(
        fontWeight: FontWeight.w600,
        color: widget.exercise.name.isEmpty
            ? CupertinoColors.placeholderText.resolveFrom(context)
            : null,
      ),
    );
  }
}

