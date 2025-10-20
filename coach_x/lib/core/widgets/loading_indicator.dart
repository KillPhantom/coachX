import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// iOS风格加载指示器
class LoadingIndicator extends StatelessWidget {
  /// 颜色
  final Color? color;

  /// 大小
  final double radius;

  /// 加载文字
  final String? text;

  /// 文字样式
  final TextStyle? textStyle;

  const LoadingIndicator({super.key, this.color, this.radius = 14.0, this.text, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(color: color ?? AppColors.primaryColor, radius: radius),
          if (text != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Text(text!, style: textStyle ?? AppTextStyles.subhead),
          ],
        ],
      ),
    );
  }
}
