import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 自定义页面指示器
///
/// 显示 "1 / 3" 页码 + 左右箭头按钮 + 绿色进度条
class CustomPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int completedCount;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const CustomPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.completedCount,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = currentPage > 0;
    final canGoNext = currentPage < totalPages - 1;
    final double progress = totalPages > 0 ? completedCount / totalPages : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Column(
        children: [
          // 箭头导航行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 左箭头
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: canGoPrevious ? onPreviousPage : null,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: canGoPrevious
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  size: 24,
                ),
              ),

              const SizedBox(width: AppDimensions.spacingS),

              // 页码
              Expanded(
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: AppDimensions.spacingS),

              // 右箭头
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: canGoNext ? onNextPage : null,
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: canGoNext
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingS),

          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: SizedBox(
              height: 4.0,
              child: Stack(
                children: [
                  // 背景轨道
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.dividerLight,
                    ),
                  ),
                  // 填充条
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
