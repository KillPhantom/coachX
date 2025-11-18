import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';

/// SupplementDay 详情 Sheet
///
/// 显示补剂日的详细信息，按时间段分组显示补剂
class SupplementDayDetailSheet extends StatelessWidget {
  final SupplementDay supplementDay;

  const SupplementDayDetailSheet({super.key, required this.supplementDay});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.dividerLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplementDay.name,
                        style: AppTextStyles.title3.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.supplementPlan,
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // 补剂列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              itemCount: supplementDay.timings.length,
              itemBuilder: (context, index) {
                final timing = supplementDay.timings[index];
                return _buildTimingSection(context, timing, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection(
    BuildContext context,
    timing,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间段名称
          Text(
            timing.name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
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

          const SizedBox(height: AppDimensions.spacingS),

          // 补剂列表
          ...timing.supplements.map((supplement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.capsule_fill,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplement.name,
                          style: AppTextStyles.callout.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supplement.amount,
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (supplement.note != null &&
                            supplement.note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
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
            );
          }).toList(),
        ],
      ),
    );
  }
}
