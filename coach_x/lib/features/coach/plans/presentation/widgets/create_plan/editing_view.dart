import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:coach_x/features/coach/plans/data/models/create_training_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/data/models/suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_notifier.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/plan_header_widget.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/day_pill_scroll_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/training_day_editor.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/exercise_card.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/set_row.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 创建训练计划 - 编辑器视图
///
/// 显示训练日编辑器，包括：
/// - PlanHeaderWidget
/// - Day Pills
/// - Content Area (TrainingDayEditor)
/// - AI 思考面板
/// - Save Button
class EditingView extends ConsumerStatefulWidget {
  final CreateTrainingPlanState state;
  final CreateTrainingPlanNotifier notifier;
  final int? selectedDayIndex;
  final Function(int) onDayIndexChanged;
  final VoidCallback onAddDay;
  final Function(int) onDeleteDay;
  final Function(int, int) onDeleteExercise;
  final Function(int, int) onAddSet;
  final Function(int, int, int) onDeleteSet;
  final VoidCallback onSave;
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onRejectSuggestion;
  final VoidCallback? onAcceptAll;
  final VoidCallback? onRejectAll;

  const EditingView({
    super.key,
    required this.state,
    required this.notifier,
    required this.selectedDayIndex,
    required this.onDayIndexChanged,
    required this.onAddDay,
    required this.onDeleteDay,
    required this.onDeleteExercise,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onSave,
    this.onAcceptSuggestion,
    this.onRejectSuggestion,
    this.onAcceptAll,
    this.onRejectAll,
  });

  @override
  ConsumerState<EditingView> createState() => _EditingViewState();
}

class _EditingViewState extends ConsumerState<EditingView> {
  final ScrollController _exercisesScrollController = ScrollController();
  final Map<String, GlobalKey> _exerciseKeys = {};

  @override
  void dispose() {
    _exercisesScrollController.dispose();
    super.dispose();
  }

