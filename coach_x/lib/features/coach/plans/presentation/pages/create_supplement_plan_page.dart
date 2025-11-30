import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_supplement_plan_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/plan_header_widget.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/day_pill.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/supplement_day_editor.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/ai_supplement_creation_panel.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/import_supplement_plan_sheet.dart';

/// 创建/编辑补剂计划页面
class CreateSupplementPlanPage extends ConsumerStatefulWidget {
  final String? planId;

  const CreateSupplementPlanPage({super.key, this.planId});

  @override
  ConsumerState<CreateSupplementPlanPage> createState() =>
      _CreateSupplementPlanPageState();
}

class _CreateSupplementPlanPageState
    extends ConsumerState<CreateSupplementPlanPage> {
  int? _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(createSupplementPlanNotifierProvider.notifier);

      AppLogger.debug('🔍 接收到的 planId: ${widget.planId}');

      if (widget.planId != null && widget.planId!.isNotEmpty) {
        AppLogger.info('📝 编辑模式 - 加载计划 ID: ${widget.planId}');
        final success = await notifier.loadPlan(widget.planId!);
        if (success && mounted) {
          final state = ref.read(createSupplementPlanNotifierProvider);
          AppLogger.info('✅ 计划加载成功 - 补剂日数量: ${state.days.length}');
          if (state.days.isNotEmpty) {
            setState(() {
              _selectedDayIndex = 0;
            });
          }
        } else if (mounted) {
          AppLogger.error('❌ 加载计划失败');
          _showErrorDialog(context, '加载计划失败');
        }
      } else {
        AppLogger.info('➕ 创建模式 - 初始化新计划');
        // 重置状态确保从空白开始
        notifier.reset();
        // 添加第一天
        notifier.addDay(name: 'Day 1');
        setState(() {
          _selectedDayIndex = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSupplementPlanNotifierProvider);
    final notifier = ref.read(createSupplementPlanNotifierProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        middle: Text(
          state.isEditMode ? 'Edit Supplement Plan' : 'Create Supplement Plan',
          style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _onBack(context, notifier),
          child: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
        ),
        trailing: !state.isEditMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showCreationModeMenu(context, notifier),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.activeBlue,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Plan Header
                PlanHeaderWidget(
                  planName: state.planName,
                  onNameChanged: notifier.updatePlanName,
                  totalDays: state.totalDays,
                  totalExercises: state.totalSupplements,
                  totalSets: 0,
                ),

                // Day Pills
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
                    itemCount: state.days.length + 1,
                    itemBuilder: (context, index) {
                      if (index == state.days.length) {
                        return GestureDetector(
                          onTap: () => _onAddDay(notifier),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
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
                      ? SupplementDayEditor(
                          day: state.days[_selectedDayIndex!],
                          dayIndex: _selectedDayIndex!,
                          onDeleteTiming: (timingIndex) => notifier
                              .removeTiming(_selectedDayIndex!, timingIndex),
                          onTimingNameChanged: (timingIndex, name) =>
                              notifier.updateTimingName(
                                _selectedDayIndex!,
                                timingIndex,
                                name,
                              ),
                          onTimingNoteChanged: (timingIndex, note) =>
                              notifier.updateTimingNote(
                                _selectedDayIndex!,
                                timingIndex,
                                note,
                              ),
                          onAddSupplement: (timingIndex) {
                            notifier.addSupplement(
                              _selectedDayIndex!,
                              timingIndex,
                              supplement: Supplement.empty(),
                            );
                          },
                          onDeleteSupplement: (timingIndex, supplementIndex) =>
                              notifier.removeSupplement(
                                _selectedDayIndex!,
                                timingIndex,
                                supplementIndex,
                              ),
                          onSupplementNameChanged:
                              (timingIndex, supplementIndex, name) =>
                                  notifier.updateSupplementField(
                                    _selectedDayIndex!,
                                    timingIndex,
                                    supplementIndex,
                                    name: name,
                                  ),
                          onSupplementAmountChanged:
                              (timingIndex, supplementIndex, amount) =>
                                  notifier.updateSupplementField(
                                    _selectedDayIndex!,
                                    timingIndex,
                                    supplementIndex,
                                    amount: amount,
                                  ),
                          onAddTiming: () {
                            notifier.addTiming(_selectedDayIndex!);
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.capsule,
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

                // Save Button
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
                                          ? CupertinoColors.black
                                          : CupertinoColors.systemGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
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

          if (state.isLoading)
            Container(
              color: CupertinoColors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 16),
              ),
            ),
        ],
      ),
    );
  }

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

  void _onAddDay(notifier) {
    notifier.addDay();
    setState(() {
      _selectedDayIndex = notifier.state.days.length - 1;
    });
  }

  void _onDeleteDay(notifier, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete day?'),
        content: const Text('Are you sure you want to delete this day?'),
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

  Future<void> _onSave(BuildContext context, notifier) async {
    AppLogger.info('💾 准备保存补剂计划');

    notifier.validate();
    if (notifier.state.validationErrors.isNotEmpty) {
      _showErrorDialog(context, notifier.state.validationErrors.first);
      return;
    }

    final success = await notifier.savePlan();

    if (success && mounted) {
      AppLogger.info('✅ 补剂计划保存成功');
      _showSuccessDialog(context);
    } else if (mounted && notifier.state.errorMessage != null) {
      AppLogger.error('❌ 补剂计划保存失败: ${notifier.state.errorMessage}');
      _showErrorDialog(context, notifier.state.errorMessage!);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: const Text('Supplement plan saved successfully'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK', style: AppTextStyles.body),
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
          ),
        ],
      ),
    );
  }

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

  void _showDayOptionsMenu(
    BuildContext context,
    dynamic notifier,
    int dayIndex,
    String currentName,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('补剂日选项'),
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed),
                SizedBox(width: 8),
                Text('删除补剂日'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDefaultAction: true,
          child: const Text('取消', style: AppTextStyles.body),
        ),
      ),
    );
  }

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
        title: const Text('编辑补剂日名称'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '例如：训练日、休息日',
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

  /// 显示 AI 创建面板
  void _showAICreationPanel() {
    AppLogger.info('✨ 打开 AI 补剂创建面板');

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return const AISupplementCreationPanel();
      },
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
                Icon(CupertinoIcons.photo, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('导入图片', style: AppTextStyles.body),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showAICreationPanel();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.sparkles, color: AppColors.primary),
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
      builder: (BuildContext context) => ImportSupplementPlanSheet(
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
                '包含 ${result.plan?.totalDays ?? 0} 个补剂日\n'
                '置信度：${(result.confidence * 100).toInt()}%',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定', style: AppTextStyles.body),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
