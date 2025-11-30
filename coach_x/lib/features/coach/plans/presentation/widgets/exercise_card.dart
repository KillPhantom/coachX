import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ReorderableDragStartListener, Curves, CurvedAnimation, Tween;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/set_row.dart';
import 'package:coach_x/features/student/training/presentation/providers/exercise_template_providers.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/widgets/create_exercise_sheet.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 动作卡片组件
class ExerciseCard extends ConsumerStatefulWidget {
  final Exercise exercise;
  final int index;
  final bool initiallyExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddSet;
  final Widget? setsWidget;

  // Review Mode 相关
  final PlanChange? activeSuggestion; // 当前激活的建议
  final bool isHighlighted; // 是否被高亮
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onRejectSuggestion;
  final VoidCallback? onAcceptAll;
  final VoidCallback? onRejectAll;
  final String? suggestionProgress;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    this.initiallyExpanded = false,
    this.onTap,
    this.onDelete,
    this.onAddSet,
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
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard>
    with SingleTickerProviderStateMixin {
  bool? _isExpanded;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

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
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

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
    _pulseController?.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !(_isExpanded ?? widget.initiallyExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = _isExpanded ?? widget.initiallyExpanded;
    
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
                // Highlighted: Primary color glow effect
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
                // Highlighted: Enhanced tight shadow
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                // Highlighted: Enhanced soft shadow
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                // Normal: Tight shadow for definition
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                // Normal: Soft shadow for depth
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.18),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: _toggleExpansion,
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
                  
                  // Exercise Number
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.primaryAction,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Exercise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        _buildExerciseNameDisplay(context),
                        const SizedBox(height: 4),

                      ],
                    ),
                  ),

                  // Sets Count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.exercise.totalSets} Sets',
                      style: AppTextStyles.caption1.copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),

                  // Expand Icon
                  Icon(
                    isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: CupertinoColors.systemGrey3,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            Container(
              height: 1,
              color: CupertinoColors.systemGrey6,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sets List
                  if (widget.isHighlighted && widget.activeSuggestion != null)
                    _buildReviewModeSets(widget.activeSuggestion!)
                  else if (widget.setsWidget != null)
                    widget.setsWidget!,

                  const SizedBox(height: 12),

                  // Actions Row
                  Row(
                    children: [
                      // Add Set Button
                      if (widget.onAddSet != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: widget.onAddSet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.add,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.addSet,
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

                      // Guidance Button
                      if (widget.exercise.exerciseTemplateId != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => _showGuidanceSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CupertinoIcons.book,
                              color: CupertinoColors.secondaryLabel,
                              size: 16,
                            ),
                          ),
                        ),
                        
                      const SizedBox(width: 12),
                      
                      // Delete Button
                      if (widget.onDelete != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CupertinoIcons.delete,
                              color: CupertinoColors.systemRed,
                              size: 16,
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


  /// 构建动作名称显示（从模板获取，支持 Review Mode 的 before/after 对比）
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

    // 默认显示：从模板获取名称
    final templateId = widget.exercise.exerciseTemplateId;
    final l10n = AppLocalizations.of(context)!;

    if (templateId == null || templateId.isEmpty) {
      return Text(
        l10n.noTemplateLinked,
        style: AppTextStyles.caption1.copyWith(
          fontWeight: FontWeight.w600,
          color: CupertinoColors.placeholderText.resolveFrom(context),
        ),
      );
    }

    final templateAsync = ref.watch(exerciseTemplateProvider(templateId));

    return templateAsync.when(
      data: (template) {
        final name = template?.name ?? l10n.unknownExercise;
        return Row(
          children: [
            Text(
              name,
              style: AppTextStyles.caption1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            // 显示标签
            if (template?.tags.isNotEmpty ?? false) ...[
              const SizedBox(width: 4),
              Wrap(
                spacing: 2,
                children: template!.tags.take(2).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.tabLabel.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
      loading: () => const CupertinoActivityIndicator(),
      error: (_, __) => Text(
        l10n.loadFailed,
        style: AppTextStyles.caption1.copyWith(
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemRed.resolveFrom(context),
        ),
      ),
    );
  }

  /// 显示指导编辑 Sheet
  Future<void> _showGuidanceSheet(BuildContext context) async {
    final templateId = widget.exercise.exerciseTemplateId;
    if (templateId == null || templateId.isEmpty) return;

    // 先加载模板 (使用 future 确保等待加载完成)
    final template = await ref.read(exerciseTemplateProvider(templateId).future);

    if (!mounted) return;

    // 打开编辑 Sheet
    await CreateExerciseSheet.show(
      context,
      template: template,
    );
  }
}
