import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 日期选择器Pills组件
///
/// 横向滚动的日期pill列表，支持选择不同天的训练计划
class DaySelectorPills extends StatelessWidget {
  final int totalDays;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const DaySelectorPills({
    super.key,
    required this.totalDays,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = day == selectedDay;

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              constraints: const BoxConstraints(minWidth: 60),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  l10n.dayNumber(day),
                  style: AppTextStyles.callout.copyWith(
                    color: isSelected
                        ? AppColors.primaryText
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
