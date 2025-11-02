import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// 空状态组件
class EmptyState extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标题
  final String title;

  /// 描述信息
  final String? message;

  /// 按钮文字
  final String? actionText;

  /// 按钮点击事件
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppDimensions.spacingL),
          Text(title, style: AppTextStyles.title2, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXXXL,
              ),
              child: Text(
                message!,
                style: AppTextStyles.subhead,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.spacingXL),
            CupertinoButton.filled(
              onPressed: onAction,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}
