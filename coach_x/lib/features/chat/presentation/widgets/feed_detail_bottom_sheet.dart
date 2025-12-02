import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/training_feed_item.dart';
import '../../data/models/feed_item_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

/// Feed 详情弹窗
///
/// 显示 Feed Item 的详细信息
/// - 视频项：显示视频列表、动作详情
/// - 图文项：显示组数、重量、次数汇总
/// Feed 详情 Sheet (Inline)
class FeedDetailSheet extends ConsumerWidget {
  final TrainingFeedItem feedItem;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const FeedDetailSheet({
    super.key,
    required this.feedItem,
    required this.scrollController,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: CustomScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),

                // 标题
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          feedItem.exerciseName ?? l10n.exerciseDetails,
                          style: AppTextStyles.title3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: onClose,
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: AppColors.textTertiary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: feedItem.type == FeedItemType.video
                ? _VideoDetailsContent(feedItem: feedItem)
                : feedItem.type == FeedItemType.textCard
                ? _TextCardDetailsContent(feedItem: feedItem)
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

/// 视频项详情内容
class _VideoDetailsContent extends StatelessWidget {
  final TrainingFeedItem feedItem;

  const _VideoDetailsContent({required this.feedItem});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metadata = feedItem.metadata!;
    final videoIndex = metadata['videoIndex'] as int;
    final totalVideos = metadata['totalVideos'] as int;
    final duration = metadata['duration'] as int?;
    final timeSpent = metadata['timeSpent'] as int?;
    final sets = metadata['sets'] as List?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视频信息卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: l10n.videoNumber(videoIndex + 1),
                  value: '$totalVideos ${l10n.videos}',
                ),
                if (duration != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: l10n.videoDuration,
                    value: _formatDuration(duration),
                  ),
                ],
                if (timeSpent != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: '耗时', // TODO: l10n
                    value: _formatDuration(timeSpent),
                  ),
                ],
                const SizedBox(height: 12),
                _DetailRow(
                  label: l10n.reviewStatus,
                  value: feedItem.isReviewed ? l10n.reviewed : l10n.notReviewed,
                  valueColor: feedItem.isReviewed
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),

          if (sets != null && sets.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.setDetails, style: AppTextStyles.title3),
            const SizedBox(height: 12),
            ...sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value as Map<String, dynamic>;
              return _buildSetItem(index, set);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSetItem(int index, Map<String, dynamic> set) {
    final completed = set['completed'] as bool? ?? false;
    final weight = num.tryParse(set['weight']?.toString() ?? '');
    final reps = int.tryParse(set['reps']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? AppColors.primary : AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: completed ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${weight ?? '-'} kg × ${reps ?? '-'}',
              style: AppTextStyles.body,
            ),
          ),
          if (completed)
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 20,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// 图文项详情内容
class _TextCardDetailsContent extends StatelessWidget {
  final TrainingFeedItem feedItem;

  const _TextCardDetailsContent({required this.feedItem});

  @override
  Widget build(BuildContext context) {
    final metadata = feedItem.metadata!;
    final isAggregated = metadata['isAggregated'] == true;

    if (isAggregated) {
      return _buildAggregatedContent(context, metadata);
    } else {
      return _buildSingleContent(context, metadata);
    }
  }

  Widget _buildAggregatedContent(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final exercises = metadata['exercises'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercises.isNotEmpty) ...[
            Text('非视频动作', style: AppTextStyles.title3),
            const SizedBox(height: 16),
            ...exercises.map((e) {
              final exercise = e as Map<String, dynamic>;
              final name = exercise['name'] as String? ?? '';
              final sets = exercise['sets'] as List? ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodySemiBold),
                  const SizedBox(height: 8),
                  ...sets.asMap().entries.map((entry) {
                    return _buildSetItem(
                      entry.key,
                      entry.value as Map<String, dynamic>,
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleContent(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final sets = metadata['sets'] as List;
    final totalSets = metadata['totalSets'] as int;
    final completedSets = metadata['completedSets'] as int;
    final avgWeight = metadata['avgWeight'] as double;
    final totalReps = metadata['totalReps'] as int;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 汇总信息卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: l10n.completedSets,
                  value: '$completedSets / $totalSets',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: l10n.averageWeight,
                  value: '${avgWeight.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.totalReps, value: '$totalReps'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 组数列表
          Text(l10n.setDetails, style: AppTextStyles.title3),
          const SizedBox(height: 12),

          ...sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value as Map<String, dynamic>;
            return _buildSetItem(index, set);
          }),
        ],
      ),
    );
  }

  Widget _buildSetItem(int index, Map<String, dynamic> set) {
    final completed = set['completed'] as bool? ?? false;
    final weight = num.tryParse(set['weight']?.toString() ?? '');
    final reps = int.tryParse(set['reps']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? AppColors.primary : AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: completed ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${weight ?? '-'} kg × ${reps ?? '-'}',
              style: AppTextStyles.body,
            ),
          ),
          if (completed)
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 20,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}

/// 详情行组件
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
