import 'package:flutter/cupertino.dart';

/// DismissKeyboard Widget
///
/// 点击外部区域时关闭键盘的包装器组件
///
/// 使用场景：
/// - 表单页面（登录页、注册页等）
/// - 静态内容页面（包含输入框但不需要滚动的页面）
///
/// 特性：
/// - 使用 HitTestBehavior.translucent 不阻止子widget的点击事件
/// - 只在有焦点时执行unfocus，避免不必要的操作
/// - 点击另一个输入框时会自动切换焦点（TextField默认行为）
///
/// 示例：
/// ```dart
/// CupertinoPageScaffold(
///   child: SafeArea(
///     child: DismissKeyboard(
///       child: SingleChildScrollView(
///         child: Form(...),
///       ),
///     ),
///   ),
/// )
/// ```
class DismissKeyboard extends StatelessWidget {
  /// 子widget
  final Widget child;

  const DismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      // 使用 translucent 允许手势向下传递，不阻止子widget的点击事件
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }

  /// 处理点击事件，关闭键盘
  void _handleTap(BuildContext context) {
    // 获取当前焦点
    final currentFocus = FocusScope.of(context);

    // 只在有焦点时才执行unfocus，避免不必要的操作
    // hasPrimaryFocus 为 false 表示焦点在子widget上
    // focusedChild 不为 null 表示确实有子widget获得了焦点
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      // 使用 FocusManager 确保正确地移除焦点
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
