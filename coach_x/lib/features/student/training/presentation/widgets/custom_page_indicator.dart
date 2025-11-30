import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'exercise_tile.dart';

/// 自定义页面指示器
///
/// 显示 ExerciseTile 横向列表 + "1 / 3" 页码 + 左右箭头按钮 + 绿色进度条
class CustomPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int completedCount;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final List<String> exerciseNames;
  final Function(int index)? onExerciseTap;
  final ScrollController? tileScrollController;

  const CustomPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.completedCount,
    this.onPreviousPage,
    this.onNextPage,
    required this.exerciseNames,
    this.onExerciseTap,
    this.tileScrollController,
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
          // ExerciseTile 横向列表
          if (exerciseNames.isNotEmpty) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                controller: tileScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: exerciseNames.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ExerciseTile(
                    name: exerciseNames[index],
                    isSelected: index == currentPage,
                    onTap: () => onExerciseTap?.call(index),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

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
