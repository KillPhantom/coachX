import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/training_review_list_item_model.dart';

/// 训练审核卡片组件
///
/// 显示：学生头像 + 姓名 + 日期 + 审核状态Badge
class TrainingReviewCard extends StatelessWidget {
  final TrainingReviewListItemModel item;

  const TrainingReviewCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        // 跳转到训练详情审核页面
        context.push(
          '/coach/training-feed/${item.dailyTrainingId}?studentId=${item.studentId}&studentName=${item.studentName}',
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学生头像
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              backgroundImage: item.studentAvatarUrl != null
                  ? NetworkImage(item.studentAvatarUrl!)
                  : null,
              child: item.studentAvatarUrl == null
                  ? Text(
                      _getInitials(item.studentName),
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // 中间内容：标题、统计、pills
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题：{Student} - {ExercisePlan} - {DietPlan}
                  _buildCardTitle(),
                  // 统计摘要
                  if (_buildSummaryStats(l10n) != null) ...[
                    const SizedBox(height: 6),
                    _buildSummaryStats(l10n)!,
                  ],
                  // 运动pills
                  if (_buildExercisePills() != null) ...[
                    const SizedBox(height: 8),
                    _buildExercisePills()!,
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 右侧：日期和状态
            _buildDateAndStatus(l10n),
          ],
        ),
      ),
    );
  }

  /// 构建卡片标题: {Student} - {ExercisePlan} - {DietPlan}
  Widget _buildCardTitle() {
    final parts = <String>[item.studentName];

    if (item.planName != null) {
      parts.add(item.planName!);
    }

    if (item.dietPlanName != null) {
      parts.add(item.dietPlanName!);
    }

    return Text(
      parts.join(' - '),
      style: AppTextStyles.callout.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建日期和状态
  Widget _buildDateAndStatus(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态Badge
        _buildStatusBadge(l10n),
        const SizedBox(height: 4),
        // 日期
        Text(
          _formatDate(item.dateTime),
          style: AppTextStyles.caption1.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  /// 构建运动名称pills（单行显示，超出宽度时截断）
  Widget? _buildExercisePills() {
    if (item.exercises == null || item.exercises!.isEmpty) return null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...item.exercises!
              .take(3)
              .map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.name,
                      style: AppTextStyles.caption2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          if (item.exercises!.length > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${item.exercises!.length - 3} more',
                style: AppTextStyles.caption2.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建统计摘要
  Widget? _buildSummaryStats(AppLocalizations l10n) {
    final hasExercises = item.exercises != null && item.exercises!.isNotEmpty;
    if (!hasExercises && item.mealCount == 0) return null;

    // 计算总视频数
    final totalVideos = hasExercises
        ? item.exercises!.fold<int>(
            0,
            (sum, exercise) => sum + exercise.videos.length,
          )
        : 0;

    final stats = <String>[];
    if (hasExercises) {
      stats.add('${item.exercises!.length} exercises');
    }
    if (totalVideos > 0) {
      stats.add('$totalVideos videos');
    }
    if (item.mealCount > 0) {
      stats.add('${item.mealCount} meals');
    }

    if (stats.isEmpty) return null;

    return Text(
      stats.join('  •  '),
      style: AppTextStyles.caption1.copyWith(color: AppColors.textTertiary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建状态Badge
  Widget _buildStatusBadge(AppLocalizations l10n) {
    final isReviewed = item.isReviewed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isReviewed
            ? AppColors.successGreen.withValues(alpha: 0.15)
            : AppColors.warningYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isReviewed ? l10n.statusReviewed : l10n.statusPending,
        style: AppTextStyles.caption1.copyWith(
          color: isReviewed ? AppColors.successGreen : AppColors.warningYellow,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 获取姓名首字母
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// 格式化日期
  /// 格式: "MMM d, yyyy" (e.g., "Nov 12, 2025")
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
