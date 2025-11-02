import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 错误视图组件
class ErrorView extends StatelessWidget {
  /// 错误信息
  final String error;

  /// 重试回调
  final VoidCallback onRetry;

  /// 图标
  final IconData? icon;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: AppColors.errorRed,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(l10n.errorTitle, style: AppTextStyles.title2),
          const SizedBox(height: AppDimensions.spacingM),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXXXL,
            ),
            child: Text(
              error,
              style: AppTextStyles.subhead,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          CupertinoButton.filled(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
