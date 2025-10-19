import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// BuildContext 扩展方法
extension ContextExtensions on BuildContext {
  /// 快速访问 MediaQueryData
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// 获取屏幕宽度
  double get screenWidth => mediaQuery.size.width;

  /// 获取屏幕高度
  double get screenHeight => mediaQuery.size.height;

  /// 获取屏幕方向
  Orientation get orientation => mediaQuery.orientation;

  /// 是否为横屏
  bool get isLandscape => orientation == Orientation.landscape;

  /// 是否为竖屏
  bool get isPortrait => orientation == Orientation.portrait;

  /// 获取状态栏高度
  double get statusBarHeight => mediaQuery.padding.top;

  /// 获取底部安全区域高度
  double get bottomPadding => mediaQuery.padding.bottom;

  /// 快速访问 Cupertino 主题
  CupertinoThemeData get theme => CupertinoTheme.of(this);

  /// 快速访问主色
  Color get primaryColor => theme.primaryColor;

  /// 快速访问文字主题
  CupertinoTextThemeData get textTheme => theme.textTheme;

  /// 快速访问背景色
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// 显示 Snackbar（使用 CupertinoAlertDialog 模拟）
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    showCupertinoDialog(
      context: this,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color:
                backgroundColor ?? AppColors.textPrimary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(color: AppColors.textWhite, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    // 自动关闭
    Future.delayed(duration, () {
      if (Navigator.of(this).canPop()) {
        Navigator.of(this).pop();
      }
    });
  }

  /// 显示加载对话框
  void showLoadingDialog({String? message}) {
    showCupertinoDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(fontSize: 15)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 关闭加载对话框
  void hideLoadingDialog() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  /// 显示确认对话框
  Future<bool?> showConfirmDialog({
    required String title,
    String? message,
    String confirmText = '确定',
    String cancelText = '取消',
  }) {
    return showCupertinoDialog<bool>(
      context: this,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 显示提示对话框
  Future<void> showAlertDialog({
    required String title,
    String? message,
    String buttonText = '确定',
  }) {
    return showCupertinoDialog(
      context: this,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// 显示操作表（Action Sheet）
  Future<T?> showActionSheet<T>({
    required List<CupertinoActionSheetAction> actions,
    Widget? title,
    Widget? message,
    Widget? cancelButton,
  }) {
    return showCupertinoModalPopup<T>(
      context: this,
      builder: (context) => CupertinoActionSheet(
        title: title,
        message: message,
        actions: actions,
        cancelButton:
            cancelButton ??
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
      ),
    );
  }

  /// 页面跳转
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(CupertinoPageRoute(builder: (_) => page));
  }

  /// 页面跳转并替换当前页面
  Future<T?> pushReplacement<T>(Widget page) {
    return Navigator.of(
      this,
    ).pushReplacement<T, void>(CupertinoPageRoute(builder: (_) => page));
  }

  /// 页面跳转并移除之前所有页面
  Future<T?> pushAndRemoveUntil<T>(Widget page) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      CupertinoPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// 返回上一页
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// 隐藏键盘
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// 请求焦点
  void requestFocus(FocusNode focusNode) {
    FocusScope.of(this).requestFocus(focusNode);
  }
}
