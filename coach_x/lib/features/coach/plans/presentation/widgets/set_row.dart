import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// Set 修改类型
enum SetChangeType {
  modified, // 修改（显示 before │ after 对比）
  added, // 新增（绿色边框）
  deleted, // 删除（红色背景 + 删除线）
}

/// 训练组行组件
class SetRow extends StatefulWidget {
  final TrainingSet set;
  final int index;
  final ValueChanged<String>? onRepsChanged;
  final ValueChanged<String>? onWeightChanged;
  final VoidCallback? onDelete;

  // Review Mode 参数
  final TrainingSet? beforeSet; // 修改前的值（可选）
  final SetChangeType? changeType; // 修改类型
  final bool isInReviewMode; // 是否处于 Review Mode

  const SetRow({
    super.key,
    required this.set,
    required this.index,
    this.onRepsChanged,
    this.onWeightChanged,
    this.onDelete,
    this.beforeSet,
    this.changeType,
    this.isInReviewMode = false,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.set.reps);
    _weightController = TextEditingController(text: widget.set.weight);
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.reps != widget.set.reps &&
        _repsController.text != widget.set.reps) {
      _repsController.text = widget.set.reps;
    }
    if (oldWidget.set.weight != widget.set.weight &&
        _weightController.text != widget.set.weight) {
      _weightController.text = widget.set.weight;
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Review Mode: 根据 changeType 显示不同的布局
    if (widget.isInReviewMode && widget.changeType != null) {
      switch (widget.changeType!) {
        case SetChangeType.modified:
          return _buildModifiedLayout(context);
        case SetChangeType.added:
          return _buildAddedLayout(context);
        case SetChangeType.deleted:
          return _buildDeletedLayout(context);
      }
    }

    // 正常模式：可编辑布局
    return _buildNormalLayout(context);
  }

  /// 正常模式布局（可编辑）
  Widget _buildNormalLayout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Set Number
          _buildSetNumber(context),
          const SizedBox(width: 8),

          // Reps Input
          Expanded(
            child: _buildCompactInput(
              context,
              controller: _repsController,
              placeholder: '10',
              onChanged: widget.onRepsChanged,
              editable: true,
            ),
          ),

          const SizedBox(width: 8),

          // Weight Input
          Expanded(
            child: _buildCompactInput(
              context,
              controller: _weightController,
              placeholder: '60kg',
              onChanged: widget.onWeightChanged,
              editable: true,
            ),
          ),

          const SizedBox(width: 8),

          // Delete Button
          if (widget.onDelete != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: widget.onDelete,
              child: Icon(
                CupertinoIcons.minus_circle_fill,
                color: CupertinoColors.systemRed.resolveFrom(context),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactInput(
    BuildContext context, {
    required TextEditingController controller,
    required String placeholder,
    required ValueChanged<String>? onChanged,
    required bool editable,
  }) {
    return SizedBox(
      height: 32,
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        onChanged: editable ? onChanged : null,
        enabled: editable,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(6),
        ),
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w500,
        ),
        placeholderStyle: AppTextStyles.body.copyWith(
          color: CupertinoColors.placeholderText,
        ),
      ),
    );
  }

  /// 修改模式布局（before │ after 对比）
  Widget _buildModifiedLayout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Set Number
          _buildSetNumber(context),
          const SizedBox(width: 6),

          // Before (左侧，红色删除线)
          Expanded(child: _buildBeforeDisplay(context)),

          // 分隔线
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: CupertinoColors.separator.resolveFrom(context),
          ),

          // After (右侧，绿色)
          Expanded(child: _buildAfterDisplay(context)),
        ],
      ),
    );
  }

  /// 新增模式布局（绿色边框）
  Widget _buildAddedLayout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Row(
        children: [
          // Set Number
          _buildSetNumber(context, color: AppColors.success),
          const SizedBox(width: 6),

          // Display (only after)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '次数',
                        style: AppTextStyles.tabLabel.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.set.reps,
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '重量',
                        style: AppTextStyles.tabLabel.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.set.weight,
                        style: AppTextStyles.caption1.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // 新增标记
          Icon(
            CupertinoIcons.add_circled_solid,
            color: AppColors.success,
            size: 12,
          ),
        ],
      ),
    );
  }

  /// 删除模式布局（红色背景 + 删除线）
  Widget _buildDeletedLayout(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: CupertinoColors.systemRed.resolveFrom(context),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Set Number
          _buildSetNumber(context, color: CupertinoColors.systemRed),
          const SizedBox(width: 6),

          // Display (deleted, with strikethrough)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '次数',
                        style: AppTextStyles.tabLabel.copyWith(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.set.reps,
                        style: AppTextStyles.caption1.copyWith(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                          decoration: TextDecoration.lineThrough,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '重量',
                        style: AppTextStyles.tabLabel.copyWith(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.set.weight,
                        style: AppTextStyles.caption1.copyWith(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                          decoration: TextDecoration.lineThrough,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // 删除标记
          Icon(
            CupertinoIcons.xmark_circle_fill,
            color: CupertinoColors.systemRed.resolveFrom(context),
            size: 12,
          ),
        ],
      ),
    );
  }

  // ==================== 辅助组件构建方法 ====================

  /// Set 编号
  Widget _buildSetNumber(BuildContext context, {Color? color}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        '${widget.index + 1}',
        style: AppTextStyles.caption2.copyWith(
          color: color ?? AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Reps 输入框
  Widget _buildRepsInput(BuildContext context, {required bool editable}) {
    return CupertinoTextField(
      placeholder: '10',
      controller: _repsController,
      onChanged: editable ? widget.onRepsChanged : null,
      enabled: editable,
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      style: AppTextStyles.caption1,
    );
  }

  /// Weight 输入框
  Widget _buildWeightInput(BuildContext context, {required bool editable}) {
    return CupertinoTextField(
      placeholder: '60kg',
      controller: _weightController,
      onChanged: editable ? widget.onWeightChanged : null,
      enabled: editable,
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 0.5,
        ),
      ),
      style: AppTextStyles.caption1,
    );
  }

  /// Before 显示（左侧，红色删除线）
  Widget _buildBeforeDisplay(BuildContext context) {
    final before = widget.beforeSet ?? widget.set;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '次数',
                style: AppTextStyles.tabLabel.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                before.reps,
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  decoration: TextDecoration.lineThrough,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '重量',
                style: AppTextStyles.tabLabel.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                before.weight,
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  decoration: TextDecoration.lineThrough,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// After 显示（右侧，绿色）
  Widget _buildAfterDisplay(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '次数',
                style: AppTextStyles.tabLabel.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.set.reps,
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '重量',
                style: AppTextStyles.tabLabel.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.set.weight,
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
