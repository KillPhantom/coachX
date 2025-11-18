import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/providers/exercise_library_providers.dart';
import '../providers/create_training_plan_providers.dart';
import './exercise_search_bar.dart';

/// 训练日编辑面板
class TrainingDayEditor extends ConsumerWidget {
  final int dayIndex;
  final Widget? exercisesWidget;

  const TrainingDayEditor({
    super.key,
    required this.dayIndex,
    this.exercisesWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExerciseSearchBar(
            onTemplateSelected: (template) {
              // 选择已存在的模板
              _addExerciseFromTemplate(
                ref,
                dayIndex,
                template.id,
                template.name,
              );
            },
            onCreateNew: (exerciseName) async {
              // 快捷创建新模板
              await _createAndAddExercise(ref, context, dayIndex, exerciseName);
            },
          ),

          const SizedBox(height: 12),

          // Exercises List
          if (exercisesWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: exercisesWidget!,
            ),
        ],
      ),
    );
  }

  /// 从已存在的模板添加动作
  void _addExerciseFromTemplate(
    WidgetRef ref,
    int dayIndex,
    String templateId,
    String templateName,
  ) {
    final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
    notifier.addExerciseFromTemplate(dayIndex, templateId, templateName);
  }

  /// 快捷创建新模板并添加动作
  Future<void> _createAndAddExercise(
    WidgetRef ref,
    BuildContext context,
    int dayIndex,
    String exerciseName,
  ) async {
    try {
      if (exerciseName.trim().isEmpty) {
        return;
      }

      // 获取教练 ID
      final coachId = AuthService.currentUserId;
      if (coachId == null) {
        AppLogger.error('无法创建模板：未找到教练 ID');
        return;
      }

      // 快捷创建模板
      final repository = ref.read(exerciseLibraryRepositoryProvider);
      final templateId = await repository.quickCreateTemplate(coachId, exerciseName);

      // 更新动作库缓存
      final libraryNotifier = ref.read(exerciseLibraryNotifierProvider.notifier);
      await libraryNotifier.refreshData();

      // 添加动作
      _addExerciseFromTemplate(ref, dayIndex, templateId, exerciseName);

      AppLogger.info('快捷创建并添加动作成功: $exerciseName');
    } catch (e, stackTrace) {
      AppLogger.error('快捷创建模板失败', e, stackTrace);

      // 显示错误提示
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('创建失败'),
            content: Text('无法创建动作模板：$e'),
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
