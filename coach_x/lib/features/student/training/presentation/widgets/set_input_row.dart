import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';

/// Set 输入行组件
///
/// 显示单个 Set 的 reps 和 weight 输入框
/// 支持编辑和完成状态切换
class SetInputRow extends StatefulWidget {
  final TrainingSet set;
  final int setNumber;
  final Function(String reps, String weight) onComplete;
  final VoidCallback onToggleEdit;

  const SetInputRow({
    super.key,
    required this.set,
    required this.setNumber,
    required this.onComplete,
    required this.onToggleEdit,
  });

  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    // 初始化 Controller，如果已完成则填充文本，否则为空（使用 placeholder）
    _repsController = TextEditingController(
      text: widget.set.completed ? widget.set.reps : '',
    );
    _weightController = TextEditingController(
      text: widget.set.completed ? widget.set.weight : '',
    );
  }

  @override
  void didUpdateWidget(SetInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 Set 刚被标记为完成（快捷完成），填充文本
    if (widget.set.completed && !oldWidget.set.completed) {
      _repsController.text = widget.set.reps;
      _weightController.text = widget.set.weight;
    }
    // 如果从完成变回未完成，清空文本
    if (!widget.set.completed && oldWidget.set.completed) {
      _repsController.text = '';
      _weightController.text = '';
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// 处理完成按钮点击
  void _handleComplete() {
    widget.onComplete(_repsController.text, _weightController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = widget.set.completed;

    return GestureDetector(
      onTap: isCompleted ? widget.onToggleEdit : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: isCompleted
                ? AppColors.primaryColor.withValues(alpha: 0.3)
                : AppColors.dividerLight,
          ),
        ),
        child: Row(
          children: [
            // Set 编号
            SizedBox(
              width: 60,
              child: Text(
                '${l10n.set} ${widget.setNumber}',
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.spacingS),

            // Reps 输入框或只读文本
            Expanded(
              child: isCompleted
                  ? Text(
                      '${widget.set.reps} ${l10n.reps}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    )
                  : _buildInputField(
                      controller: _repsController,
                      placeholder: widget.set.reps.isEmpty
                          ? '10'
                          : widget.set.reps,
                      suffix: l10n.reps,
                      onChanged: (value) {
                        // 仅更新本地 controller，不触发父组件更新
                      },
                    ),
            ),

            const SizedBox(width: AppDimensions.spacingS),

            // "x" 分隔符
            Text(
              'x',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: AppDimensions.spacingS),

            // Weight 输入框或只读文本
            Expanded(
              child: isCompleted
                  ? Text(
                      widget.set.weight,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    )
                  : _buildWeightInputField(
                      controller: _weightController,
                      placeholder: widget.set.weight.isEmpty
                          ? l10n.weightPlaceholder
                          : widget.set.weight,
                      onChanged: (value) {
                        // 仅更新本地 controller，不触发父组件更新
                      },
                    ),
            ),

            const SizedBox(width: AppDimensions.spacingS),

            // Checkmark Button（未完成显示灰色圆圈，已完成显示绿色 checkmark）
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: isCompleted ? widget.onToggleEdit : _handleComplete, minimumSize: Size(24, 24),
              child: Icon(
                isCompleted
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: isCompleted
                    ? AppColors.successGreen
                    : AppColors.dividerMedium,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建输入框
  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required String suffix,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.callout,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dividerLight),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          suffix,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建 Weight 输入框（无 suffix，支持文本输入）
  Widget _buildWeightInputField({
    required TextEditingController controller,
    required String placeholder,
    required Function(String) onChanged,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      maxLength: 10,
      style: AppTextStyles.callout,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      onChanged: onChanged,
    );
  }
}
