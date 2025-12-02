import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/day_pill.dart';

/// Horizontal Day Pills Scroll View 组件
///
/// 通用的 Day Pills 横向滚动选择器，用于训练/饮食/补剂计划创建页面
/// 包括 Day Pills 和 Add Day 按钮
class DayPillScrollView extends StatelessWidget {
  /// Day 项目列表（包含 name 和 day 字段）
  final List<({String name, int day})> dayItems;

  /// 当前选中的 day 索引
  final int? selectedDayIndex;

  /// Day pill 点击回调
  final Function(int index) onDayTap;

  /// Day pill 长按回调（可选，用于显示编辑/删除菜单）
  final Function(int index, String dayName)? onDayLongPress;

  /// Add Day 按钮点击回调
  final VoidCallback onAddDay;

  /// Add Day 按钮文本
  final String addDayLabel;

  const DayPillScrollView({
    super.key,
    required this.dayItems,
    required this.selectedDayIndex,
    required this.onDayTap,
    this.onDayLongPress,
    required this.onAddDay,
    required this.addDayLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dayItems.length + 1, // +1 for Add Day button
        itemBuilder: (context, index) {
          if (index == dayItems.length) {
            // Add Day Button
            return GestureDetector(
              onTap: onAddDay,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryText.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      color: AppColors.primaryText,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      addDayLabel,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Day Pill
          final dayItem = dayItems[index];
          return DayPill(
            label: dayItem.name,
            dayNumber: dayItem.day,
            isSelected: selectedDayIndex == index,
            onTap: () => onDayTap(index),
            onLongPress: onDayLongPress != null
                ? () => onDayLongPress!(index, dayItem.name)
                : null,
          );
        },
      ),
    );
  }
}
