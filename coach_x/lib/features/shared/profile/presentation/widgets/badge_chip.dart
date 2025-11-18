import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 认证标签组件
///
/// 用于显示用户的认证信息，如 "IFFF Pro", "Certified" 等
class BadgeChip extends StatelessWidget {
  /// 标签文字
  final String tag;

  const BadgeChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(tag);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS - 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        tag,
        style: AppTextStyles.caption1.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 根据标签名称获取颜色
  Color _getBadgeColor(String tag) {
    final lowerTag = tag.toLowerCase();

    // IFFF Pro - 蓝色
    if (lowerTag.contains('ifff') || lowerTag.contains('pro')) {
      return AppColors.infoBlue;
    }

    // Certified - 绿色
    if (lowerTag.contains('certified') || lowerTag.contains('认证')) {
      return AppColors.successGreen;
    }

    // 默认颜色
    return AppColors.primary;
  }
}
