import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/diet_suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_providers.dart';

/// Diet Plan Review Mode 全页面 Overlay
///
/// 显示饮食计划修改审查界面，包含：
/// - 半透明遮罩
/// - 当前修改详情卡片
/// - 进度指示器
/// - 控制按钮（接受/拒绝/全部接受）
class DietReviewModeOverlay extends ConsumerWidget {
  final int? focusedDayIndex;
  final int? focusedMealIndex;

  const DietReviewModeOverlay({
    super.key,
    this.focusedDayIndex,
    this.focusedMealIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(dietSuggestionReviewNotifierProvider);

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
    DietPlanChange change,
    DietSuggestionReviewState reviewState,
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
                  color: AppColors.primaryText,
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
                    .read(dietSuggestionReviewNotifierProvider.notifier)
                    .toggleShowAllChanges(),
                child: Text(
                  '查看全部',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.primaryText,
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
              // 位置标签 (Day{x}-{MealName})
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getChangeLocationLabel(change, reviewState),
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.primaryText,
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
                color: AppColors.primaryText,
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
        ],
      ),
    );
  }

  /// 构建简化的修改描述
  String _buildCompactDescription(DietPlanChange change) {
    switch (change.type) {
      case DietChangeType.addDay:
        final dayName = change.after as String? ?? '新饮食日';
        return '添加饮食日: $dayName';
      case DietChangeType.addMeal:
        String mealName = '新餐次';
        if (change.after is Map) {
          mealName = (change.after as Map)['name'] as String? ?? '新餐次';
        } else if (change.after is String) {
          mealName = change.after as String;
        }
        return '添加餐次: $mealName';
      case DietChangeType.addFoodItem:
        if (change.after is Map) {
          final food = (change.after as Map)['food'] as String? ?? '新食物';
          return '添加食物: $food';
        }
        return '添加食物';
      case DietChangeType.modifyMeal:
        // 餐次名称修改
        if (change.before is String && change.after is String) {
          return '${change.before} → ${change.after}';
        }
        return change.description;
      case DietChangeType.modifyFoodItem:
        // 食物修改：从 Map 中提取 food 和 amount
        if (change.before is Map && change.after is Map) {
          final beforeFood = (change.before as Map)['food'] as String? ?? '';
          final beforeAmount =
              (change.before as Map)['amount'] as String? ?? '';
          final afterFood = (change.after as Map)['food'] as String? ?? '';
          final afterAmount = (change.after as Map)['amount'] as String? ?? '';

          // 如果食物名称相同，只显示分量变化
          if (beforeFood == afterFood && beforeFood.isNotEmpty) {
            return '$beforeFood $beforeAmount → $afterAmount';
          } else if (beforeFood.isNotEmpty && afterFood.isNotEmpty) {
            // 食物名称和分量都变了
            return '$beforeFood $beforeAmount → $afterFood $afterAmount';
          }
        }
        return change.description;
      default:
        return change.description;
    }
  }

  /// 构建全部改动视图
  Widget _buildAllChangesView(
    BuildContext context,
    WidgetRef ref,
    DietSuggestionReviewState state,
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
                  color: AppColors.primaryText,
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
                    .read(dietSuggestionReviewNotifierProvider.notifier)
                    .toggleShowAllChanges(),
                child: Text(
                  '收起',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.primaryText,
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
                        ? AppColors.primaryText.withOpacity(0.1)
                        : CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent
                        ? Border.all(color: AppColors.primaryText, width: 1.5)
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

                      // 位置标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryText.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getChangeLocationLabel(change, state),
                          style: AppTextStyles.caption2.copyWith(
                            color: AppColors.primaryText,
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

  /// 构建控制按钮
  Widget _buildControlButtons(
    BuildContext context,
    WidgetRef ref,
    bool hasNext,
    bool isShowingAll,
  ) {
    final String acceptText;
    final VoidCallback acceptAction;

    if (isShowingAll) {
      acceptText = '全部接受';
      acceptAction = () => _acceptAll(context, ref);
    } else {
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
    ref.read(dietSuggestionReviewNotifierProvider.notifier).acceptCurrent();
  }

  /// 拒绝当前修改
  void _rejectCurrent(WidgetRef ref) {
    ref.read(dietSuggestionReviewNotifierProvider.notifier).rejectCurrent();
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
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(dietSuggestionReviewNotifierProvider.notifier)
                  .acceptAll();
              _finishReview(context, ref);
            },
            child: const Text('确定'),
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
        .read(dietSuggestionReviewNotifierProvider.notifier)
        .finishReview();

    // 关闭 Review Mode
    ref.read(isDietReviewModeProvider.notifier).state = false;

    // 应用最终计划到编辑状态
    if (finalPlan != null) {
      ref
          .read(createDietPlanNotifierProvider.notifier)
          .applyModifiedPlan(finalPlan);
    }
  }

  /// 获取修改位置标签 (Day{x}-{MealName})
  String _getChangeLocationLabel(
    DietPlanChange change,
    DietSuggestionReviewState state,
  ) {
    try {
      // 确保 dayIndex 有效
      if (change.dayIndex < 0 ||
          change.dayIndex >= state.workingPlan.days.length) {
        return 'Day${change.dayIndex + 1}';
      }

      final day = state.workingPlan.days[change.dayIndex];
      final dayNumber = day.day;

      // 如果有 mealIndex，获取餐次名称
      if (change.mealIndex != null &&
          change.mealIndex! >= 0 &&
          change.mealIndex! < day.meals.length) {
        final mealName = day.meals[change.mealIndex!].name;
        return 'Day$dayNumber-$mealName';
      }

      // 如果没有 mealIndex，只显示 Day
      return 'Day$dayNumber';
    } catch (e) {
      // 出错时返回默认格式
      return 'Day${change.dayIndex + 1}';
    }
  }
}
