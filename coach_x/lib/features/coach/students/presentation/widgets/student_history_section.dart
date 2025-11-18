import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/routes/route_names.dart';
import '../../data/models/student_detail_model.dart';

/// 训练历史区块
class StudentHistorySection extends StatelessWidget {
  final List<RecentTraining> recentTrainings;
  final String studentId;

  const StudentHistorySection({
    super.key,
    required this.recentTrainings,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和查看全部按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.trainingHistory,
                style: AppTextStyles.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () {
                  context.push(
                    '${RouteNames.coachTrainingReviews}?studentId=$studentId',
                  );
                },
                child: Text(
                  '${l10n.viewAll} ›',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.secondaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 训练记录列表
          if (recentTrainings.isEmpty)
            _buildEmptyState(l10n)
          else
            Column(
              children: recentTrainings
                  .map(
                    (training) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTrainingItem(context, l10n, training),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        'No training records yet',
        style: AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  /// 构建训练记录项
  Widget _buildTrainingItem(
    BuildContext context,
    AppLocalizations l10n,
    RecentTraining training,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        context.push('/training-review/${training.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 日期
            _buildDateColumn(training.date),

            const SizedBox(width: 12),

            // 训练信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    training.title,
                    style: AppTextStyles.footnote.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${training.exerciseCount} ${l10n.exercises} • '
                    '${training.videoCount} ${l10n.videos} • '
                    '${training.formattedDuration}',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 状态Badge
            _buildStatusBadge(l10n, training.isReviewed),
          ],
        ),
      ),
    );
  }

  /// 构建日期列
  Widget _buildDateColumn(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return SizedBox(
        width: 50,
        child: Column(
          children: [
            Text(
              date.day.toString().padLeft(2, '0'),
              style: AppTextStyles.title3.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getMonthAbbr(date.month),
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return SizedBox(
        width: 50,
        child: Text(
          dateStr.substring(0, 5),
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
  }

  /// 获取月份缩写
  String _getMonthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  /// 构建状态Badge
  Widget _buildStatusBadge(AppLocalizations l10n, bool isReviewed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReviewed ? const Color(0xFFD1F2EB) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isReviewed ? l10n.reviewed : l10n.pending,
        style: AppTextStyles.caption2.copyWith(
          color: isReviewed ? const Color(0xFF0C5449) : const Color(0xFF856404),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
