import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

enum StepStatus { pending, loading, completed }

class StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final StepStatus status;
  final String? detailText;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.status,
    this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 15),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    Color backgroundColor;
    Widget iconChild;

    switch (status) {
      case StepStatus.pending:
        backgroundColor = CupertinoColors.systemGrey5;
        iconChild = Text(
          '$stepNumber',
          style: AppTextStyles.subhead.copyWith(
            color: CupertinoColors.systemGrey,
          ),
        );
        break;
      case StepStatus.loading:
        backgroundColor = AppColors.primaryAction;
        iconChild = const CupertinoActivityIndicator(
          color: CupertinoColors.white,
          radius: 10,
        );
        break;
      case StepStatus.completed:
        backgroundColor = CupertinoColors.systemGreen;
        iconChild = const Icon(
          CupertinoIcons.check_mark,
          color: CupertinoColors.white,
          size: 16,
        );
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: iconChild),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subhead),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTextStyles.footnote.copyWith(
            color: CupertinoColors.systemGrey,
          ),
        ),
        if (detailText != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detailText!,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.primaryAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
