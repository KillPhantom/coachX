import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/features/coach/plans/data/models/create_plan_page_state.dart';
import 'package:coach_x/features/coach/plans/data/models/create_training_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/import_result.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/edit_conversation_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/initial_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/training/training_ai_guided_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/text_import_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/training/training_text_import_summary_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/training/training_ai_streaming_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/editing_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/ai_edit_chat_panel.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/review_mode_overlay.dart';
import 'package:coach_x/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    // 加载计划或创建新计划
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.planId != null && widget.planId!.isNotEmpty) {
        // 编辑模式：加载现有计划
        await _loadPlan();
      } else {
        // 创建模式：显示初始选择页面
        ref.read(createPlanPageStateProvider.notifier).state =
            CreatePlanPageState.initial;
      }
    });
  }

  /// 加载现有计划
  Future<void> _loadPlan() async {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    AppLogger.info('📝 编辑模式 - 加载计划 ID: ${widget.planId}');
    final success = await notifier.loadPlan(widget.planId!);

    if (success && mounted) {
      final state = ref.read(createTrainingPlanNotifierProvider);
      AppLogger.info('✅ 计划加载成功 - 训练日数量: ${state.days.length}');

      ref.read(createPlanPageStateProvider.notifier).state =
          CreatePlanPageState.editing;
      setState(() {
        _selectedDayIndex = state.days.isNotEmpty ? 0 : null;
      });
    } else if (mounted) {
      // 加载失败，显示错误并返回
      AppLogger.error('❌ 加载计划失败');
      _showErrorDialog(context, '加载计划失败');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createTrainingPlanNotifierProvider);
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    // Review Mode 相关
    final isReviewMode = ref.watch(isReviewModeProvider);
    final reviewState = ref.watch(suggestionReviewNotifierProvider);

    // 监听页面状态变化（用于自动切换）
    final pageState = ref.watch(createPlanPageStateProvider);

    // 监听 AI 生成状态变化（已在 generateFromParamsStreaming 中处理）
    ref.listen<CreateTrainingPlanState>(createTrainingPlanNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      // 流式生成完成后，updatePageState 会自动切换到 editing
      // 这里处理普通 AI 生成（非流式）的情况
      if (previous?.aiStatus == AIGenerationStatus.generating &&
          next.aiStatus == AIGenerationStatus.success &&
          pageState == CreatePlanPageState.aiGuided) {
        ref.read(createPlanPageStateProvider.notifier).state =
            CreatePlanPageState.editing;
        setState(() {
          _selectedDayIndex = next.days.isNotEmpty ? 0 : null;
        });
        // 保存初始快照（用于判断是否有修改）
        ref.read(createTrainingPlanNotifierProvider.notifier).saveInitialSnapshot();
        AppLogger.info('✅ AI 生成完成，切换到编辑模式');
      }
    });

    // 监听页面状态变化（处理 AI Streaming 完成和文本导入完成）
    ref.listen<CreatePlanPageState>(createPlanPageStateProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      // 当从 aiStreaming 切换到 editing 时，默认选中第一天
      if (previous == CreatePlanPageState.aiStreaming &&
          next == CreatePlanPageState.editing) {
        final state = ref.read(createTrainingPlanNotifierProvider);
        setState(() {
          _selectedDayIndex = state.days.isNotEmpty ? 0 : null;
        });
        // 保存初始快照（用于判断是否有修改）
        ref.read(createTrainingPlanNotifierProvider.notifier).saveInitialSnapshot();
        AppLogger.info('✅ AI Streaming 完成，默认选中第一天');
      }

      // 当从 textImportSummary 切换到 editing 时，默认选中第一天
      if (previous == CreatePlanPageState.textImportSummary &&
          next == CreatePlanPageState.editing) {
        final state = ref.read(createTrainingPlanNotifierProvider);
        setState(() {
          _selectedDayIndex = state.days.isNotEmpty ? 0 : null;
        });
        // 保存初始快照（用于判断是否有修改）
        ref.read(createTrainingPlanNotifierProvider.notifier).saveInitialSnapshot();
        AppLogger.info('✅ 文本导入完成，默认选中第一天');
      }
    });

    // 监听 review state 变化（处理 Review 完成）
    ref.listen<SuggestionReviewState?>(suggestionReviewNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

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
      navigationBar: _buildNavigationBar(
        context,
        l10n,
        state,
        notifier,
        pageState,
      ),
      child: Stack(
        children: [
          // Main Content
          SafeArea(child: _buildBody(context, state, notifier)),

          // Loading Overlay
          if (state.isLoading)
            Container(
              color: CupertinoColors.black.withValues(alpha: 0.3),
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

  // ==================== UI 构建方法 ====================

  /// 构建导航栏
  CupertinoNavigationBar _buildNavigationBar(
    BuildContext context,
    AppLocalizations l10n,
    CreateTrainingPlanState state,
    notifier,
    CreatePlanPageState pageState,
  ) {
    return CupertinoNavigationBar(
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      middle: Text(
        _getTitle(l10n, state, pageState),
        style: AppTextStyles.navTitle,
      ),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _onBack(context, notifier),
        child: const Icon(CupertinoIcons.back, color: AppColors.primaryText),
      ),
      trailing: pageState == CreatePlanPageState.editing && state.isEditMode
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAIEditChatPanel(context, notifier),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: CupertinoColors.activeBlue,
              ),
            )
          : null,
    );
  }

  /// 获取页面标题
  String _getTitle(
    AppLocalizations l10n,
    CreateTrainingPlanState state,
    CreatePlanPageState pageState,
  ) {
    if (pageState == CreatePlanPageState.editing && state.isEditMode) {
      return l10n.editPlan;
    }
    return l10n.createPlanTitle;
  }

  /// 构建主体内容（根据页面状态路由）
  Widget _buildBody(
    BuildContext context,
    CreateTrainingPlanState state,
    notifier,
  ) {
    final pageState = ref.watch(createPlanPageStateProvider);

    switch (pageState) {
      case CreatePlanPageState.initial:
        return InitialView(
          onAIGuidedTap: _onAIGuidedTap,
          onTextImportTap: _onTextImportTap,
          onManualCreateTap: _onManualCreateTap,
        );

      case CreatePlanPageState.aiGuided:
        return TrainingAIGuidedView(
          onGenerationStart: () {
            // AI 生成开始后，页面状态保持在 aiGuided
            // 等待生成完成后自动切换到 editing（通过 listener）
            AppLogger.info('🤖 AI 引导生成开始');
          },
        );

      case CreatePlanPageState.textImport:
        return TextImportView(onImportSuccess: _onImportSuccess);

      case CreatePlanPageState.textImportSummary:
        return const TrainingTextImportSummaryView();

      case CreatePlanPageState.aiStreaming:
        return const TrainingAIStreamingView();

      case CreatePlanPageState.editing:
        return EditingView(
          state: state,
          notifier: notifier,
          selectedDayIndex: _selectedDayIndex,
          onDayIndexChanged: (index) {
            setState(() {
              _selectedDayIndex = index;
            });
          },
          onAddDay: () => _onAddDay(notifier),
          onDeleteDay: (index) => _onDeleteDay(notifier, index),
          onDeleteExercise: (dayIndex, exerciseIndex) =>
              _onDeleteExercise(notifier, dayIndex, exerciseIndex),
          onAddSet: (dayIndex, exerciseIndex) =>
              _onAddSet(notifier, dayIndex, exerciseIndex),
          onDeleteSet: (dayIndex, exerciseIndex, setIndex) =>
              _onDeleteSet(notifier, dayIndex, exerciseIndex, setIndex),
          onSave: () => _onSave(context, notifier),
          onAcceptSuggestion: _onAcceptSuggestion,
          onRejectSuggestion: _onRejectSuggestion,
          onAcceptAll: _onAcceptAll,
          onRejectAll: _onRejectAll,
        );
    }
  }

  // ==================== 状态切换方法 ====================

  /// AI 引导创建
  void _onAIGuidedTap() {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
    notifier.reset();
    ref.read(createPlanPageStateProvider.notifier).state =
        CreatePlanPageState.aiGuided;
    AppLogger.info('🤖 AI 引导创建模式 - 已重置状态');
  }

  /// 文本导入
  void _onTextImportTap() {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
    notifier.reset();
    ref.read(createPlanPageStateProvider.notifier).state =
        CreatePlanPageState.textImport;
    AppLogger.info('📄 文本导入模式 - 已重置状态');
  }

  /// 手动创建
  void _onManualCreateTap() {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
    notifier.reset();
    notifier.addDay(name: 'Day 1');
    ref.read(createPlanPageStateProvider.notifier).state =
        CreatePlanPageState.editing;
    setState(() {
      _selectedDayIndex = 0;
    });
    AppLogger.info('✍️ 手动创建模式 - 已重置状态并添加第一天');
  }

  /// 导入成功
  void _onImportSuccess(ImportResult result) {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    if (result.plan != null) {
      // 加载导入的计划到状态中（内部会自动计算统计）
      notifier.loadFromImportResult(result);

      // 切换到文本导入总结页面
      ref.read(createPlanPageStateProvider.notifier).state =
          CreatePlanPageState.textImportSummary;
    }
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
                  child: const Text('确定', style: AppTextStyles.body),
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

  /// 返回（支持多层级返回）
  void _onBack(BuildContext context, notifier) {
    final pageState = ref.read(createPlanPageStateProvider);

    // 场景 1: 在编辑模式且有未保存的更改 → 显示确认对话框
    if (pageState == CreatePlanPageState.editing &&
        notifier.state.hasUnsavedChanges) {
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
                // 判断是否回到 initial 或完全退出
                if (widget.planId == null) {
                  // 创建模式：返回到 initial
                  ref.read(createPlanPageStateProvider.notifier).state =
                      CreatePlanPageState.initial;
                } else {
                  // 编辑模式：清除对话历史并退出
                  ref
                      .read(editConversationNotifierProvider.notifier)
                      .clearConversationStorage(widget.planId);
                  context.pop();
                }
              },
            ),
          ],
        ),
      );
      return;
    }

    // 场景 2a: aiGuided 或 textImport 或 textImportSummary 状态 → 总是返回到 initial
    if ((pageState == CreatePlanPageState.aiGuided ||
            pageState == CreatePlanPageState.textImport ||
            pageState == CreatePlanPageState.textImportSummary) &&
        widget.planId == null) {
      ref.read(createPlanPageStateProvider.notifier).state =
          CreatePlanPageState.initial;
      AppLogger.info('🔙 返回到创建方式选择页面');
      return;
    }

    // 场景 2b: editing/aiStreaming 状态且为创建模式 → 返回到前一个状态
    if (pageState != CreatePlanPageState.initial && widget.planId == null) {
      // 检查是否有前一个页面状态
      final previousState = notifier.previousPageState;

      if (previousState != null &&
          previousState != CreatePlanPageState.editing) {
        // 返回到前一个状态（如 aiGuided, textImport, 或 aiStreaming）
        ref.read(createPlanPageStateProvider.notifier).state = previousState;
        AppLogger.info('🔙 返回到前一个页面: $previousState');
      } else {
        // 没有前一个状态或前一个状态也是 editing，返回到 initial
        ref.read(createPlanPageStateProvider.notifier).state =
            CreatePlanPageState.initial;
        AppLogger.info('🔙 返回到创建方式选择页面');
      }
      return;
    }

    // 场景 3: 在 initial 状态或编辑模式无更改 → 退出页面
    ref
        .read(editConversationNotifierProvider.notifier)
        .clearConversationStorage(widget.planId);
    context.pop();
    AppLogger.info('🔙 退出创建训练计划页面');
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
            child: const Text('Cancel', style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete', style: AppTextStyles.body),
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

  /// 删除动作
  void _onDeleteExercise(notifier, int dayIndex, int exerciseIndex) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete movement?'),
        content: const Text('Are you sure you want to delete this movement?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel', style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete', style: AppTextStyles.body),
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
            child: const Text('OK', style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
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
