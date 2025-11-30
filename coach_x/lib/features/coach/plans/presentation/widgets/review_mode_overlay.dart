import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';

/// Review Mode 全页面 Overlay
///
/// 显示修改审查界面，包含：
/// - 半透明遮罩
/// - 当前修改详情卡片
/// - 进度指示器
/// - 控制按钮（接受/拒绝/全部接受）
class ReviewModeOverlay extends ConsumerWidget {
  final int? focusedDayIndex;
  final int? focusedExerciseIndex;

  const ReviewModeOverlay({
    super.key,
    this.focusedDayIndex,
    this.focusedExerciseIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(suggestionReviewNotifierProvider);

    // 只有当 reviewState 完全为 null 时才不显示
    if (reviewState == null) {
      return const SizedBox.shrink();
    }

    final currentChange = reviewState.currentChange;
    final progressText = reviewState.progressText;
    final acceptedCount = reviewState.acceptedCount;
    final rejectedCount = reviewState.rejectedCount;
    final hasNext = reviewState.hasNext;
    final isShowingAll = reviewState.isShowingAllChanges;

    // 如果没有当前修改（已完成），不显示
    if (currentChange == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {}, // 阻止点击穿透
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          // 顶部紧凑区域（可滚动，占据剩余空间）
          Expanded(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: isShowingAll
                          ? _buildAllChangesView(context, ref, reviewState)
                          : _buildCompactHeader(
                              context,
                              ref,
                              progressText,
                              acceptedCount,
                              rejectedCount,
                              currentChange,
                              reviewState,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 控制按钮（固定底部，不参与滚动）
          SafeArea(
            top: false,
            child: _buildControlButtons(context, ref, hasNext, isShowingAll),
          ),
        ],
      ),
    );
  }

  /// 构建紧凑的顶部区域（进度 + 修改详情）
  Widget _buildCompactHeader(
    BuildContext context,
    WidgetRef ref,
    String progress,
    int accepted,
    int rejected,
    PlanChange change,
    SuggestionReviewState reviewState,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：进度 + 统计 + 查看全部 + 退出
          Row(
            children: [
              // 进度
              Text(
                progress,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),

              // 统计
              _buildStatChip(context, '已接受', accepted, AppColors.success),
              const SizedBox(width: 6),
              _buildStatChip(
                context,
                '已拒绝',
                rejected,
                CupertinoColors.systemRed.resolveFrom(context),
              ),

              const Spacer(),

              // 查看全部按钮
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: () => ref
                    .read(suggestionReviewNotifierProvider.notifier)
                    .toggleShowAllChanges(),
                child: Text(
                  '查看全部',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // 退出按钮
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _cancelReview(context, ref),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),

          Divider(
            height: 16,
            color: CupertinoColors.separator.resolveFrom(context),
          ),

          // 第二行：修改类型 + 简短描述
          Row(
            children: [
              // 位置标签 (Day{x}-{ExerciseName})
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getChangeLocationLabel(change, reviewState),
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 简短描述
              Expanded(
                child: Text(
                  _buildCompactDescription(change),
                  style: AppTextStyles.footnote.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 第三行：理由
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.lightbulb,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  change.reason,
                  style: AppTextStyles.caption1.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 第四行：如果是 add_day 类型，显示训练日详情
          if (change.type == ChangeType.addDay)
            _buildAddDayDetails(context, change),

          // 第四行：如果是 add_exercise 类型，显示动作详情
          if (change.type == ChangeType.addExercise)
            _buildAddExerciseDetails(context, change),
        ],
      ),
    );
  }

  /// 构建 add_exercise 类型的动作详情
  Widget _buildAddExerciseDetails(BuildContext context, PlanChange change) {
    // 解析 after 字段中的动作数据
    final exerciseData = change.after;

    if (exerciseData == null || exerciseData is! Map) {
      return const SizedBox.shrink();
    }

    final name = exerciseData['name'] as String? ?? '新动作';
    final sets = exerciseData['sets'] as List? ?? [];
    final note = exerciseData['note'] as String?;

    if (sets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        const SizedBox(height: 12),

        // 动作详情标题
        Row(
          children: [
            Icon(CupertinoIcons.flame, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '动作详情：$name',
                style: AppTextStyles.footnote.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 备注（如果有）
        if (note != null && note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    style: AppTextStyles.caption1.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 训练组列表
        Column(
          children: sets.asMap().entries.map((entry) {
            final index = entry.key;
            final setData = entry.value as Map;
            final reps = setData['reps'] as String? ?? '';
            final weight = setData['weight'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 组号
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.caption2.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 次数
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '次数',
                          style: AppTextStyles.tabLabel.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reps,
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 重量
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '重量',
                          style: AppTextStyles.tabLabel.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weight,
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 4),

        // 统计信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '共 ${sets.length} 组',
            style: AppTextStyles.caption2.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建 add_day 类型的训练日详情
  Widget _buildAddDayDetails(BuildContext context, PlanChange change) {
    // 解析 after 字段中的训练日数据
    final dayData = change.after;

    if (dayData == null || dayData is! Map) {
      return const SizedBox.shrink();
    }

    final dayName = dayData['name'] as String? ?? '新训练日';
    final exercises = dayData['exercises'] as List? ?? [];

    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Divider(
          height: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        const SizedBox(height: 12),

        // 训练日详情标题
        Row(
          children: [
            Icon(
              CupertinoIcons.list_bullet,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '训练日详情：$dayName',
                style: AppTextStyles.footnote.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Exercises 列表 - 使用 ConstrainedBox + SingleChildScrollView 限制高度并支持滚动
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exerciseData = entry.value as Map;
                return _buildExerciseItem(context, index + 1, exerciseData);
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // 统计信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '共 ${exercises.length} 个动作',
            style: AppTextStyles.caption2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个动作项
  Widget _buildExerciseItem(BuildContext context, int index, Map exerciseData) {
    final name = exerciseData['name'] as String? ?? '未命名动作';
    final sets = exerciseData['sets'] as List? ?? [];
    final note = exerciseData['note'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 序号
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: AppTextStyles.caption2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 动作信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 动作名称
                Text(
                  name,
                  style: AppTextStyles.caption1.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                // 组数信息
                Text(
                  '${sets.length}组 ${_formatSetsPreview(sets)}',
                  style: AppTextStyles.caption2.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),

                // 备注
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: AppTextStyles.caption2.copyWith(
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化 sets 预览信息
  String _formatSetsPreview(List sets) {
    if (sets.isEmpty) return '';

    try {
      final firstSet = sets.first as Map;
      final reps = firstSet['reps'] as String? ?? '';
      final weight = firstSet['weight'] as String? ?? '';

      if (reps.isNotEmpty && weight.isNotEmpty) {
        return '($reps次 × $weight)';
      } else if (reps.isNotEmpty) {
        return '($reps次)';
      }
    } catch (e) {
      // 解析失败，返回空字符串
    }

    return '';
  }

  /// 构建简化的修改描述（动作名 - before → after）
  String _buildCompactDescription(PlanChange change) {
    // add_day 类型：显示训练日名称和动作数量
    if (change.type == ChangeType.addDay) {
      final dayData = change.after;
      if (dayData is Map) {
        final dayName = dayData['name'] as String? ?? '新训练日';
        final exercises = dayData['exercises'] as List? ?? [];
        return '$dayName (${exercises.length}个动作)';
      }
      return '添加新训练日';
    }

    // add_exercise 类型：显示动作名称
    if (change.type == ChangeType.addExercise) {
      final exerciseData = change.after;
      if (exerciseData is Map) {
        final name = exerciseData['name'] as String? ?? '新动作';
        return '添加动作: $name';
      } else if (exerciseData is String) {
        return '添加动作: $exerciseData';
      }
      return '添加新动作';
    }

    // modify_exercise 类型：显示动作名称对比
    if (change.type == ChangeType.modifyExercise) {
      String? beforeName;
      String? afterName;

      if (change.before is String) {
        beforeName = change.before as String;
      } else if (change.before is Map) {
        beforeName = (change.before as Map)['name'] as String?;
      }

      if (change.after is String) {
        afterName = change.after as String;
      } else if (change.after is Map) {
        afterName = (change.after as Map)['name'] as String?;
      }

      if (beforeName != null && afterName != null) {
        return '$beforeName → $afterName';
      }
      return '修改动作';
    }

    // modify_exercise_sets 类型
    if (change.type == ChangeType.modifyExerciseSets) {
      final before = change.before;
      final after = change.after;

      if (before is List && after is List) {
        if (before.length != after.length) {
          return '${before.length}组 → ${after.length}组';
        } else {
          return '调整训练组参数';
        }
      }
    }

    // 其他类型：使用字符串 before/after
    if (change.before != null && change.after != null) {
      return '${change.before} → ${change.after}';
    } else if (change.after != null) {
      // 如果 after 是 Map 或 List，只显示描述
      if (change.after is Map || change.after is List) {
        return change.description;
      }
      return change.after.toString();
    } else {
      // 回退到完整描述
      return change.description;
    }
  }

  /// 构建全部改动视图
  Widget _buildAllChangesView(
    BuildContext context,
    WidgetRef ref,
    SuggestionReviewState state,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部：进度 + 统计 + 收起 + 退出
          Row(
            children: [
              Text(
                state.progressText,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                context,
                '已接受',
                state.acceptedCount,
                AppColors.success,
              ),
              const SizedBox(width: 6),
              _buildStatChip(
                context,
                '已拒绝',
                state.rejectedCount,
                CupertinoColors.systemRed.resolveFrom(context),
              ),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                onPressed: () => ref
                    .read(suggestionReviewNotifierProvider.notifier)
                    .toggleShowAllChanges(),
                child: Text(
                  '收起',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _cancelReview(context, ref),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 14,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),

          Divider(
            height: 16,
            color: CupertinoColors.separator.resolveFrom(context),
          ),

          // 修改摘要
          if (state.allChanges.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '共 ${state.allChanges.length} 处修改',
                style: AppTextStyles.footnote.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // 全部改动列表（可滚动）
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.allChanges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final change = state.allChanges[index];
                final isAccepted = state.acceptedIds.contains(change.id);
                final isRejected = state.rejectedIds.contains(change.id);
                final isCurrent = index == state.currentIndex;

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary.withOpacity(0.1)
                        : CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      // 序号
                      Text(
                        '${index + 1}.',
                        style: AppTextStyles.caption1.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 位置标签 (Day{x}-{ExerciseName})
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getChangeLocationLabel(change, state),
                          style: AppTextStyles.caption2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 描述
                      Expanded(
                        child: Text(
                          _buildCompactDescription(change),
                          style: AppTextStyles.caption1.copyWith(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 状态图标
                      if (isAccepted)
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 16,
                          color: AppColors.success,
                        )
                      else if (isRejected)
                        Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 16,
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计 Chip
  Widget _buildStatChip(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption2.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: AppTextStyles.caption2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建控制按钮（两个按钮：拒绝 + 接受）
  Widget _buildControlButtons(
    BuildContext context,
    WidgetRef ref,
    bool hasNext,
    bool isShowingAll,
  ) {
    // 根据展开状态决定右侧按钮的文本和行为
    final String acceptText;
    final VoidCallback acceptAction;

    if (isShowingAll) {
      // 展开时：显示"全部接受"
      acceptText = '全部接受';
      acceptAction = () => _acceptAll(context, ref);
    } else {
      // 未展开时：显示"接受并继续"或"接受"
      acceptText = hasNext ? '接受并继续' : '接受';
      acceptAction = () => _acceptCurrent(ref);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // 拒绝按钮
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
              onPressed: () => _rejectCurrent(ref),
              child: Text(
                '拒绝',
                style: AppTextStyles.body.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 接受按钮（绿色）
          Expanded(
            flex: 2,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppColors.success,
              borderRadius: BorderRadius.circular(16),
              onPressed: acceptAction,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    acceptText,
                    style: AppTextStyles.body.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 接受当前修改
  void _acceptCurrent(WidgetRef ref) {
    ref.read(suggestionReviewNotifierProvider.notifier).acceptCurrent();
  }

  /// 拒绝当前修改
  void _rejectCurrent(WidgetRef ref) {
    ref.read(suggestionReviewNotifierProvider.notifier).rejectCurrent();
  }

  /// 接受所有剩余修改
  void _acceptAll(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('接受所有剩余修改'),
        content: const Text('确定要接受所有剩余的修改建议吗？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: AppTextStyles.body),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(suggestionReviewNotifierProvider.notifier).acceptAll();
              _finishReview(context, ref);
            },
            child: const Text('确定', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  /// 取消审查
  void _cancelReview(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('取消审查'),
        content: const Text('确定要取消审查吗？已接受的修改将被保留。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '继续审查',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              // 保存已接受的修改并退出 Review Mode
              _finishReview(context, ref);
            },
            child: Text(
              '取消',
              style: AppTextStyles.body.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 完成审查（保存已接受的修改并退出 Review Mode）
  void _finishReview(BuildContext context, WidgetRef ref) {
    // 获取当前的最终计划（包含已接受的修改）
    final finalPlan = ref
        .read(suggestionReviewNotifierProvider.notifier)
        .finishReview();

    // 关闭 Review Mode
    ref.read(isReviewModeProvider.notifier).state = false;

    // 应用最终计划到编辑状态
    if (finalPlan != null) {
      ref
          .read(createTrainingPlanNotifierProvider.notifier)
          .applyModifiedPlan(finalPlan);
    }
  }

  /// 获取修改位置标签 (Day{x}-{ExerciseName})
  String _getChangeLocationLabel(
    PlanChange change,
    SuggestionReviewState state,
  ) {
    try {
      // 确保 dayIndex 有效
      if (change.dayIndex < 0 ||
          change.dayIndex >= state.workingPlan.days.length) {
        return 'Day${change.dayIndex + 1}';
      }

      final day = state.workingPlan.days[change.dayIndex];
      final dayNumber = day.day;

      // 如果有 exerciseIndex，获取动作名称
      if (change.exerciseIndex != null &&
          change.exerciseIndex! >= 0 &&
          change.exerciseIndex! < day.exercises.length) {
        final exerciseName = day.exercises[change.exerciseIndex!].name;
        return 'Day$dayNumber-$exerciseName';
      }

      // 如果没有 exerciseIndex，只显示 Day
      return 'Day$dayNumber';
    } catch (e) {
      // 出错时返回默认格式
      return 'Day${change.dayIndex + 1}';
    }
  }
}
