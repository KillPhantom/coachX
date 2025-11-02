import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 计划头部信息组件
class PlanHeaderWidget extends StatefulWidget {
  final String planName;
  final ValueChanged<String>? onNameChanged;
  final int totalDays;
  final int totalExercises;
  final int totalSets;

  const PlanHeaderWidget({
    super.key,
    required this.planName,
    this.onNameChanged,
    this.totalDays = 0,
    this.totalExercises = 0,
    this.totalSets = 0,
  });

  @override
  State<PlanHeaderWidget> createState() => _PlanHeaderWidgetState();
}

class _PlanHeaderWidgetState extends State<PlanHeaderWidget> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.planName);
  }

  @override
  void didUpdateWidget(PlanHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在值变化且不是当前输入导致的变化时更新
    if (oldWidget.planName != widget.planName &&
        _nameController.text != widget.planName) {
      _nameController.text = widget.planName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Name Input
          CupertinoTextField(
            placeholder: '计划名称（必填）',
            controller: _nameController,
            onChanged: widget.onNameChanged,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // Plan Overview Stats
          if (widget.totalDays > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStatBadge(
                  context,
                  '${widget.totalDays}',
                  'Days',
                  CupertinoIcons.calendar,
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  context,
                  '${widget.totalExercises}',
                  'Movements',
                  CupertinoIcons.square_stack_3d_up_fill,
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  context,
                  '${widget.totalSets}',
                  'Sets',
                  CupertinoIcons.square_stack_fill,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.footnote.copyWith(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}




