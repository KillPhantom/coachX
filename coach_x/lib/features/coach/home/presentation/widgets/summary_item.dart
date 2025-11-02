import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// Summary单项组件
///
/// 用于显示Summary区域的每一项统计信息
class SummaryItem extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 文本内容
  final String text;

  /// 点击回调
  final VoidCallback? onTap;

  const SummaryItem({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: AppDimensions.iconL,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(child: Text(text, style: AppTextStyles.body)),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textTertiary,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}
