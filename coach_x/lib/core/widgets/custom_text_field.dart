import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// 自定义文本输入框组件
class CustomTextField extends StatefulWidget {
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
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  /// 当前错误信息
  String? _errorText;

  /// 是否已触发过验证
  bool _hasBeenValidated = false;

  @override
  void initState() {
    super.initState();
    // 监听文本变化
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // 移除监听
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  /// 文本变化时的处理
  void _onTextChanged() {
    // 只有在已经验证过之后才自动重新验证
    if (_hasBeenValidated && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  /// 公开的验证方法，供外部调用
  bool validate() {
    if (widget.validator == null) {
      return true;
    }

    setState(() {
      _hasBeenValidated = true;
      _errorText = widget.validator!(widget.controller.text);
    });

    return _errorText == null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.backgroundWhite
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.dividerLight, width: 1.0),
          ),
          child: CupertinoTextField(
            controller: widget.controller,
            placeholder: widget.placeholder,
            obscureText: widget.isPassword,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            textAlign: widget.textAlign,
            onEditingComplete: widget.onEditingComplete,
            onChanged: widget.onChanged,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingM,
              horizontal: AppDimensions.spacingL,
            ),
            prefix: widget.prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.spacingL,
                    ),
                    child: widget.prefix,
                  )
                : null,
            suffix: widget.suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      right: AppDimensions.spacingL,
                    ),
                    child: widget.suffix,
                  )
                : null,
            style: AppTextStyles.body,
            placeholderStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            decoration: const BoxDecoration(),
          ),
        ),
        if (_errorText != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.spacingS,
              left: AppDimensions.spacingM,
            ),
            child: Text(
              _errorText!,
              style: AppTextStyles.caption1.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ],
    );
  }
}
