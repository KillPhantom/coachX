import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/student/home/presentation/providers/student_home_providers.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_record_state.dart';
import 'package:coach_x/features/student/training/presentation/providers/exercise_record_providers.dart';
import 'package:coach_x/features/student/training/presentation/widgets/exercise_record_card.dart';
import 'package:coach_x/features/student/training/presentation/widgets/timer_header.dart';
import 'package:coach_x/features/student/training/presentation/widgets/custom_page_indicator.dart';
import 'package:coach_x/features/student/training/presentation/widgets/congrats_banner.dart';

/// 训练记录页面（完整版）
class ExerciseRecordPage extends ConsumerStatefulWidget {
  const ExerciseRecordPage({super.key});

  @override
  ConsumerState<ExerciseRecordPage> createState() => _ExerciseRecordPageState();
}

class _ExerciseRecordPageState extends ConsumerState<ExerciseRecordPage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);

    // 页面加载时初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// 页面切换监听
  void _onPageChanged() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage != _currentPage) {
      setState(() {
        _currentPage = currentPage;
      });
      // 页面切换不重置计时器
    }
  }

  Future<void> _loadData() async {
    try {
      // 等待 plans 数据加载完成
      final plans = await ref.read(studentPlansProvider.future);

      final exercisePlan = plans.exercisePlan;

      if (exercisePlan == null) {
        // 没有训练计划
        await ref
            .read(exerciseRecordNotifierProvider.notifier)
            .loadExercisesForToday(coachId: 'unknown');
        return;
      }

      // 计算今天应该做哪个训练日
      final dayNumbers = ref.read(currentDayNumbersProvider);
      final currentDayNumber = dayNumbers['exercise'] ?? 1;

      final currentDay = exercisePlan.days.firstWhere(
        (day) => day.day == currentDayNumber,
        orElse: () => exercisePlan.days.first,
      );

      await ref
          .read(exerciseRecordNotifierProvider.notifier)
          .loadExercisesForToday(
            coachId: exercisePlan.ownerId,
            exercisePlanId: exercisePlan.id,
            exerciseDayNumber: currentDayNumber,
            exercisePlanDay: currentDay.exercises,
          );
    } catch (e) {
      print('❌ 加载训练数据失败: $e');
    }
  }

  /// 显示启动计时器确认对话框
  void _showStartTimerDialog() {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.startTimerConfirmTitle),
        content: Text(l10n.startTimerConfirmMessage),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              _startTimerMode();
            },
            child: Text(l10n.startTimerButton),
          ),
        ],
      ),
    );
  }

  /// 启动计时器
  void _startTimerMode() {
    ref.read(exerciseRecordNotifierProvider.notifier).startTimer();
    // 同时启动第一个 Exercise 的计时器
    ref.read(exerciseRecordNotifierProvider.notifier).startExerciseTimer(_currentPage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(exerciseRecordNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.trainingRecord, style: AppTextStyles.navTitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer Icon
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: state.isTimerRunning ? null : _showStartTimerDialog,
              child: Icon(CupertinoIcons.timer, color: AppColors.primaryAction),
            ),
            // Add Custom Exercise Icon
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: state.isSaving ? null : _showAddCustomExerciseAlert,
              child: const Icon(CupertinoIcons.add, color: AppColors.primaryAction),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Timer Header (如果计时器在运行)
            if (state.isTimerRunning)
              TimerHeader(
                startTime: state.timerStartTime,
                currentExerciseStartTime: state.currentExerciseStartTime,
              ),

            // 主内容区域
            Expanded(
              child: state.isLoading
                  ? const Center(child: LoadingIndicator())
                  : state.error != null
                  ? _buildErrorView(state.error!)
                  : state.exercises.isEmpty
                  ? _buildEmptyView()
                  : _buildPageView(state),
            ),

            // Page Indicator (底部指示器)
            if (state.exercises.isNotEmpty)
              CustomPageIndicator(
                currentPage: _currentPage,
                totalPages: state.exercises.length,
                completedCount: state.exercises.where((e) => e.completed).length,
                onPreviousPage: () {
                  if (_currentPage > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onNextPage: () {
                  if (_currentPage < state.exercises.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),

            // Congrats Banner (所有 exercise 完成时显示，放在最底部)
            if (state.exercises.isNotEmpty &&
                state.exercises.every((e) => e.completed))
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 12.0,
                  bottom: 8.0,
                ),
                child: CongratsBanner(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.loadFailed, style: AppTextStyles.title3),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.flame,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noExercises,
            style: AppTextStyles.title3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addCustomExerciseHint,
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(ExerciseRecordState state) {
    return PageView.builder(
      controller: _pageController,
      itemCount: state.exercises.length,
      itemBuilder: (context, index) {
        final exercise = state.exercises[index];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ExerciseRecordCard(
            exercise: exercise,
            exerciseIndex: index,
            isSaving: state.isSaving,
            onSetChanged: (setIndex, updatedSet) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .updateSetRealtime(index, setIndex, updatedSet);
            },
            onToggleSetEdit: (setIndex) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .toggleSetCompleted(index, setIndex);
            },
            onQuickComplete: () {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .quickComplete(index);
            },
            onVideoUploaded: (videoFile) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .uploadVideo(index, videoFile);
            },
            onVideoDeleted: (videoIndex) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .deleteVideo(index, videoIndex);
            },
          ),
        );
      },
    );
  }

  void _showAddCustomExerciseAlert() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('TODO'),
        content: const Text('添加自定义动作功能开发中...'),
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
