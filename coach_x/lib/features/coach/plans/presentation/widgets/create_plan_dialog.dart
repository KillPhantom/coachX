import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 创建计划弹窗
class CreatePlanDialog extends StatelessWidget {
  const CreatePlanDialog({super.key});

  /// 显示弹窗
  static Future<String?> show(BuildContext context) {
    return showCupertinoDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreatePlanDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部手柄
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 标题
            Text(
              l10n.createNewPlanTitle,
              style: AppTextStyles.title2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // 副标题
            Text(
              l10n.createPlanSubtitle,
              style: AppTextStyles.callout.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // 选项列表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _PlanOptionCard(
                    icon: CupertinoIcons.sportscourt_fill,
                    iconColor: const Color(0xFFEC1313),
                    iconBackground: const Color(0xFFEC1313).withOpacity(0.1),
                    title: l10n.exercisePlanTitle,
                    description: l10n.exercisePlanDesc,
                    onTap: () => Navigator.of(context).pop('exercise'),
                  ),
                  const SizedBox(height: 12),
                  _PlanOptionCard(
                    icon: CupertinoIcons.square_favorites_alt_fill,
                    iconColor: AppColors.successGreen,
                    iconBackground: AppColors.successGreen.withOpacity(0.1),
                    title: l10n.dietPlanTitle,
                    description: l10n.dietPlanDesc,
                    onTap: () => Navigator.of(context).pop('diet'),
                  ),
                  const SizedBox(height: 12),
                  _PlanOptionCard(
                    icon: CupertinoIcons.capsule_fill,
                    iconColor: AppColors.infoBlue,
                    iconBackground: AppColors.infoBlue.withOpacity(0.1),
                    title: l10n.supplementPlanTitle,
                    description: l10n.supplementPlanDesc,
                    onTap: () => Navigator.of(context).pop('supplement'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 取消按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.cancel,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 计划选项卡片
class _PlanOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PlanOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.footnote),
                ],
              ),
            ),
            // 右侧箭头
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
