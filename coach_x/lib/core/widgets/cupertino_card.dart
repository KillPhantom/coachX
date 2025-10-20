import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// iOS风格卡片组件
/// 提供统一的卡片样式
class CupertinoCard extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 内边距
  final EdgeInsets padding;

  /// 外边距
  final EdgeInsets margin;

  /// 圆角半径
  final double borderRadius;

  /// 背景颜色
  final Color? backgroundColor;

  /// 点击事件
  final VoidCallback? onTap;

  /// 是否显示阴影
  final bool showShadow;

  const CupertinoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingL),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppDimensions.radiusL,
    this.backgroundColor,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
    }

    return card;
  }
}
