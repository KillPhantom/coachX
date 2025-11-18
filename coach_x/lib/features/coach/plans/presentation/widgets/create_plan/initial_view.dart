import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 创建训练计划 - 初始视图（创建方式选择）
///
/// 显示三个创建选项：
/// 1. AI 引导创建
/// 2. 扫描或粘贴文本
/// 3. 手动创建
class InitialView extends StatelessWidget {
  final VoidCallback onAIGuidedTap;
  final VoidCallback onTextImportTap;
  final VoidCallback onManualCreateTap;

  const InitialView({
    super.key,
    required this.onAIGuidedTap,
    required this.onTextImportTap,
    required this.onManualCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎标题
              Text(
                l10n.createPlanTitle,
                style: AppTextStyles.largeTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 副标题
              Text(
                l10n.chooseCreationMethod,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // AI 引导创建按钮
              _buildLargeOptionButton(
                context: context,
                icon: CupertinoIcons.sparkles,
                title: l10n.aiGuidedCreate,
                description: l10n.aiGuidedDesc,
                color: AppColors.primary,
                onTap: onAIGuidedTap,
              ),

              const SizedBox(height: 16),

              // 扫描或粘贴文本按钮
              _buildLargeOptionButton(
                context: context,
                icon: CupertinoIcons.doc_text,
                title: l10n.scanOrPasteText,
                description: l10n.scanOrPasteDesc,
                color: AppColors.secondaryBlue,
                onTap: onTextImportTap,
              ),

              const Spacer(),

              // 手动创建链接
              Center(
                child: CupertinoButton(
                  onPressed: onManualCreateTap,
                  child: Text(
                    l10n.orManualCreate,
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeOptionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),

            const SizedBox(width: 16),

            // 文本内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.title3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.subhead.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 箭头图标
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
