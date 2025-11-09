import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/routes/route_names.dart';

/// 记录活动底部弹窗
///
/// 显示添加记录选项的现代化底部弹窗
class RecordActivityBottomSheet extends StatelessWidget {
  const RecordActivityBottomSheet({super.key});

  /// 显示底部弹窗
  static Future<void> show(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => const RecordActivityBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽条
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),

            // 标题区域
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL,
                vertical: AppDimensions.spacingM,
              ),
              child: Column(
                children: [
                  Text(
                    l10n.addRecordTitle,
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    l10n.addRecordSubtitle,
                    style: AppTextStyles.subhead.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 选项列表
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL,
              ),
              child: Column(
                children: [
                  // Record Meal - 跳转到AI食物扫描
                  _RecordOption(
                    icon: CupertinoIcons.square_favorites_alt,
                    title: l10n.dietRecord,
                    description: l10n.dietRecordDesc,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.studentAIFoodScanner);
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),

                  // Record Exercise
                  _RecordOption(
                    icon: CupertinoIcons.flame,
                    title: l10n.trainingRecord,
                    description: l10n.trainingRecordDesc,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.studentExerciseRecord);
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),

                  // Record Body Stats
                  _RecordOption(
                    icon: CupertinoIcons.person_crop_square,
                    title: l10n.bodyMeasurement,
                    description: l10n.bodyMeasurementDesc,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(RouteNames.studentBodyStatsRecord);
                    },
                  ),
                ],
              ),
            ),

            // Cancel 按钮
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(12.0),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示TODO提示
  static void _showTodoAlert(
    BuildContext context,
    String title,
    String message,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('TODO: $title'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.know),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// 记录选项卡片
class _RecordOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RecordOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 24.0, color: AppColors.primaryText),
            ),
            const SizedBox(width: AppDimensions.spacingM),

            // 标题和描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    description,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 右箭头
            Icon(
              CupertinoIcons.chevron_right,
              size: 20.0,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
