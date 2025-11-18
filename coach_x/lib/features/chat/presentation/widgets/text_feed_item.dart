import 'package:flutter/cupertino.dart';
import '../../data/models/training_feed_item.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class TextFeedItem extends StatelessWidget {
  final TrainingFeedItem feedItem;
  final VoidCallback onCommentTap;
  final VoidCallback onDetailTap;

  const TextFeedItem({
    super.key,
    required this.feedItem,
    required this.onCommentTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = feedItem.metadata!;
    final totalSets = metadata['totalSets'] as int;
    final completedSets = metadata['completedSets'] as int;
    final avgWeight = metadata['avgWeight'] as double;
    final totalReps = metadata['totalReps'] as int;

    return Container(
      color: CupertinoColors.black,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动作名称
          Text(
            feedItem.exerciseName ?? '',
            style: AppTextStyles.largeTitle.copyWith(
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: 8),

          // 副标题
          Text(
            '无视频记录 · 数据汇总',
            style: AppTextStyles.callout.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 32),

          // 数据卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.darkColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _DataRow(label: '完成组数', value: '$completedSets / $totalSets 组'),
                const SizedBox(height: 16),
                _DataRow(
                  label: '平均重量',
                  value: '${avgWeight.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 16),
                _DataRow(label: '总次数', value: '$totalReps 次'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: onCommentTap,
                  child: Text(
                    '批阅',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemGrey5.darkColor,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: onDetailTap,
                  child: Text(
                    '详情',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 批阅状态标记
          if (feedItem.isReviewed)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 16,
                    color: CupertinoColors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已批阅',
                    style: AppTextStyles.callout.copyWith(
                      color: CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: CupertinoColors.systemGrey),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }
}
