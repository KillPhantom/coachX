import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 补剂计划卡片
///
/// 显示今日补剂目标（补剂数量）
class SupplementPlanCard extends StatelessWidget {
  final int supplementsCount;
  final VoidCallback? onTap;

  const SupplementPlanCard({
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
          children: [
            Icon(
              CupertinoIcons.capsule,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.supplementsToTake(supplementsCount),
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
