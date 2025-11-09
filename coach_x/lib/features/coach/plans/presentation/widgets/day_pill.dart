import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// Day Pill 组件（横向滚动选择器）
///
/// 通用组件，可用于 Training/Diet/Supplement 计划的 Day 选择
class DayPill extends StatelessWidget {
  final String label;
  final int dayNumber;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DayPill({
    super.key,
    required this.label,
    required this.dayNumber,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AppColors.primaryText) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day Number Badge
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Label
            Text(
              label,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.primaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
