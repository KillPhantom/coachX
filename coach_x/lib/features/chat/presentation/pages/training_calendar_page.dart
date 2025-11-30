import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_summary_providers.dart';
import 'package:coach_x/features/chat/presentation/providers/training_calendar_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/summary_widgets/summary_header.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class TrainingCalendarPage extends ConsumerStatefulWidget {
  final String studentId;
  final DateTime? initialDate;

  const TrainingCalendarPage({
    super.key,
    required this.studentId,
    this.initialDate,
  });

  @override
  ConsumerState<TrainingCalendarPage> createState() =>
      _TrainingCalendarPageState();
}

class _TrainingCalendarPageState extends ConsumerState<TrainingCalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    final initial = _normalizeDate(widget.initialDate ?? DateTime.now());
    _focusedDay = initial;
    _selectedDay = initial;
    _updateRange(initial);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final params = _currentParameters;
    final calendarAsync = ref.watch(trainingCalendarProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.trainingCalendarTitle,
          style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: calendarAsync.when(
          data: (events) => _buildContent(context, events),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              l10n.errorOccurred,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<DateTime, List<DailyTrainingModel>> events,
  ) {
    final statsAsync = ref.watch(studentStatsProvider(widget.studentId));

    return Column(
      children: [
        statsAsync.when(
          data: (stats) => SummaryHeader(
            recordDaysCount: stats['recordDays'] ?? 0,
            coachReviewsCount: stats['coachReviews'] ?? 0,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        _buildCalendar(events),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCalendar(Map<DateTime, List<DailyTrainingModel>> events) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: TableCalendar<DailyTrainingModel>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) =>
              events[_normalizeDate(day)] ?? const <DailyTrainingModel>[],
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: AppTextStyles.title3,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AppColors.textPrimary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: AppTextStyles.body,
            weekendTextStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            final normalized = _normalizeDate(selectedDay);
            final dayRecords = events[normalized];

            setState(() {
              _selectedDay = normalized;
              _focusedDay = _normalizeDate(focusedDay);
            });

            if (dayRecords != null && dayRecords.isNotEmpty) {
              final latestRecord = dayRecords.last;
              context.push(
                RouteNames.getDailyTrainingSummaryRoute(latestRecord.id),
              );
            }
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = _normalizeDate(focusedDay);
              _updateRange(_focusedDay);
            });
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) => _buildDayCell(day, events),
            todayBuilder: (context, day, _) =>
                _buildDayCell(day, events, isToday: true),
            selectedBuilder: (context, day, _) =>
                _buildDayCell(day, events, isSelected: true),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, List<DailyTrainingModel>> events, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final normalized = _normalizeDate(day);
    final hasRecord = (events[normalized]?.isNotEmpty ?? false);
    final backgroundColor = isSelected
        ? AppColors.successGreen
        : hasRecord
        ? AppColors.successGreenLight
        : AppColors.backgroundWhite;

    final textColor = isSelected
        ? AppColors.textPrimary
        : hasRecord
        ? AppColors.primaryDark
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? AppColors.secondaryBlue : AppColors.dividerLight,
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: hasRecord
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: AppTextStyles.body.copyWith(
            color: textColor,
            fontWeight: hasRecord ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _updateRange(DateTime focus) {
    _rangeStart = DateTime(focus.year, focus.month, 1);
    _rangeEnd = DateTime(focus.year, focus.month + 1, 0);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  TrainingCalendarRequest get _currentParameters => TrainingCalendarRequest(
    studentId: widget.studentId,
    startDate: _rangeStart,
    endDate: _rangeEnd,
  );
}
