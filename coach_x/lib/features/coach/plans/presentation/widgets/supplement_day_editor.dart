import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/supplement_timing_card.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';

/// 补剂日编辑器
class SupplementDayEditor extends StatefulWidget {
  final SupplementDay day;
  final int dayIndex;
  final Function(int)? onDeleteTiming;
  final Function(int, String)? onTimingNameChanged;
  final Function(int, String)? onTimingNoteChanged;
  final Function(int)? onAddSupplement;
  final Function(int, int)? onDeleteSupplement;
  final Function(int, int, String)? onSupplementNameChanged;
  final Function(int, int, String)? onSupplementAmountChanged;
  final VoidCallback? onAddTiming;

  const SupplementDayEditor({
    super.key,
    required this.day,
    required this.dayIndex,
    this.onDeleteTiming,
    this.onTimingNameChanged,
    this.onTimingNoteChanged,
    this.onAddSupplement,
    this.onDeleteSupplement,
    this.onSupplementNameChanged,
    this.onSupplementAmountChanged,
    this.onAddTiming,
  });

  @override
  State<SupplementDayEditor> createState() => _SupplementDayEditorState();
}

class _SupplementDayEditorState extends State<SupplementDayEditor> {
  @override
  Widget build(BuildContext context) {
    if (widget.day.timings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              if (widget.onAddTiming != null)
                CupertinoButton(
                  onPressed: widget.onAddTiming,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.add,
                          color: CupertinoColors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '添加第一个时间段',
                          style: AppTextStyles.body.copyWith(
                            color: CupertinoColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return DismissKeyboardOnScroll(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timing Cards
          ...widget.day.timings.asMap().entries.map((entry) {
            final timingIndex = entry.key;
            final timing = entry.value;

            return SupplementTimingCard(
              timing: timing,
              dayIndex: widget.dayIndex,
              timingIndex: timingIndex,
              isExpanded: true,
              onDelete: () => widget.onDeleteTiming?.call(timingIndex),
              onNameChanged: (name) =>
                  widget.onTimingNameChanged?.call(timingIndex, name),
              onNoteChanged: (note) =>
                  widget.onTimingNoteChanged?.call(timingIndex, note),
              onAddSupplement: () => widget.onAddSupplement?.call(timingIndex),
              onDeleteSupplement: (supplementIndex) =>
                  widget.onDeleteSupplement?.call(timingIndex, supplementIndex),
              onSupplementNameChanged: (supplementIndex, name) => widget
                  .onSupplementNameChanged
                  ?.call(timingIndex, supplementIndex, name),
              onSupplementAmountChanged: (supplementIndex, amount) => widget
                  .onSupplementAmountChanged
                  ?.call(timingIndex, supplementIndex, amount),
            );
          }),

          const SizedBox(height: 16),

          // Add Timing Button
          if (widget.onAddTiming != null)
            Center(
              child: CupertinoButton(
                onPressed: widget.onAddTiming,
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '添加时间段',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
