import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 训练动作 Tile (用于快速导航)
///
/// 显示动作名称,支持选中状态高亮 (边框),点击跳转到对应的 exercise
class ExerciseTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const ExerciseTile({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: isSelected
              ? Border.all(color: AppColors.primaryAction, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            name,
            style: AppTextStyles.callout.copyWith(
              color: isSelected
                  ? AppColors.primaryText
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
