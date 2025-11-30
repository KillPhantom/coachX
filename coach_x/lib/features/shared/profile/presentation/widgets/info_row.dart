import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 信息行组件
///
/// 显示左侧标签和右侧数值的行
class InfoRow extends StatelessWidget {
  /// 左侧标签文字
  final String label;

  /// 右侧数值文字
  final String value;

  /// 是否显示底部分隔线
  final bool showDivider;

  /// 点击回调（可选，用于编辑功能）
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppTextStyles.bodyMedium),
              if (onTap != null) ...[
                const SizedBox(width: AppDimensions.spacingS),
                Icon(
                  CupertinoIcons.pencil,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Column(
      children: [
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: contentWidget,
          )
        else
          contentWidget,
        if (showDivider) Container(height: 1, color: AppColors.dividerLight),
      ],
    );
  }
}
