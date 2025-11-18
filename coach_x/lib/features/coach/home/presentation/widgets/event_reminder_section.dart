import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/cupertino_card.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import '../providers/coach_home_providers.dart';
import 'event_reminder_item.dart';

/// Event Reminder区域组件
///
/// 显示即将到来的事件提醒列表
class EventReminderSection extends ConsumerWidget {
  const EventReminderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(eventRemindersProvider);

    return CupertinoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.upcomingScheduleTitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.spacingL),
          remindersAsync.when(
            data: (reminders) {
              if (reminders.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  for (int i = 0; i < reminders.length; i++) ...[
                    EventReminderItem(reminder: reminders[i]),
                    if (i < reminders.length - 1)
                      const SizedBox(height: AppDimensions.spacingM),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacingXXL),
                child: LoadingIndicator(),
              ),
            ),
            error: (error, stack) => ErrorView(
              error: error.toString(),
              onRetry: () => ref.invalidate(eventRemindersProvider),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXXL),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 48.0,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.noUpcomingEvents,
              style: AppTextStyles.subhead.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
