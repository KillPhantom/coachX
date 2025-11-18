import 'package:flutter/cupertino.dart';

/// DismissKeyboardOnScroll Widget
///
/// 滚动时自动关闭键盘的包装器组件
///
/// 使用场景：
/// - 滚动列表页面（计划列表、学生列表等）
/// - 包含搜索框的列表页面
/// - 任何需要在滚动时自动关闭键盘的场景
///
/// 特性：
/// - 使用 NotificationListener 监听滚动事件，性能开销极小
/// - 只在滚动开始时执行一次unfocus，避免重复操作
/// - 不消费滚动事件，不影响其他滚动监听器
/// - 符合 iOS 标准交互行为
///
/// 性能优化：
/// - 只监听 ScrollStartNotification，不影响滚动流畅度
/// - 不增加widget树层级（NotificationListener不影响布局）
/// - 比 GestureDetector 方案更轻量
///
/// 示例：
/// ```dart
/// Column(
///   children: [
///     SearchBar(...),
///     Expanded(
///       child: DismissKeyboardOnScroll(
///         child: ListView.builder(...),
///       ),
///     ),
///   ],
/// )
/// ```
class DismissKeyboardOnScroll extends StatelessWidget {
  /// 子widget（通常是 ScrollView）
  final Widget child;

  const DismissKeyboardOnScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _handleScrollNotification(notification),
      child: child,
    );
  }

  /// 处理滚动通知
  bool _handleScrollNotification(ScrollNotification notification) {
    // 只在滚动开始时失焦，避免在滚动过程中重复执行
    if (notification is ScrollStartNotification) {
      // 关闭键盘
      FocusManager.instance.primaryFocus?.unfocus();
    }

    // 返回 false 表示不消费这个通知，允许其他监听器继续处理
    // 这确保了不会影响其他依赖滚动事件的功能
    return false;
  }
}
