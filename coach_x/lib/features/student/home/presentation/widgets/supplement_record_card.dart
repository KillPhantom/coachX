import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 补剂记录卡片
///
/// 显示今日补剂目标（补剂数量）
class SupplementRecordCard extends StatelessWidget {
  final int supplementsCount;
  final VoidCallback? onTap;

  const SupplementRecordCard({
    super.key,
    required this.supplementsCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.supplementRecord,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            Row(
              children: [
                Icon(
                  CupertinoIcons.capsule,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.supplementsCount(supplementsCount),
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
