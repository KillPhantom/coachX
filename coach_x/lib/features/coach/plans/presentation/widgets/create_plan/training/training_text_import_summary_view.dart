import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/create_plan_page_state.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/providers/exercise_library_providers.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/widgets/create_exercise_sheet.dart';
import 'package:coach_x/features/coach/exercise_library/data/models/exercise_template_model.dart';
import 'package:coach_x/features/student/training/presentation/widgets/exercise_guidance_sheet.dart';

/// 创建训练计划 - 文本导入总结视图
///
/// 显示文本导入解析完成后的统计摘要，支持：
/// - 查看已匹配的动作指导
/// - 为新动作创建指导内容
/// - 编辑动作名称
/// - 批量创建剩余模板
class TrainingTextImportSummaryView extends ConsumerStatefulWidget {
  const TrainingTextImportSummaryView({super.key});

  @override
  ConsumerState<TrainingTextImportSummaryView> createState() =>
      _TrainingTextImportSummaryViewState();
}

class _TrainingTextImportSummaryViewState
    extends ConsumerState<TrainingTextImportSummaryView> {
  /// 动作名称编辑控制器 (originalName -> controller)
  final Map<String, TextEditingController> _nameControllers = {};

  @override
  void dispose() {
    // 清理所有控制器
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(createTrainingPlanNotifierProvider);
    final stats = state.aiStreamingStats;

    if (stats == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundWhite,
      child: SafeArea(
        child: Column(
          children: [
            // 标题区域
            _buildHeader(l10n),

            // 内容区域（可滚动）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.spacingL),

                    // Exercise From Library Section
                    if (stats.reusedExerciseNames.isNotEmpty) ...[
                      _buildExerciseFromLibrarySection(stats, l10n),
                      const SizedBox(height: AppDimensions.spacingXL),
                    ],

                    // New Exercise Section
                    if (stats.newExerciseNames.isNotEmpty) ...[
                      _buildNewExerciseSection(stats, l10n),
                      const SizedBox(height: AppDimensions.spacingXL),
                    ],

                    // 底部间距
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // 底部确认按钮
            _buildConfirmButton(l10n),
          ],
        ),
      ),
    );
  }

  /// 构建标题区域
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          Text(
            l10n.textImportSummaryTitle,
            style: AppTextStyles.title2.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.textImportSummarySubtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建"动作库中的动作"区域
  Widget _buildExerciseFromLibrarySection(
    stats,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 标题
        Text(
          l10n.exerciseFromLibrary,
          style: AppTextStyles.title3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // 动作列表
        ...stats.reusedExerciseNames.map<Widget>((name) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
            child: _buildExerciseCard(
              name: name,
              isEditable: false,
              actionLabel: l10n.viewGuidance,
              onAction: () => _handleViewGuidance(name),
            ),
          );
        }),
      ],
    );
  }

  /// 构建"新动作"区域
  Widget _buildNewExerciseSection(
    stats,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 标题
        Container(
          width: double.infinity,
          height: 0.5,
          color: AppColors.divider,
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
        ),
        Text(
          l10n.newExercise,
          style: AppTextStyles.title3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // 动作列表（可编辑）
        ...stats.newExerciseNames.map<Widget>((name) {
          // 为每个动作创建控制器（如果还没有）
          _nameControllers.putIfAbsent(
            name,
            () => TextEditingController(text: name),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
            child: _buildExerciseCard(
              name: name,
              controller: _nameControllers[name],
              isEditable: true,
              actionLabel: l10n.createGuidance,
              onAction: () => _handleCreateGuidance(name),
            ),
          );
        }),
      ],
    );
  }

  /// 构建单个动作卡片
  Widget _buildExerciseCard({
    required String name,
    TextEditingController? controller,
    required bool isEditable,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.divider, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 左侧：动作名称
          Expanded(
            child: isEditable
                ? CupertinoTextField(
                    controller: controller,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: null,
                    padding: EdgeInsets.zero,
                    cursorColor: AppColors.primaryAction,
                  )
                : Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),

          const SizedBox(width: AppDimensions.spacingM),

          // 右侧：操作按钮
          CupertinoButton(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            minSize: 0,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.backgroundSecondary,
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.primaryAction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理"查看指导"按钮点击
  void _handleViewGuidance(String exerciseName) {
    final templates = ref.read(exerciseTemplatesProvider);

    // 查找匹配的模板
    final template = templates.firstWhereOrNull(
      (t) =>
          t.name.trim().toLowerCase() == exerciseName.trim().toLowerCase(),
    );

    if (template != null) {
      ExerciseGuidanceSheet.show(context, template.id);
    }
  }

  /// 处理"创建指导"按钮点击
  Future<void> _handleCreateGuidance(String originalName) async {
    final controller = _nameControllers[originalName];
    final currentName = controller?.text ?? originalName;

    // 创建临时模板，预填充动作名称
    final now = DateTime.now();
    final tempTemplate = ExerciseTemplateModel(
      id: '', // 临时 ID，保存时会生成真实 ID
      ownerId: '', // 保存时会填充
      name: currentName,
      tags: const [], // 空标签，用户可以在 sheet 中添加
      createdAt: now,
      updatedAt: now,
    );

    // 显示创建动作的 Sheet（预填充名称）
    await CreateExerciseSheet.show(context, template: tempTemplate);

    // 刷新动作库
    await ref.read(exerciseLibraryNotifierProvider.notifier).loadData();

    // 查找新创建的模板（按名称匹配）
    final templates = ref.read(exerciseTemplatesProvider);
    final newTemplate = templates.firstWhereOrNull(
      (t) => t.name.trim().toLowerCase() == currentName.trim().toLowerCase(),
    );

    if (newTemplate != null && mounted) {
      // 记录到 notifier
      ref
          .read(createTrainingPlanNotifierProvider.notifier)
          .recordManuallyCreatedTemplate(currentName, newTemplate.id);

      // 如果名称被修改了，也记录名称变化
      if (currentName != originalName) {
        ref
            .read(createTrainingPlanNotifierProvider.notifier)
            .applyExerciseNameChanges({originalName: currentName});
      }
    }
  }

  /// 构建底部确认按钮
  Widget _buildConfirmButton(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: _handleConfirm,
            child: Text(
              l10n.confirm,
              style: AppTextStyles.buttonLarge.copyWith(
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理确认按钮点击
  Future<void> _handleConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

    try {
      // 步骤1: 收集名称修改
      final nameChanges = <String, String>{};
      _nameControllers.forEach((oldName, controller) {
        final newName = controller.text.trim();
        if (newName.isNotEmpty && newName != oldName) {
          nameChanges[oldName] = newName;
        }
      });

      // 步骤2: 应用名称修改
      if (nameChanges.isNotEmpty) {
        notifier.applyExerciseNameChanges(nameChanges);
      }

      // 步骤3: 收集需要批量创建的新动作（使用更新后的 state）
      var currentState = ref.read(createTrainingPlanNotifierProvider);
      var stats = currentState.aiStreamingStats!;
      final allNewNames = stats.newExerciseNames;

      final manuallyCreated = currentState.manuallyCreatedTemplates.keys.toSet();
      final needBatchCreate = allNewNames
          .where((name) => !manuallyCreated.contains(name))
          .toList();

      // 步骤4: 批量创建剩余模板
      Map<String, String> batchCreatedIds = {};
      if (needBatchCreate.isNotEmpty) {
        batchCreatedIds = await notifier.createExerciseTemplatesBatch(
          needBatchCreate,
        );
      }

      // 步骤5: 刷新动作库缓存
      await ref.read(exerciseLibraryNotifierProvider.notifier).loadData();

      // 步骤6: 查找已存在模板的 templateId
      currentState = ref.read(createTrainingPlanNotifierProvider);
      stats = currentState.aiStreamingStats!;
      final templates = ref.read(exerciseTemplatesProvider);

      final reusedTemplateIds = <String, String>{};
      for (final exerciseName in stats.reusedExerciseNames) {
        final template = templates.firstWhereOrNull(
          (t) => t.name.trim().toLowerCase() == exerciseName.trim().toLowerCase(),
        );
        if (template != null) {
          reusedTemplateIds[exerciseName] = template.id;
        }
      }

      // 步骤7: 合并所有 templateId（使用更新后的 state）
      final allTemplateIds = {
        ...reusedTemplateIds,                   // 已存在的模板
        ...currentState.manuallyCreatedTemplates, // 手动创建的模板
        ...batchCreatedIds,                     // 批量创建的模板
      };

      // 步骤8: 注入 templateId
      notifier.injectTemplateIdsIntoPlan(allTemplateIds);

      // 步骤9: 进入 editing 状态
      notifier.updatePageState(CreatePlanPageState.editing);
    } catch (e) {
      // 显示错误
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.errorOccurred),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// Extension to add firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
