import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_timing.dart';

/// 补剂日内容组件
///
/// 展示单日完整补剂计划，按时间段分组显示
class SupplementDayContent extends StatelessWidget {
  final SupplementDay supplementDay;

  const SupplementDayContent({super.key, required this.supplementDay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 所有时间段列表
        ...supplementDay.timings
            .map((timing) => _buildTimingSection(context, timing)),
      ],
    );
  }

  /// 构建时间段区块
  Widget _buildTimingSection(BuildContext context, SupplementTiming timing) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间段名称
          Row(
            children: [
              const Icon(
                CupertinoIcons.clock,
                size: 18,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                timing.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // 时间段备注
          if (timing.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              timing.note,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.spacingM),

          // 补剂列表
          ...timing.supplements.map((supplement) => Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.capsule_fill,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 补剂名称
                        Text(
                          supplement.name,
                          style: AppTextStyles.callout.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 剂量
                        Text(
                          supplement.amount,
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        // 补剂备注
                        if (supplement.note != null && supplement.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            supplement.note!,
                            style: AppTextStyles.caption1.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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
}
