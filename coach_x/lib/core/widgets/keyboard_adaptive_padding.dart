import 'package:flutter/cupertino.dart';

/// 键盘自适应内边距组件
///
/// 自动检测键盘高度并添加底部内边距，防止键盘遮挡内容。
/// 使用平滑动画过渡，适配 iOS 风格。
///
/// 使用场景：
/// - 底部弹窗（Bottom Sheet）中包含输入框
/// - 需要在键盘弹出时自动调整布局
///
/// 示例：
/// ```dart
/// KeyboardAdaptivePadding(
///   child: Container(
///     child: CupertinoTextField(...),
///   ),
/// )
/// ```
class KeyboardAdaptivePadding extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 动画时长，默认 150ms（接近 iOS 系统键盘动画）
  final Duration? animationDuration;

  /// 动画曲线，默认 Curves.easeOutCubic（iOS 风格）
  final Curve? curve;

  const KeyboardAdaptivePadding({
    super.key,
    required this.child,
    this.animationDuration,
    this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: animationDuration ?? const Duration(milliseconds: 150),
      curve: curve ?? Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }
}
