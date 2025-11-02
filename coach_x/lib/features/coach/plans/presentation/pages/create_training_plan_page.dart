import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/data/models/create_training_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/edit_conversation_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/plan_header_widget.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/day_pill.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/training_day_editor.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/exercise_card.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/set_row.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/guide_upload_placeholder.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/import_plan_sheet.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/guided_creation_sheet.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/ai_edit_chat_panel.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/review_mode_overlay.dart';

/// 创建/编辑训练计划页面
class CreateTrainingPlanPage extends ConsumerStatefulWidget {
  final String? planId;

  const CreateTrainingPlanPage({super.key, this.planId});

  @override
  ConsumerState<CreateTrainingPlanPage> createState() =>
      _CreateTrainingPlanPageState();
}

class _CreateTrainingPlanPageState
    extends ConsumerState<CreateTrainingPlanPage> {
  // 当前选中的训练日索引
  int? _selectedDayIndex;

  // Auto-scroll 相关
  final ScrollController _exercisesScrollController = ScrollController();
  final Map<String, GlobalKey> _exerciseKeys = {}; // key format: "day_exercise"

  @override
  void initState() {
    super.initState();
    // 加载计划或创建新计划
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

      AppLogger.debug('🔍 接收到的 planId: ${widget.planId}');

      if (widget.planId != null && widget.planId!.isNotEmpty) {
        // 编辑模式：加载现有计划
        AppLogger.info('📝 编辑模式 - 加载计划 ID: ${widget.planId}');
        final success = await notifier.loadPlan(widget.planId!);
        if (success && mounted) {
          final state = ref.read(createTrainingPlanNotifierProvider);
          AppLogger.info('✅ 计划加载成功 - 训练日数量: ${state.days.length}');
          if (state.days.isNotEmpty) {
            setState(() {
              _selectedDayIndex = 0;
            });
          }
        } else if (mounted) {
          // 加载失败，显示错误并返回
          AppLogger.error('❌ 加载计划失败');
          _showErrorDialog(context, '加载计划失败');
        }
      } else {
        // 创建模式：添加第一个训练日作为默认
        AppLogger.info('➕ 创建模式 - 初始化新计划 (planId: ${widget.planId})');
        final state = ref.read(createTrainingPlanNotifierProvider);
        if (state.days.isEmpty) {
          notifier.addDay(name: 'Day 1');
          setState(() {
            _selectedDayIndex = 0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // 清理 ScrollController
    _exercisesScrollController.dispose();

    // 注意：不能在 dispose 中使用 ref，因为 widget 已被标记为销毁
    // 对话历史的清理可以在 notifier 内部的自动清理机制中处理
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTrainingPlanNotifierProvider);
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    // Review Mode 相关
    final isReviewMode = ref.watch(isReviewModeProvider);
    final reviewState = ref.watch(suggestionReviewNotifierProvider);

    // 监听 review state 变化（统一处理滚动和完成）
    ref.listen<SuggestionReviewState?>(suggestionReviewNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      // 处理当前修改变化 - 自动滚动
      final currentChange = next?.currentChange;
      final previousChange = previous?.currentChange;

      if (currentChange != null && currentChange != previousChange) {
        // 1. 切换到正确的训练日标签（如果需要）
        if (currentChange.dayIndex != _selectedDayIndex) {
          setState(() {
            _selectedDayIndex = currentChange.dayIndex;
          });
        }

        // 2. 滚动到对应的 ExerciseCard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final exerciseKey =
              '${currentChange.dayIndex}_${currentChange.exerciseIndex ?? 0}';
          final key = _exerciseKeys[exerciseKey];

          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.2, // 20% from top of viewport
            );
          }
        });
      }

      // 处理 Review 完成
      if (next != null && next.isComplete && isReviewMode) {
        // Review 完成，保存最终计划并退出 Review Mode
        final finalPlan = ref
            .read(suggestionReviewNotifierProvider.notifier)
            .finishReview();
        ref.read(isReviewModeProvider.notifier).state = false;

        // 应用最终计划到当前状态
        if (finalPlan != null) {
          notifier.applyModifiedPlan(finalPlan);
          AppLogger.info('✅ Review Mode 完成，已应用最终计划');
        }
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Text(
          state.isEditMode ? 'Edit Training Plan' : 'Create Training Plan',
          style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _onBack(context, notifier),
          child: const Icon(
            CupertinoIcons.back,
            color: AppColors.primaryAction,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // 根据是否是编辑模式显示不同的功能
            if (state.isEditMode) {
              _showAIEditChatPanel(context, notifier);
            } else {
              _showCreationModeMenu(context, notifier);
            }
          },
          child: const Icon(
            CupertinoIcons.sparkles,
            color: CupertinoColors.activeBlue,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Plan Header
                PlanHeaderWidget(
                  planName: state.planName,
                  onNameChanged: notifier.updatePlanName,
                  totalDays: state.totalDays,
                  totalExercises: state.totalExercises,
                  totalSets: state.totalSets,
                ),

                // Horizontal Day Pills Scroll View
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.days.length + 1, // +1 for Add button
                    itemBuilder: (context, index) {
                      if (index == state.days.length) {
                        // Add Day Button
                        return GestureDetector(
                          onTap: () => _onAddDay(notifier),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryText.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryText.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.add,
                                  color: AppColors.primaryText,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Day',
                                  style: AppTextStyles.footnote.copyWith(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final day = state.days[index];
                      return DayPill(
                        label: day.name,
                        dayNumber: day.day,
                        isSelected: _selectedDayIndex == index,
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = index;
                          });
                        },
                        onLongPress: () => _showDayOptionsMenu(
                          context,
                          notifier,
                          index,
                          day.name,
                        ),
                      );
                    },
                  ),
                ),

                // Content Area
                Expanded(
                  child:
                      _selectedDayIndex != null &&
                          _selectedDayIndex! < state.days.length
                      ? SingleChildScrollView(
                          child: TrainingDayEditor(
                            onAddExercise: () =>
                                _onAddExercise(notifier, _selectedDayIndex!),
                            exercisesWidget: _buildExercisesList(
                              context,
                              notifier,
                              _selectedDayIndex!,
                              state.days[_selectedDayIndex!].exercises,
                              isReviewMode: isReviewMode,
                              reviewState: reviewState,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.calendar_badge_plus,
                                size: 64,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select a day or add a new one',
                                style: AppTextStyles.callout.copyWith(
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // AI 思考面板（仅在生成时显示）
                if (state.aiStatus == AIGenerationStatus.generating)
                  _buildAIThinkingPanel(context, state),

                // Save Button (Fixed at bottom)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
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
                          onPressed: state.canSave && !state.isLoading
                              ? () => _onSave(context, notifier)
                              : null,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: state.canSave && !state.isLoading
                                  ? AppColors.primary
                                  : CupertinoColors.quaternarySystemFill
                                        .resolveFrom(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: state.isLoading
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                : Text(
                                    'Save Plan',
                                    style: TextStyle(
                                      color: state.canSave
                                          ? CupertinoColors.systemGrey
                                          : CupertinoColors.quaternaryLabel
                                                .resolveFrom(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        // Validation Errors
                        if (state.validationErrors.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.validationErrors.first,
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
            ),
          ),

          // Loading Overlay
          if (state.isLoading)
            Container(
              color: CupertinoColors.black.withOpacity(0.3),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 16),
              ),
            ),

          // Review Mode Overlay
          if (isReviewMode && reviewState != null)
            ReviewModeOverlay(
              focusedDayIndex: reviewState.currentChange?.dayIndex,
              focusedExerciseIndex: reviewState.currentChange?.exerciseIndex,
            ),
        ],
      ),
    );
  }

  // ==================== AI 思考面板 ====================

  /// 构建 AI 思考面板
  Widget _buildAIThinkingPanel(
    BuildContext context,
    CreateTrainingPlanState state,
  ) {
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
                'AI 正在生成训练计划...',
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),

          // 当前进度
          if (state.currentDayNumber != null) ...[
            const SizedBox(height: 12),
            Text(
              '正在生成第 ${state.currentDayNumber} 天',
              style: AppTextStyles.footnote.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),

            // 当前天的动作进度
            if (state.currentDayInProgress != null &&
                state.currentDayInProgress!.exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '已添加 ${state.currentDayInProgress!.exercises.length} 个动作',
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),

              // 显示最新添加的动作（最多显示最后3个）
              ...state.currentDayInProgress!.exercises.reversed
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
          if (state.days.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '已完成 ${state.days.length} 天',
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

  // ==================== Event Handlers ====================

  // ---------- Review Mode Event Handlers ----------

  /// 接受当前建议
  Future<void> _onAcceptSuggestion() async {
    await ref.read(suggestionReviewNotifierProvider.notifier).acceptCurrent();

    // 检查是否完成所有审核
    _checkReviewComplete();
  }

  /// 拒绝当前建议
  void _onRejectSuggestion() {
    ref.read(suggestionReviewNotifierProvider.notifier).rejectCurrent();

    // 检查是否完成所有审核
    _checkReviewComplete();
  }

  /// 接受所有剩余建议
  Future<void> _onAcceptAll() async {
    await ref.read(suggestionReviewNotifierProvider.notifier).acceptAll();
    _checkReviewComplete();
  }

  /// 拒绝所有剩余建议
  void _onRejectAll() {
    ref.read(suggestionReviewNotifierProvider.notifier).rejectAll();
    _checkReviewComplete();
  }

  /// 检查是否完成所有审核
  void _checkReviewComplete() {
    final reviewState = ref.read(suggestionReviewNotifierProvider);

    if (reviewState != null && reviewState.isComplete) {
      // 完成审核，应用最终计划
      final finalPlan = ref
          .read(suggestionReviewNotifierProvider.notifier)
          .finishReview();

      if (finalPlan != null) {
        // 应用到当前编辑状态
        ref
            .read(createTrainingPlanNotifierProvider.notifier)
            .applyModifiedPlan(finalPlan);

        // 退出 Review Mode
        ref.read(isReviewModeProvider.notifier).state = false;

        // 显示完成提示
        AppLogger.info('✅ Review 完成 - 已接受 ${reviewState.acceptedCount} 处修改');

        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('修改已应用'),
              content: Text('已成功应用 ${reviewState.acceptedCount} 处修改'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  // ---------- Original Event Handlers ----------

  /// 返回
  void _onBack(BuildContext context, notifier) {
    if (notifier.state.hasUnsavedChanges) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Discard changes?',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                'Leave',
                style: AppTextStyles.body.copyWith(
                  color: CupertinoColors.systemRed,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // 清除对话历史
                ref
                    .read(editConversationNotifierProvider.notifier)
                    .clearConversationStorage(widget.planId);
                context.pop();
              },
            ),
          ],
        ),
      );
    } else {
      // 清除对话历史
      ref
          .read(editConversationNotifierProvider.notifier)
          .clearConversationStorage(widget.planId);
      context.pop();
    }
  }

  /// 添加训练日
  void _onAddDay(notifier) {
    notifier.addDay();
    // 自动选择新添加的训练日
    setState(() {
      _selectedDayIndex = notifier.state.days.length - 1;
    });
  }

  /// 删除训练日
  void _onDeleteDay(notifier, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete training day?'),
        content: const Text(
          'Are you sure you want to delete this training day?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              notifier.removeDay(index);
              if (_selectedDayIndex == index) {
                setState(() {
                  _selectedDayIndex = null;
                });
              } else if (_selectedDayIndex != null &&
                  _selectedDayIndex! > index) {
                setState(() {
                  _selectedDayIndex = _selectedDayIndex! - 1;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// 添加动作
  void _onAddExercise(notifier, int dayIndex) {
    notifier.addExercise(dayIndex, exercise: Exercise.empty());
  }

  /// 删除动作
  void _onDeleteExercise(notifier, int dayIndex, int exerciseIndex) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete movement?'),
        content: const Text('Are you sure you want to delete this movement?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              notifier.removeExercise(dayIndex, exerciseIndex);
            },
          ),
        ],
      ),
    );
  }

  /// 添加 Set
  void _onAddSet(notifier, int dayIndex, int exerciseIndex) {
    notifier.addSet(dayIndex, exerciseIndex, set: TrainingSet.empty());
  }

  /// 删除 Set
  void _onDeleteSet(notifier, int dayIndex, int exerciseIndex, int setIndex) {
    notifier.removeSet(dayIndex, exerciseIndex, setIndex);
  }

  /// 保存计划
  Future<void> _onSave(BuildContext context, notifier) async {
    AppLogger.info('💾 准备保存训练计划');

    // 验证
    notifier.validate();
    if (notifier.state.validationErrors.isNotEmpty) {
      _showErrorDialog(context, notifier.state.validationErrors.first);
      return;
    }

    // 保存
    final success = await notifier.savePlan();

    if (success && mounted) {
      AppLogger.info('✅ 训练计划保存成功');
      _showSuccessDialog(context);
    } else if (mounted && notifier.state.errorMessage != null) {
      AppLogger.error('❌ 训练计划保存失败: ${notifier.state.errorMessage}');
      _showErrorDialog(context, notifier.state.errorMessage!);
    }
  }

  // ==================== UI Builders ====================

  /// 构建动作列表
  Widget _buildExercisesList(
    BuildContext context,
    notifier,
    int dayIndex,
    List<Exercise> exercises, {
    required bool isReviewMode,
    required SuggestionReviewState? reviewState,
  }) {
    // Review Mode 相关状态（从参数获取，避免重复 watch）
    final currentChange = reviewState?.currentChange;

    if (exercises.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No movements yet. Click "Add" to add one.',
          style: AppTextStyles.footnote.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: exercises.asMap().entries.map((entry) {
        final exerciseIndex = entry.key;
        final exercise = entry.value;

        // 检查当前动作是否有激活的建议
        final hasActiveSuggestion =
            isReviewMode &&
            currentChange != null &&
            currentChange.dayIndex == dayIndex &&
            currentChange.exerciseIndex == exerciseIndex;

        // 为每个 ExerciseCard 分配 GlobalKey 用于自动滚动
        final exerciseKey = '${dayIndex}_$exerciseIndex';
        _exerciseKeys.putIfAbsent(exerciseKey, () => GlobalKey());

        return ExerciseCard(
          key: _exerciseKeys[exerciseKey],
          exercise: exercise,
          index: exerciseIndex,
          isExpanded: true,
          onTap: null,
          onDelete: () => _onDeleteExercise(notifier, dayIndex, exerciseIndex),
          onNameChanged: (name) =>
              notifier.updateExerciseName(dayIndex, exerciseIndex, name),
          onNoteChanged: (note) =>
              notifier.updateExerciseNote(dayIndex, exerciseIndex, note),
          // Review Mode 参数
          activeSuggestion: hasActiveSuggestion ? currentChange : null,
          isHighlighted: hasActiveSuggestion,
          onAcceptSuggestion: hasActiveSuggestion
              ? () => _onAcceptSuggestion()
              : null,
          onRejectSuggestion: hasActiveSuggestion
              ? () => _onRejectSuggestion()
              : null,
          onAcceptAll: hasActiveSuggestion ? () => _onAcceptAll() : null,
          onRejectAll: hasActiveSuggestion ? () => _onRejectAll() : null,
          suggestionProgress: reviewState?.progressText,
          onAddSet: () => _onAddSet(notifier, dayIndex, exerciseIndex),
          onUploadGuide: () =>
              GuideUploadPlaceholder.showPlaceholderDialog(context),
          setsWidget: _buildSetsList(
            context,
            notifier,
            dayIndex,
            exerciseIndex,
            exercise.sets,
          ),
        );
      }).toList(),
    );
  }

  /// 构建 Sets 列表
  Widget _buildSetsList(
    BuildContext context,
    notifier,
    int dayIndex,
    int exerciseIndex,
    List<TrainingSet> sets,
  ) {
    if (sets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No sets yet. Click "Add Set" button.',
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
          onRepsChanged: (reps) {
            final updatedSet = set.copyWith(reps: reps);
            notifier.updateSet(dayIndex, exerciseIndex, setIndex, updatedSet);
          },
          onWeightChanged: (weight) {
            final updatedSet = set.copyWith(weight: weight);
            notifier.updateSet(dayIndex, exerciseIndex, setIndex, updatedSet);
          },
          onDelete: () =>
              _onDeleteSet(notifier, dayIndex, exerciseIndex, setIndex),
        );
      }).toList(),
    );
  }

  // ==================== Dialogs ====================

  /// 显示成功对话框
  void _showSuccessDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: const Text('Training plan saved successfully'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK', style: AppTextStyles.body),
            onPressed: () {
              Navigator.of(context).pop();
              // 清除对话历史
              ref
                  .read(editConversationNotifierProvider.notifier)
                  .clearConversationStorage(widget.planId);
              // 返回上一页
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 显示创建模式菜单
  void _showCreationModeMenu(BuildContext context, dynamic notifier) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('选择创建方式'),
        message: const Text('你可以手动创建、导入图片或使用AI引导'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showImportSheet(context, notifier);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, color: AppColors.primaryText),
                const SizedBox(width: 8),
                const Text('导入图片', style: AppTextStyles.body),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showGuidedCreationSheet(context, notifier);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.sparkles, color: AppColors.primaryText),
                const SizedBox(width: 8),
                const Text('AI 引导创建', style: AppTextStyles.body),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          isDefaultAction: true,
          child: const Text('取消', style: AppTextStyles.body),
        ),
      ),
    );
  }

  /// 显示导入计划 Sheet
  void _showImportSheet(BuildContext context, dynamic notifier) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => ImportPlanSheet(
        onImportSuccess: (result) {
          // 导入成功，加载计划到当前状态
          notifier.loadFromImportResult(result);

          // 显示成功提示
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('导入成功'),
              content: Text(
                '已成功导入计划：${result.plan?.name ?? "未知"}\n'
                '包含 ${result.plan?.totalDays ?? 0} 个训练日\n'
                '置信度：${(result.confidence * 100).toInt()}%',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 显示AI引导创建 Sheet
  void _showGuidedCreationSheet(BuildContext context, dynamic notifier) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => const GuidedCreationSheet(),
    );
  }

  /// 显示AI编辑对话面板
  void _showAIEditChatPanel(BuildContext context, dynamic notifier) {
    // 构建当前计划对象
    final currentPlan = ExercisePlanModel(
      id: notifier.state.planId ?? '',
      name: notifier.state.planName,
      description: notifier.state.description,
      ownerId: '',
      studentIds: const [],
      createdAt: 0,
      updatedAt: 0,
      days: notifier.state.days,
    );

    // 显示对话面板（高度为屏幕的 70%）
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext dialogContext) {
        return _AIEditChatPanelWrapper(
          dialogContext: dialogContext,
          currentPlan: currentPlan,
          notifier: notifier,
        );
      },
    );
  }

  /// 显示训练日选项菜单（长按pill）
  void _showDayOptionsMenu(
    BuildContext context,
    dynamic notifier,
    int dayIndex,
    String currentName,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('训练日选项'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDayNameDialog(context, notifier, dayIndex, currentName);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil, color: AppColors.primaryText),
                const SizedBox(width: 8),
                const Text('编辑名称', style: AppTextStyles.body),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _onDeleteDay(notifier, dayIndex);
            },
            isDestructiveAction: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(width: 8),
                const Text('删除训练日'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          isDefaultAction: true,
          child: const Text('取消', style: AppTextStyles.body),
        ),
      ),
    );
  }

  /// 显示编辑训练日名称对话框
  void _showEditDayNameDialog(
    BuildContext context,
    dynamic notifier,
    int dayIndex,
    String currentName,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('编辑训练日名称'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '例如：腿部力量训练',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: const Text('保存'),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                notifier.updateDayName(dayIndex, newName);
              }
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// AI 编辑对话面板包装器
///
/// 监听 pendingSuggestion，当有建议时自动关闭对话框并启动 Review Mode
class _AIEditChatPanelWrapper extends ConsumerStatefulWidget {
  final BuildContext dialogContext;
  final ExercisePlanModel currentPlan;
  final dynamic notifier;

  const _AIEditChatPanelWrapper({
    required this.dialogContext,
    required this.currentPlan,
    required this.notifier,
  });

  @override
  ConsumerState<_AIEditChatPanelWrapper> createState() =>
      _AIEditChatPanelWrapperState();
}

class _AIEditChatPanelWrapperState
    extends ConsumerState<_AIEditChatPanelWrapper> {
  bool _hasTriggeredReviewMode = false;

  @override
  Widget build(BuildContext context) {
    final pendingSuggestion = ref.watch(pendingSuggestionProvider);

    // 当有建议且未触发过 Review Mode 时，自动触发
    if (pendingSuggestion != null && !_hasTriggeredReviewMode && mounted) {
      _hasTriggeredReviewMode = true;

      // 使用 post frame callback 确保在当前 build 完成后执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        AppLogger.info('🚀 检测到建议，自动启动 Review Mode');

        // 1. 清除对话中的 pending suggestion
        ref.read(editConversationNotifierProvider.notifier).applySuggestion();

        // 2. 启动 Review Mode
        ref
            .read(suggestionReviewNotifierProvider.notifier)
            .startReview(pendingSuggestion, widget.currentPlan);
        ref.read(isReviewModeProvider.notifier).state = true;

        // 3. 关闭对话框
        Navigator.of(widget.dialogContext).pop();
        AppLogger.info('✅ 对话框已关闭，Review Mode 已启动');
      });
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: AIEditChatPanel(
        planId: widget.notifier.state.planId ?? '',
        currentPlan: widget.currentPlan,
        onPlanModified: (modifiedPlan) {
          // 应用修改后的计划到当前状态
          widget.notifier.applyModifiedPlan(modifiedPlan);
        },
        onSuggestionApplied: () {
          // 这个回调现在可能不会被调用了，因为我们自动触发
          // 但保留以防万一
        },
      ),
    );
  }
}
