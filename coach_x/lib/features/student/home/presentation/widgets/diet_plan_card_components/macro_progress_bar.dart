import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 横向进度条组件
///
/// 显示宏营养素的进度条
class MacroProgressBar extends StatelessWidget {
  final String label;
  final double actualValue;
  final int targetValue;
  final double progress;
  final Color color;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.actualValue,
    required this.targetValue,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 计算颜色 (3色逻辑)
    Color progressColor;
    if (progress >= 0.95 && progress <= 1.05) {
      progressColor = AppColors.successGreen;
    } else if (progress > 1.05) {
      progressColor = AppColors.errorRed;
    } else {
      progressColor = color;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签和数值
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${actualValue.toInt()}/${targetValue}g',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // 进度条
        SizedBox(
          height: 6,
          child: Stack(
            children: [
              // 背景
              Container(
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // 进度
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
