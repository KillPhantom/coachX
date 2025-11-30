import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../data/models/invitation_code_model.dart';

/// 邀请码项组件
class InvitationCodeItem extends StatelessWidget {
  final InvitationCodeModel code;

  const InvitationCodeItem({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: code.isExpired
              ? AppColors.errorRed.withValues(alpha: 0.3)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 邀请码
                Text(
                  code.code,
                  style: AppTextStyles.bodySemiBold.copyWith(
                    color: code.isExpired
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingS),

                // 签约时长
                Text(
                  '签约时长: ${code.totalDays}天',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXS),

                // 过期时间或状态
                if (code.used)
                  Text(
                    '已使用',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  )
                else if (code.isExpired)
                  Text(
                    '已过期',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.errorRed,
                    ),
                  )
                else
                  Text(
                    '剩余 ${code.expiresInDays} 天',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.successGreen,
                    ),
                  ),

                // 备注
                if (code.note.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '备注: ${code.note}',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // 复制按钮
          if (code.isValid)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _copyCode(context),
              child: const Icon(
                CupertinoIcons.doc_on_clipboard,
                size: AppDimensions.iconM,
                color: AppColors.primaryText,
              ),
            ),
        ],
      ),
    );
  }

  /// 复制邀请码
  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code.code));

    // 显示提示
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: const Text('邀请码已复制'),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定', style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
