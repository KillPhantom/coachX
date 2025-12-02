import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/enums/ai_status.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/create_plan_page_state.dart';
import 'package:coach_x/features/coach/plans/data/models/create_diet_plan_state.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_notifier.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/diet_suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/plan_header_widget.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/day_pill_scroll_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/diet_day_editor.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/meal_card.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/food_item_row.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/guided_diet_creation_sheet.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/ai_edit_diet_chat_panel.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/diet_review_mode_overlay.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/initial_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/text_import_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/diet/diet_ai_guided_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/diet/diet_ai_streaming_view.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/create_plan/diet/diet_text_import_summary_view.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 创建/编辑饮食计划页面
class CreateDietPlanPage extends ConsumerStatefulWidget {
  final String? planId;

  const CreateDietPlanPage({super.key, this.planId});

  @override
  ConsumerState<CreateDietPlanPage> createState() => _CreateDietPlanPageState();
}

class _CreateDietPlanPageState extends ConsumerState<CreateDietPlanPage> {
  // 当前选中的饮食日索引
  int? _selectedDayIndex;

  // 当前展开的餐次索引
  int? _expandedMealIndex;

  // Auto-scroll 相关
  final ScrollController _mealsScrollController = ScrollController();
  final Map<String, GlobalKey> _mealKeys = {}; // key format: "day_meal"

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
        ref.read(createDietPlanPageStateProvider.notifier).state =
            CreatePlanPageState.initial;
      }
    });
  }

  /// 加载现有计划
  Future<void> _loadPlan() async {
    final notifier = ref.read(createDietPlanNotifierProvider.notifier);

    AppLogger.info('📝 编辑模式 - 加载计划 ID: ${widget.planId}');
    final success = await notifier.loadPlan(widget.planId!);

    if (success && mounted) {
      final state = ref.read(createDietPlanNotifierProvider);
      AppLogger.info('✅ 计划加载成功 - 饮食日数量: ${state.days.length}');

      ref.read(createDietPlanPageStateProvider.notifier).state =
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
    // 清理 ScrollController
    _mealsScrollController.dispose();
    super.dispose();
  }

  /// 滚动到高亮的 meal card
  void _scrollToHighlightedMeal(int dayIndex, int? mealIndex) {
    if (mealIndex == null) return;

    final mealKey = '${dayIndex}_$mealIndex';
    final globalKey = _mealKeys[mealKey];

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
    final state = ref.watch(createDietPlanNotifierProvider);
    final notifier = ref.read(createDietPlanNotifierProvider.notifier);
    final isDietReviewMode = ref.watch(isDietReviewModeProvider);

    // 监听页面状态变化
    final pageState = ref.watch(createDietPlanPageStateProvider);

    // 注意：AI 生成完成后不再自动切换到 editing
    // 用户需要在 StreamView 中点击确认按钮后才会切换

    // 监听页面状态变化（处理自动选中第一天）
    ref.listen<CreatePlanPageState>(createDietPlanPageStateProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      // 当切换到 editing 时，默认选中第一天
      if (previous != CreatePlanPageState.editing &&
          next == CreatePlanPageState.editing) {
        final state = ref.read(createDietPlanNotifierProvider);
        setState(() {
          _selectedDayIndex = state.days.isNotEmpty ? 0 : null;
        });
        AppLogger.info('✅ 切换到编辑模式，默认选中第一天');
      }
    });

    // 监听 Review Mode 高亮变化，自动切换 day、展开 meal 并滚动
    ref.listen<DietSuggestionReviewState?>(
      dietSuggestionReviewNotifierProvider,
      (previous, next) {
        if (!mounted) return;

        // 当有新的 currentChange 时，自动切换 day、展开 meal 并滚动
        if (next != null && next.currentChange != null && isDietReviewMode) {
          final currentChange = next.currentChange!;

          // 1. 切换到目标 Day
          if (_selectedDayIndex != currentChange.dayIndex) {
            setState(() {
              _selectedDayIndex = currentChange.dayIndex;
            });
          }

          // 2. 展开目标 Meal
          if (currentChange.mealIndex != null &&
              _expandedMealIndex != currentChange.mealIndex) {
            setState(() {
              _expandedMealIndex = currentChange.mealIndex;
            });
          }

          // 3. 延迟执行，等待 UI 更新完成后滚动
          if (currentChange.mealIndex != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToHighlightedMeal(
                currentChange.dayIndex,
                currentChange.mealIndex,
              );
            });
          }
        }
      },
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Text(
          state.isEditMode ? 'Edit Diet Plan' : 'Create Diet Plan',
          style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _onBack(context, notifier),
          child: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
        ),
        trailing: state.days.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showAIEditDialog,
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.activeBlue,
                ),
              )
            : (!state.isEditMode
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          _showGuidedCreationSheet(context, notifier),
                      child: const Icon(
                        CupertinoIcons.sparkles,
                        color: CupertinoColors.activeBlue,
                      ),
                    )
                  : null),
      ),
      child: Stack(
        children: [
          // Main Content - 根据页面状态显示不同内容
          _buildBody(context, pageState),

          // Loading Overlay
          if (state.isLoading)
            Container(
              color: CupertinoColors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 16),
              ),
            ),

          // Diet Review Mode Overlay
          Consumer(
            builder: (context, ref, child) {
              final isDietReviewMode = ref.watch(isDietReviewModeProvider);
              if (isDietReviewMode) {
                return Container(child: const DietReviewModeOverlay());
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // ==================== Event Handlers ====================

  /// 返回
  void _onBack(BuildContext context, CreateDietPlanNotifier notifier) {
    final state = ref.read(createDietPlanNotifierProvider);
    if (state.hasUnsavedChanges) {
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
                context.pop();
              },
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  // ... (other methods)

  /// 保存计划
  Future<void> _onSave(
    BuildContext context,
    CreateDietPlanNotifier notifier,
  ) async {
    AppLogger.info('💾 准备保存饮食计划');

    // 验证
    notifier.validate();
    // Re-read state after validation to check for errors
    var state = ref.read(createDietPlanNotifierProvider);
    if (state.validationErrors.isNotEmpty) {
      _showErrorDialog(context, state.validationErrors.first);
      return;
    }

    // 保存
    final success = await notifier.savePlan();

    if (!context.mounted) return;

    if (success) {
      AppLogger.info('✅ 饮食计划保存成功');
      // TODO: 实现成功对话框
      // _showSuccessDialog(context);
    } else {
      // Re-read state to check for error message
      state = ref.read(createDietPlanNotifierProvider);
      if (state.errorMessage != null) {
        AppLogger.error('❌ 饮食计划保存失败: ${state.errorMessage}');
        _showErrorDialog(context, state.errorMessage!);
      }
    }
  }

  /// 添加饮食日
  void _onAddDay(CreateDietPlanNotifier notifier) {
    notifier.addDay();
    // 自动选择新添加的饮食日
    setState(() {
      _selectedDayIndex =
          ref.read(createDietPlanNotifierProvider).days.length - 1;
      _expandedMealIndex = null;
    });
  }

  /// 删除饮食日
  void _onDeleteDay(CreateDietPlanNotifier notifier, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete diet day?'),
        content: const Text('Are you sure you want to delete this diet day?'),
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
                  _expandedMealIndex = null;
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

  /// 添加餐次
  void _onAddMeal(CreateDietPlanNotifier notifier, int dayIndex) {
    notifier.addMeal(dayIndex, meal: Meal.empty());
  }

  /// 删除餐次
  void _onDeleteMeal(
    CreateDietPlanNotifier notifier,
    int dayIndex,
    int mealIndex,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete meal?'),
        content: const Text('Are you sure you want to delete this meal?'),
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
              notifier.removeMeal(dayIndex, mealIndex);
              if (_expandedMealIndex == mealIndex) {
                setState(() {
                  _expandedMealIndex = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// 添加食物条目
  void _onAddFoodItem(
    CreateDietPlanNotifier notifier,
    int dayIndex,
    int mealIndex,
  ) {
    notifier.addFoodItem(dayIndex, mealIndex, item: FoodItem.empty());
  }

  /// 删除食物条目
  void _onDeleteFoodItem(
    CreateDietPlanNotifier notifier,
    int dayIndex,
    int mealIndex,
    int itemIndex,
  ) {
    notifier.removeFoodItem(dayIndex, mealIndex, itemIndex);
  }

  // ==================== UI Builders ====================

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

  /// 显示饮食日选项菜单（长按pill）
  void _showDayOptionsMenu(
    BuildContext context,
    dynamic notifier,
    int dayIndex,
    String currentName,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('饮食日选项'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDayNameDialog(context, notifier, dayIndex, currentName);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil, color: AppColors.primary),
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
                const Text('删除饮食日'),
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

  /// 显示编辑饮食日名称对话框
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
        title: const Text('编辑饮食日名称'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '例如：高碳水日、低碳水日',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消', style: AppTextStyles.body),
            onPressed: () {
              controller.dispose();
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            child: const Text('保存', style: AppTextStyles.body),
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

  /// 显示AI引导创建饮食计划 Sheet
  void _showGuidedCreationSheet(BuildContext context, dynamic notifier) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => const GuidedDietCreationSheet(),
    );
  }

  /// 显示 AI 编辑对话框
  void _showAIEditDialog() {
    final currentState = ref.read(createDietPlanNotifierProvider);

    if (currentState.days.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('请先添加饮食日后再使用 AI 编辑'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定', style: AppTextStyles.body),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final currentPlan = _buildCurrentPlan();

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _AIEditDietChatPanelWrapper(
        dialogContext: dialogContext,
        currentPlan: currentPlan,
        notifier: ref.read(createDietPlanNotifierProvider.notifier),
      ),
    );
  }

  /// 根据页面状态构建不同的内容
  Widget _buildBody(BuildContext context, CreatePlanPageState pageState) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(createDietPlanNotifierProvider.notifier);

    switch (pageState) {
      case CreatePlanPageState.initial:
        return InitialView(
          onAIGuidedTap: () =>
              _switchToState(CreatePlanPageState.aiGuided),
          onTextImportTap: () =>
              _switchToState(CreatePlanPageState.textImport),
          onManualCreateTap: _createManualPlan,
        );

      case CreatePlanPageState.aiGuided:
        return DietAIGuidedView(
          onGenerationStart: _handleGenerationStart,
        );

      case CreatePlanPageState.textImport:
        return TextImportView(
          onImportSuccess: (result) {
            // TODO: 处理导入结果，切换到 textImportSummary 状态
            _switchToState(CreatePlanPageState.textImportSummary);
          },
        );

      case CreatePlanPageState.textImportSummary:
        return const DietTextImportSummaryView();

      case CreatePlanPageState.aiStreaming:
        return DietAIStreamingView(
          onConfirm: _handleStreamingConfirm,
        );

      case CreatePlanPageState.editing:
        return _buildEditingContent();
    }
  }

  /// 构建编辑器内容（现有的编辑界面）
  Widget _buildEditingContent() {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createDietPlanNotifierProvider);
    final notifier = ref.read(createDietPlanNotifierProvider.notifier);
    final reviewState = ref.watch(dietSuggestionReviewNotifierProvider);

    return SafeArea(
      child: Column(
        children: [
          // Plan Header
          PlanHeaderWidget(
            planName: state.planName,
            onNameChanged: notifier.updatePlanName,
            totalDays: state.totalDays,
            totalExercises: state.totalMeals,
            totalSets: state.totalFoodItems,
          ),

          // Horizontal Day Pills Scroll View
          DayPillScrollView(
            dayItems: state.days
                .map((day) => (name: day.name, day: day.day))
                .toList(),
            selectedDayIndex: _selectedDayIndex,
            onDayTap: (index) {
              setState(() {
                _selectedDayIndex = index;
                _expandedMealIndex = null; // 切换天时收起所有餐次
              });
            },
            onDayLongPress: (index, dayName) {
              _showDayOptionsMenu(context, notifier, index, dayName);
            },
            onAddDay: () => _onAddDay(notifier),
            addDayLabel: l10n.addDay,
          ),

          // Content Area
          Expanded(
            child: _selectedDayIndex != null &&
                    _selectedDayIndex! < state.days.length
                ? DismissKeyboardOnScroll(
                    child: SingleChildScrollView(
                      controller: _mealsScrollController,
                      child: DietDayEditor(
                        onAddMeal: () =>
                            _onAddMeal(notifier, _selectedDayIndex!),
                        totalMacros:
                            state.days[_selectedDayIndex!].targetMacros ??
                            state.days[_selectedDayIndex!].macros,
                        onProteinChanged: (value) =>
                            notifier.updateDayTargetMacros(
                              _selectedDayIndex!,
                              protein: value,
                            ),
                        onCarbsChanged: (value) =>
                            notifier.updateDayTargetMacros(
                              _selectedDayIndex!,
                              carbs: value,
                            ),
                        onFatChanged: (value) =>
                            notifier.updateDayTargetMacros(
                              _selectedDayIndex!,
                              fat: value,
                            ),
                        mealsWidget: Column(
                          children: _buildMealsList(
                            context,
                            notifier,
                            _selectedDayIndex!,
                            state.days[_selectedDayIndex!].meals,
                            reviewState,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Select a day or add a new one',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),

          // Save Button
          _buildSaveButton(context, notifier, state),
        ],
      ),
    );
  }

  /// 构建餐次列表
  List<Widget> _buildMealsList(
    BuildContext context,
    CreateDietPlanNotifier notifier,
    int selectedDayIndex,
    List<Meal> meals,
    DietSuggestionReviewState? reviewState,
  ) {
    return meals.asMap().entries.map((entry) {
      final mealIndex = entry.key;
      final meal = entry.value;
      final isExpanded = _expandedMealIndex == mealIndex;

      // 生成唯一的 GlobalKey
      final mealKey = '${selectedDayIndex}_$mealIndex';
      _mealKeys.putIfAbsent(mealKey, () => GlobalKey());

      // 构建 food items widget
      final foodItemsWidget = Column(
        children: meal.items.asMap().entries.map((itemEntry) {
          final itemIndex = itemEntry.key;
          final item = itemEntry.value;
          return FoodItemRow(
            item: item,
            index: itemIndex,
            onFoodChanged: (value) => notifier.updateFoodItemField(
              selectedDayIndex,
              mealIndex,
              itemIndex,
              food: value,
            ),
            onAmountChanged: (value) => notifier.updateFoodItemField(
              selectedDayIndex,
              mealIndex,
              itemIndex,
              amount: value,
            ),
            onProteinChanged: (value) => notifier.updateFoodItemField(
              selectedDayIndex,
              mealIndex,
              itemIndex,
              protein: value,
            ),
            onCarbsChanged: (value) => notifier.updateFoodItemField(
              selectedDayIndex,
              mealIndex,
              itemIndex,
              carbs: value,
            ),
            onFatChanged: (value) => notifier.updateFoodItemField(
              selectedDayIndex,
              mealIndex,
              itemIndex,
              fat: value,
            ),
            onCaloriesChanged: (value) => notifier.updateFoodItemField(
              selectedDayIndex,
              mealIndex,
              itemIndex,
              calories: value,
            ),
            onDelete: () => notifier.removeFoodItem(
              selectedDayIndex,
              mealIndex,
              itemIndex,
            ),
          );
        }).toList(),
      );

      return MealCard(
        key: _mealKeys[mealKey],
        meal: meal,
        index: mealIndex,
        isExpanded: isExpanded,
        onTap: () => setState(() {
          _expandedMealIndex = isExpanded ? null : mealIndex;
        }),
        onNameChanged: (name) => notifier.updateMealName(
          selectedDayIndex,
          mealIndex,
          name,
        ),
        onNoteChanged: (note) => notifier.updateMealNote(
          selectedDayIndex,
          mealIndex,
          note,
        ),
        onAddFoodItem: () => notifier.addFoodItem(
          selectedDayIndex,
          mealIndex,
        ),
        onDelete: () {
          notifier.removeMeal(selectedDayIndex, mealIndex);
          setState(() {
            _expandedMealIndex = null;
          });
        },
        foodItemsWidget: foodItemsWidget,
      );
    }).toList();
  }

  /// 构建保存按钮
  Widget _buildSaveButton(
    BuildContext context,
    CreateDietPlanNotifier notifier,
    CreateDietPlanState state,
  ) {
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
                      : CupertinoColors.quaternarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: state.isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : Text(
                        l10n.savePlan,
                        style: TextStyle(
                          color: state.canSave
                              ? CupertinoColors.black
                              : CupertinoColors.systemGrey,
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
    );
  }

  /// 切换页面状态
  void _switchToState(CreatePlanPageState newState) {
    ref.read(createDietPlanPageStateProvider.notifier).state = newState;
    AppLogger.debug('📄 切换页面状态到: $newState');
  }

  /// AI 生成开始时的处理
  void _handleGenerationStart() {
    // 立即切换到 aiStreaming 状态展示进度
    _switchToState(CreatePlanPageState.aiStreaming);
    AppLogger.info('🔄 AI 生成开始，切换到 streaming 视图');
  }

  /// AI 流式生成完成后用户点击确认按钮的处理
  void _handleStreamingConfirm() {
    final notifier = ref.read(createDietPlanNotifierProvider.notifier);
    final state = ref.read(createDietPlanNotifierProvider);

    // 切换到编辑模式
    _switchToState(CreatePlanPageState.editing);

    // 选中第一天
    setState(() {
      _selectedDayIndex = state.days.isNotEmpty ? 0 : null;
    });

    // 只在编辑模式下保存初始快照（首次创建不需要）
    if (state.isEditMode) {
      notifier.saveInitialSnapshot();
      AppLogger.info('✅ 用户确认查看计划，切换到编辑模式（已保存快照）');
    } else {
      AppLogger.info('✅ 用户确认查看计划，切换到编辑模式（首次创建）');
    }
  }

  /// 创建手动计划（添加 Day 1 并进入 editing）
  void _createManualPlan() {
    final notifier = ref.read(createDietPlanNotifierProvider.notifier);
    final state = ref.read(createDietPlanNotifierProvider);

    if (state.days.isEmpty) {
      notifier.addDay(name: 'Day 1');
      setState(() {
        _selectedDayIndex = 0;
      });
    }

    // 切换到编辑模式
    _switchToState(CreatePlanPageState.editing);

    // 保存初始快照（用于判断是否有修改）
    notifier.saveInitialSnapshot();

    AppLogger.info('➕ 创建手动计划 - 进入编辑模式');
  }

  /// 构建当前计划
  DietPlanModel _buildCurrentPlan() {
    final state = ref.read(createDietPlanNotifierProvider);

    return DietPlanModel(
      id: state.planId ?? '',
      name: state.planName,
      description: state.description,
      ownerId: '',
      studentIds: const [],
      createdAt: 0,
      updatedAt: 0,
      days: state.days,
    );
  }
}

/// AI 编辑饮食计划对话面板包装器
///
/// 简单包装 AIEditDietChatPanel，当建议被应用后关闭对话框
class _AIEditDietChatPanelWrapper extends ConsumerWidget {
  final BuildContext dialogContext;
  final DietPlanModel currentPlan;
  final dynamic notifier;

  const _AIEditDietChatPanelWrapper({
    required this.dialogContext,
    required this.currentPlan,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: AIEditDietChatPanel(
        planId: notifier.state.planId ?? '',
        currentPlan: currentPlan,
        onPlanModified: (modifiedPlan) {
          // 应用修改后的计划到当前状态（用于预览）
          final currentState = notifier.state;
          notifier.state = currentState.copyWith(
            planName: modifiedPlan.name,
            description: modifiedPlan.description,
            days: modifiedPlan.days,
          );
        },
        onSuggestionApplied: () {
          // Review Mode 启动后，关闭对话框
          Navigator.of(dialogContext).pop();
          AppLogger.info('✅ AI 编辑对话框已关闭，进入 Review Mode');
        },
      ),
    );
  }
}
