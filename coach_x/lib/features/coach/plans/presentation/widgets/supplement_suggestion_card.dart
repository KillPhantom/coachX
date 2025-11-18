import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';

/// 补剂建议卡片
class SupplementSuggestionCard extends StatelessWidget {
  final SupplementDay supplementDay;
  final VoidCallback onApply;
  final VoidCallback onReject;

  const SupplementSuggestionCard({
    super.key,
    required this.supplementDay,
    required this.onApply,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 补剂内容
          _buildContent(context),

          // 按钮区域
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 遍历时间段
          ...supplementDay.timings.asMap().entries.map((entry) {
            final index = entry.key;
            final timing = entry.value;
            final isLast = index == supplementDay.timings.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimingSection(context, timing),
                if (!isLast) const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimingSection(BuildContext context, timing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 时间段标题
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timing.name,
              style: AppTextStyles.footnote.copyWith(
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 时间段备注（如果有）
        if (timing.note.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Text(
              timing.note,
              style: AppTextStyles.caption2.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // 补剂列表
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: timing.supplements.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final supplement = entry.value;
              final isLast = index == timing.supplements.length - 1;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // 圆点
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 补剂名称
                      Expanded(
                        child: Text(
                          supplement.name,
                          style: AppTextStyles.caption1.copyWith(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 用量
                      Text(
                        supplement.amount,
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) const SizedBox(height: 6),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 拒绝按钮
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onReject,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Reject',
                  style: AppTextStyles.footnote.copyWith(
                    color: CupertinoColors.systemRed.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 应用按钮
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onApply,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Apply',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
