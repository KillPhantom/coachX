import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// 自定义文本输入框组件
class CustomTextField extends StatelessWidget {
  /// 控制器
  final TextEditingController controller;

  /// 占位符
  final String placeholder;

  /// 前缀组件
  final Widget? prefix;

  /// 后缀组件
  final Widget? suffix;

  /// 是否为密码输入
  final bool isPassword;

  /// 键盘类型
  final TextInputType keyboardType;

  /// 验证器
  final String? Function(String?)? validator;

  /// 最大行数
  final int maxLines;

  /// 是否启用
  final bool enabled;

  /// 文本对齐
  final TextAlign textAlign;

  /// 输入完成回调
  final VoidCallback? onEditingComplete;

  /// 内容改变回调
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.prefix,
    this.suffix,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.onEditingComplete,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.backgroundWhite
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.dividerLight, width: 1.0),
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: isPassword,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            textAlign: textAlign,
            onEditingComplete: onEditingComplete,
            onChanged: onChanged,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingM,
              horizontal: AppDimensions.spacingL,
            ),
            prefix: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacingL,
                    ),
                    child: prefix,
                  )
                : null,
            suffix: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      right: AppDimensions.spacingL,
                    ),
                    child: suffix,
                  )
                : null,
            style: AppTextStyles.body,
            placeholderStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            decoration: const BoxDecoration(),
          ),
        ),
        if (validator != null) ...[
          Builder(
            builder: (context) {
              final error = validator!(controller.text);
              if (error != null) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: AppDimensions.spacingS,
                    left: AppDimensions.spacingM,
                  ),
                  child: Text(
                    error,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.errorRed,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }
}
