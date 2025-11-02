import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_timing.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/supplement_row.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 补剂时间段卡片组件（类似 MealCard）
class SupplementTimingCard extends StatefulWidget {
  final SupplementTiming timing;
  final int dayIndex;
  final int timingIndex;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onNoteChanged;
  final VoidCallback? onAddSupplement;
  final Function(int)? onDeleteSupplement;
  final Function(int, String)? onSupplementNameChanged;
  final Function(int, String)? onSupplementAmountChanged;

  const SupplementTimingCard({
    super.key,
    required this.timing,
    required this.dayIndex,
    required this.timingIndex,
    this.isExpanded = true,
    this.onTap,
    this.onDelete,
    this.onNameChanged,
    this.onNoteChanged,
    this.onAddSupplement,
    this.onDeleteSupplement,
    this.onSupplementNameChanged,
    this.onSupplementAmountChanged,
  });

  @override
  State<SupplementTimingCard> createState() => _SupplementTimingCardState();
}

class _SupplementTimingCardState extends State<SupplementTimingCard> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.timing.name);
    _noteController = TextEditingController(text: widget.timing.note);
  }

  @override
  void didUpdateWidget(covariant SupplementTimingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timing.name != widget.timing.name &&
        _nameController.text != widget.timing.name) {
      _nameController.text = widget.timing.name;
    }
    if (oldWidget.timing.note != widget.timing.note &&
        _noteController.text != widget.timing.note) {
      _noteController.text = widget.timing.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 时间段名称输入框（直接可编辑）
                        Expanded(
                          child: CupertinoTextField(
                            controller: _nameController,
                            placeholder: '例如：早餐前、训练后、睡前',
                            onChanged: widget.onNameChanged,
                            style: AppTextStyles.callout.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6.resolveFrom(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 8),
                // 补剂数量汇总
                Text(
                  '${widget.timing.supplements.length} 个补剂',
                  style: AppTextStyles.footnote.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Container(
            height: 1,
            color: CupertinoColors.separator.resolveFrom(context),
          ),

          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 补剂列表标题 & 添加按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '补剂列表',
                        style: AppTextStyles.callout.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.onAddSupplement != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: widget.onAddSupplement,
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.add_circled_solid,
                                color: AppColors.primaryText,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '添加补剂',
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 补剂列表
                  if (widget.timing.supplements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '暂无补剂，点击"添加补剂"按钮添加',
                          style: AppTextStyles.footnote.copyWith(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ),
                    )
                  else
                    ...widget.timing.supplements.asMap().entries.map((entry) {
                      final supplementIndex = entry.key;
                      final supplement = entry.value;
                      return SupplementRow(
                        supplement: supplement,
                        index: supplementIndex,
                        onNameChanged: (name) =>
                            widget.onSupplementNameChanged?.call(supplementIndex, name),
                        onAmountChanged: (amount) =>
                            widget.onSupplementAmountChanged?.call(supplementIndex, amount),
                        onDelete: () => widget.onDeleteSupplement?.call(supplementIndex),
                      );
                    }),

                  // 备注区域（仅当补剂列表不为空时显示）
                  if (widget.timing.supplements.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.supplementTimingNote,
                      style: AppTextStyles.footnote.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _noteController,
                      onChanged: widget.onNoteChanged,
                      placeholder: AppLocalizations.of(context)!.supplementTimingNotePlaceholder,
                      minLines: 1,
                      maxLines: 3,
                      style: AppTextStyles.footnote,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),

      // 右上角删除按钮
      if (widget.onDelete != null)
        Positioned(
          top: -6,
          right: -6,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: widget.onDelete,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: CupertinoColors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
