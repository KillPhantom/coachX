import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// Settings 行组件
///
/// 用于 Settings 卡片中的每一行选项
class SettingsRow extends StatelessWidget {
  /// 选项文字
  final String title;

  /// 点击回调
  final VoidCallback? onTap;

  /// 右侧组件（可选，如 Toggle、箭头等）
  final Widget? trailing;

  /// 是否为危险操作（如 Log Out），使用红色文字
  final bool isDangerous;

  /// 是否显示底部分隔线
  final bool showDivider;

  const SettingsRow({
    super.key,
    required this.title,
    this.onTap,
    this.trailing,
    this.isDangerous = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingL,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: isDangerous ? AppColors.errorRed : AppColors.textPrimary,
                  ),
                ),
                trailing ??
                    Icon(
                      CupertinoIcons.forward,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: AppDimensions.paddingL),
            color: AppColors.dividerLight,
          ),
      ],
    );
  }
}
