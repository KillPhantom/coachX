import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/providers/feedback_providers.dart';

/// 训练反馈日期筛选器
///
/// 提供日期范围筛选功能：
/// - 开始日期选择
/// - 结束日期选择
/// - 清除筛选按钮
class FeedbackDateFilter extends ConsumerWidget {
  const FeedbackDateFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(feedbackDateRangeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 开始日期按钮
          Expanded(
            child: _DateButton(
              label: 'Start Date',
              date: dateRange?.start,
              onTap: () => _selectStartDate(context, ref, dateRange),
            ),
          ),
          const SizedBox(width: 12),
          // 结束日期按钮
          Expanded(
            child: _DateButton(
              label: 'End Date',
              date: dateRange?.end,
              onTap: () => _selectEndDate(context, ref, dateRange),
            ),
          ),
          const SizedBox(width: 12),
          // 清除按钮
          if (dateRange != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(feedbackDateRangeProvider.notifier).state = null;
              },
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// 选择开始日期
  void _selectStartDate(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? currentRange,
  ) {
    final initialDate = currentRange?.start ?? DateTime.now();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDate,
            mode: CupertinoDatePickerMode.date,
            use24hFormat: true,
            onDateTimeChanged: (DateTime newDate) {
              final endDate = currentRange?.end ?? newDate;
              ref
                  .read(feedbackDateRangeProvider.notifier)
                  .state = DateTimeRange(
                start: newDate,
                end: endDate.isBefore(newDate) ? newDate : endDate,
              );
            },
          ),
        ),
      ),
    );
  }

  /// 选择结束日期
  void _selectEndDate(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? currentRange,
  ) {
    final initialDate = currentRange?.end ?? DateTime.now();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDate,
            mode: CupertinoDatePickerMode.date,
            use24hFormat: true,
            onDateTimeChanged: (DateTime newDate) {
              final startDate = currentRange?.start ?? newDate;
              ref
                  .read(feedbackDateRangeProvider.notifier)
                  .state = DateTimeRange(
                start: startDate.isAfter(newDate) ? newDate : startDate,
                end: newDate,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 日期按钮组件
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.borderColor,
            width: date != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMM d, yyyy').format(date!) : 'Select',
              style: AppTextStyles.footnote.copyWith(
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
