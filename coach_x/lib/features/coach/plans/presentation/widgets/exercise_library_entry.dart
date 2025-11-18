import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';

/// 动作库入口组件 - 显示在训练计划tab的搜索栏上方
class ExerciseLibraryEntry extends StatelessWidget {
  const ExerciseLibraryEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/coach/exercise-library'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingS,
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧图标
            Icon(
              CupertinoIcons.square_grid_2x2,
              color: AppColors.primaryText,
              size: 24,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            // 文字
            Expanded(
              child: Text(
                l10n.exerciseLibrary,
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // 右侧箭头
            Icon(
              CupertinoIcons.forward,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
