import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 训练反馈日期分组标题
///
/// 显示日期分组标签：
/// - "Today" - 今天
/// - "Yesterday" - 昨天
/// - "October 26" - 具体日期
class FeedbackGroupHeader extends StatelessWidget {
  final String dateLabel;

  const FeedbackGroupHeader({super.key, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        dateLabel,
        style: AppTextStyles.subhead.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
