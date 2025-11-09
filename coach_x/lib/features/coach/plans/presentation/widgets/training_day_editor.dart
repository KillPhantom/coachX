import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 训练日编辑面板
class TrainingDayEditor extends StatelessWidget {
  final VoidCallback? onAddExercise;
  final Widget? exercisesWidget;

  const TrainingDayEditor({
    super.key,
    this.onAddExercise,
    this.exercisesWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercises Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '动作列表 (Movements)',
                style: AppTextStyles.subhead.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onAddExercise != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: onAddExercise,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        color: AppColors.primaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '添加',
                        style: TextStyle(color: AppColors.primaryText),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Exercises List
          if (exercisesWidget != null) exercisesWidget!,
        ],
      ),
    );
  }
}
