import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 信息行组件
///
/// 显示左侧标签和右侧数值的行
class InfoRow extends StatelessWidget {
  /// 左侧标签文字
  final String label;

  /// 右侧数值文字
  final String value;

  /// 是否显示底部分隔线
  final bool showDivider;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        if (showDivider) Container(height: 1, color: AppColors.dividerLight),
      ],
    );
  }
}
