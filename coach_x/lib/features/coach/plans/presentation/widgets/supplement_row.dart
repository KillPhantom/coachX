import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 补剂行组件
class SupplementRow extends StatefulWidget {
  final Supplement supplement;
  final int index;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onAmountChanged;
  final VoidCallback? onDelete;

  const SupplementRow({
    super.key,
    required this.supplement,
    required this.index,
    this.onNameChanged,
    this.onAmountChanged,
    this.onDelete,
  });

  @override
  State<SupplementRow> createState() => _SupplementRowState();
}

class _SupplementRowState extends State<SupplementRow> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplement.name);
    _amountController = TextEditingController(text: widget.supplement.amount);
  }

  @override
  void didUpdateWidget(SupplementRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supplement.name != widget.supplement.name &&
        _nameController.text != widget.supplement.name) {
      _nameController.text = widget.supplement.name;
    }
    if (oldWidget.supplement.amount != widget.supplement.amount &&
        _amountController.text != widget.supplement.amount) {
      _amountController.text = widget.supplement.amount;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 补剂名称输入框
          Expanded(
            flex: 3,
            child: CupertinoTextField(
              controller: _nameController,
              placeholder: '补剂名称',
              onChanged: widget.onNameChanged,
              style: AppTextStyles.footnote,
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

          const SizedBox(width: 8),

          // 用量输入框
          Expanded(
            flex: 2,
            child: CupertinoTextField(
              controller: _amountController,
              placeholder: '用量',
              onChanged: widget.onAmountChanged,
              style: AppTextStyles.footnote,
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

          const SizedBox(width: 8),

          // 删除按钮
          if (widget.onDelete != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: widget.onDelete,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.systemRed.resolveFrom(context),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
