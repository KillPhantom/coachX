import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../enums/app_status.dart';

/// 自定义按钮组件
class CustomButton extends StatelessWidget {
  /// 按钮文字
  final String text;

  /// 点击事件
  final VoidCallback onPressed;

  /// 按钮类型
  final ButtonType type;

  /// 按钮大小
  final ButtonSize size;

  /// 是否加载中
  final bool isLoading;

  /// 是否全宽
  final bool fullWidth;

  /// 是否禁用
  final bool disabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final double height = _getHeight();
    final TextStyle textStyle = _getTextStyle();
    final Color backgroundColor = _getBackgroundColor();
    final Color textColor = _getTextColor();

    Widget button = Container(
      height: height,
      constraints: fullWidth ? const BoxConstraints(minWidth: double.infinity) : null,
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(
          horizontal: size == ButtonSize.small ? AppDimensions.spacingL : AppDimensions.spacingXL,
        ),
        color: type == ButtonType.primary ? backgroundColor : null,
        disabledColor: AppColors.secondaryGrey.withValues(alpha: 0.5),
        onPressed: (disabled || isLoading) ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: isLoading
            ? CupertinoActivityIndicator(color: textColor, radius: 10)
            : Text(text, style: textStyle.copyWith(color: textColor)),
      ),
    );

    // 如果是次要按钮或文字按钮，添加边框或特殊样式
    if (type == ButtonType.secondary) {
      button = Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: button,
      );
    }

    return button;
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightS;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case ButtonSize.large:
        return AppDimensions.buttonHeightL;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall;
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case ButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  Color _getBackgroundColor() {
    if (type == ButtonType.primary) {
      return AppColors.primaryColor;
    }
    return CupertinoColors.white;
  }

  Color _getTextColor() {
    switch (type) {
      case ButtonType.primary:
        return AppColors.primaryText;
      case ButtonType.secondary:
      case ButtonType.text:
        return AppColors.primaryText;
    }
  }
}