  /// 显示 Day 操作菜单（长按触发）
  void _showDayOptionsMenu(BuildContext context, int dayIndex, String dayName) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext popupContext) => CupertinoActionSheet(
        title: Text(dayName),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(popupContext);
              widget.onDeleteDay(dayIndex);
            },
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 滚动到高亮的 exercise card
  void _scrollToHighlightedCard(int dayIndex, int? exerciseIndex) {
    if (exerciseIndex == null) return;

    final exerciseKey = '${dayIndex}_$exerciseIndex';
    final globalKey = _exerciseKeys[exerciseKey];

    if (globalKey?.currentContext != null) {
      // 使用 Scrollable.ensureVisible 自动滚动到目标 widget
      Scrollable.ensureVisible(
        globalKey!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // 将卡片滚动到屏幕 20% 的位置（靠上）
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReviewMode = ref.watch(isReviewModeProvider);
    final reviewState = ref.watch(suggestionReviewNotifierProvider);

    // 监听 Review Mode 高亮变化，自动切换 day 并滚动到目标卡片
    ref.listen<SuggestionReviewState?>(suggestionReviewNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      // 当有新的 currentChange 时，自动切换 day 并滚动
      if (next != null && next.currentChange != null && isReviewMode) {
        final targetDayIndex = next.currentChange!.dayIndex;

        // 如果目标 day 不同，先切换到目标 day
        if (widget.selectedDayIndex != targetDayIndex) {
          widget.onDayIndexChanged(targetDayIndex);
        }

        // 延迟执行，等待 UI 更新完成后滚动
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToHighlightedCard(
            next.currentChange!.dayIndex,
            next.currentChange!.exerciseIndex,
          );
        });
      }
    });

    return Column(
      children: [
        // Plan Header
        PlanHeaderWidget(
          planName: widget.state.planName,
          onNameChanged: widget.notifier.updatePlanName,
          totalDays: widget.state.totalDays,
          totalExercises: widget.state.totalExercises,
          totalSets: widget.state.totalSets,
        ),

        // Horizontal Day Pills Scroll View
        DayPillScrollView(
          dayItems: widget.state.days
              .map((day) => (name: day.name, day: day.day))
              .toList(),
          selectedDayIndex: widget.selectedDayIndex,
          onDayTap: (index) => widget.onDayIndexChanged(index),
          onDayLongPress: (index, dayName) => _showDayOptionsMenu(context, index, dayName),
          onAddDay: widget.onAddDay,
          addDayLabel: l10n.addDay,
        ),

        // Content Area
        Expanded(
          child:
              widget.selectedDayIndex != null &&
                  widget.selectedDayIndex! < widget.state.days.length
              ? DismissKeyboardOnScroll(
                  child: TrainingDayEditor(
                    dayIndex: widget.selectedDayIndex!,
                    scrollController: _exercisesScrollController,
                    exerciseCards: _buildExercisesList(
                      context,
                      widget.selectedDayIndex!,
                      widget.state.days[widget.selectedDayIndex!].exercises,
                      isReviewMode: isReviewMode,
                      reviewState: reviewState,
                    ),
                    onReorder: (oldIndex, newIndex) {
                      widget.notifier.reorderExercise(
                        widget.selectedDayIndex!,
                        oldIndex,
                        newIndex,
                      );
                    },
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.calendar_badge_plus,
                        size: 64,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.selectDayOrAddNew,
                        style: AppTextStyles.callout.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // AI 思考面板（仅在生成时显示）
        if (widget.state.aiStatus == AIGenerationStatus.generating)
          _buildAIThinkingPanel(context),

        // Save Button (Fixed at bottom)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            border: Border(
              top: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save Button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.state.canSave && !widget.state.isLoading
                      ? widget.onSave
                      : null,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      border  : widget.state.canSave && !widget.state.isLoading
                          ? Border.all(color: AppColors.primary)
                          : Border.all(color: CupertinoColors.quaternarySystemFill.resolveFrom(
                              context,
                            )),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: widget.state.isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : Text(
                            l10n.savePlan,
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: widget.state.canSave
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.quaternaryLabel.resolveFrom(
                                      context,
                                    ),
                            ),
                          ),
                  ),
                ),

                // Validation Errors
                if (widget.state.validationErrors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.state.validationErrors.first,
                      style: AppTextStyles.footnote.copyWith(
                        color: CupertinoColors.systemRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIThinkingPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和加载动画
          Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 12),
              Text(
                l10n.aiGeneratingPlan,
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),

          // 当前进度
          if (widget.state.currentDayNumber != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.generatingDay(widget.state.currentDayNumber!),
              style: AppTextStyles.footnote.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),

            // 当前天的动作进度
            if (widget.state.currentDayInProgress != null &&
                widget.state.currentDayInProgress!.exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.addedExercises(
                  widget.state.currentDayInProgress!.exercises.length,
                ),
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),

              // 显示最新添加的动作（最多显示最后3个）
              ...widget.state.currentDayInProgress!.exercises.reversed
                  .take(3)
                  .map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: AppTextStyles.caption1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],

          // 已完成的训练日列表
          if (widget.state.days.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.completedDays(widget.state.days.length),
              style: AppTextStyles.footnote.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildExercisesList(
    BuildContext context,
    int dayIndex,
    List<Exercise> exercises, {
    required bool isReviewMode,
    required SuggestionReviewState? reviewState,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final currentChange = reviewState?.currentChange;

    if (exercises.isEmpty) {
      return [
        Padding(
          key: const ValueKey('empty_placeholder'),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            l10n.noExercisesYet,
            style: AppTextStyles.footnote.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        )
      ];
    }

    return exercises.asMap().entries.map((entry) {
      final exerciseIndex = entry.key;
      final exercise = entry.value;

      final hasActiveSuggestion =
          isReviewMode &&
          currentChange != null &&
          currentChange.dayIndex == dayIndex &&
          currentChange.exerciseIndex == exerciseIndex;

      final exerciseKey = '${dayIndex}_$exerciseIndex';
      _exerciseKeys.putIfAbsent(exerciseKey, () => GlobalKey());

      return ExerciseCard(
        key: _exerciseKeys[exerciseKey],
        exercise: exercise,
        index: exerciseIndex,
        initiallyExpanded: true,
        onTap: null,
        onDelete: () => widget.onDeleteExercise(dayIndex, exerciseIndex),
        activeSuggestion: hasActiveSuggestion ? currentChange : null,
        isHighlighted: hasActiveSuggestion,
        onAcceptSuggestion: hasActiveSuggestion
            ? widget.onAcceptSuggestion
            : null,
        onRejectSuggestion: hasActiveSuggestion
            ? widget.onRejectSuggestion
            : null,
        onAcceptAll: hasActiveSuggestion ? widget.onAcceptAll : null,
        onRejectAll: hasActiveSuggestion ? widget.onRejectAll : null,
        suggestionProgress: reviewState?.progressText,
        onAddSet: () => widget.onAddSet(dayIndex, exerciseIndex),
        setsWidget: _buildSetsList(
          context,
          dayIndex,
          exerciseIndex,
          exercise.sets,
        ),
      );
    }).toList();
  }

  Widget _buildSetsList(
    BuildContext context,
    int dayIndex,
    int exerciseIndex,
    List<TrainingSet> sets,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (sets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.noSetsYet,
          style: AppTextStyles.caption1.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: sets.asMap().entries.map((entry) {
        final setIndex = entry.key;
        final set = entry.value;

        return SetRow(
          set: set,
          index: setIndex,
          onWeightChanged: (value) {
            final updatedSet = set.copyWith(weight: value);
            widget.notifier.updateSet(
              dayIndex,
              exerciseIndex,
              setIndex,
              updatedSet,
            );
          },
          onRepsChanged: (value) {
            final updatedSet = set.copyWith(reps: value);
            widget.notifier.updateSet(
              dayIndex,
              exerciseIndex,
              setIndex,
              updatedSet,
            );
          },
          onDelete: () => widget.onDeleteSet(
            dayIndex,
            exerciseIndex,
            setIndex,
          ),
        );
      }).toList(),
    );
  }
}
