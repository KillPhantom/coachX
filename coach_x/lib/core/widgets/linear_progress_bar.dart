import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 线性进度条组件
///
/// 用于显示任务进度（0.0-1.0），支持info text显示
class LinearProgressBar extends StatelessWidget {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 进度信息文本（可选，显示在进度条下方）
  final String? infoText;

  /// 进度条高度
  final double height;

  /// 背景颜色
  final Color backgroundColor;

  /// 进度颜色
  final Color progressColor;

  /// 圆角
  final BorderRadius borderRadius;

  const LinearProgressBar({
    super.key,
    required this.progress,
    this.infoText,
    this.height = 8.0,
    this.backgroundColor = AppColors.backgroundSecondary,
    this.progressColor = AppColors.success,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
  });

  @override
  Widget build(BuildContext context) {
    // 确保progress在0.0-1.0范围内
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              widthFactor: clampedProgress,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ),

        // 信息文本（如果提供）
        if (infoText != null && infoText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            infoText!,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
