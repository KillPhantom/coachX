import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../data/models/event_reminder_model.dart';

/// Event Reminder单项组件
///
/// 用于显示单个事件提醒
class EventReminderItem extends StatelessWidget {
  /// Event Reminder数据
  final EventReminderModel reminder;

  const EventReminderItem({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(reminder.type.icon, color: AppColors.textSecondary, size: 20.0),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(child: Text(reminder.title, style: AppTextStyles.callout)),
      ],
    );
  }
}
