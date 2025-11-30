import 'package:flutter/material.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

class SummaryHeader extends StatelessWidget {
  final int recordDaysCount;
  final int coachReviewsCount;

  const SummaryHeader({
    super.key,
    required this.recordDaysCount,
    required this.coachReviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  count: recordDaysCount,
                  label: 'record days',
                ),
                const VerticalDivider(
                  color: AppColors.dividerLight,
                  thickness: 1,
                  width: 1,
                  indent: 4,
                  endIndent: 4,
                ),
                _buildStatItem(
                  context,
                  count: coachReviewsCount,
                  label: 'coach reviews',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context,
      {required int count, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTextStyles.title2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
