import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// Toast 工具类
///
/// 提供轻量级的提示消息显示功能
class ToastUtils {
  ToastUtils._(); // 私有构造函数

  /// 显示成功提示
  static void showSuccessToast(BuildContext context, String message) {
    _showToast(
      context,
      message,
      icon: CupertinoIcons.check_mark_circled_solid,
      iconColor: AppColors.successGreen,
    );
  }

  /// 显示错误提示
  static void showErrorToast(BuildContext context, String message) {
    _showToast(
      context,
      message,
      icon: CupertinoIcons.xmark_circle_fill,
      iconColor: AppColors.errorRed,
    );
  }

  /// 显示信息提示
  static void showInfoToast(BuildContext context, String message) {
    _showToast(
      context,
      message,
      icon: CupertinoIcons.info_circle_fill,
      iconColor: AppColors.secondaryBlue,
    );
  }

  /// 内部方法：显示 Toast
  static void _showToast(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color iconColor,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) =>
          _ToastWidget(message: message, icon: icon, iconColor: iconColor),
    );

    overlay.insert(overlayEntry);

    // 2 秒后自动移除
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

/// Toast Widget
class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // 1.7 秒后开始淡出动画
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 24),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTextStyles.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
