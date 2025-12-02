import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
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
  late ScrollController _tileScrollController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    _tileScrollController = ScrollController();

    // 页面加载时初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _tileScrollController.dispose();
    super.dispose();
  }

  /// 页面切换监听
  void _onPageChanged() {
    final currentPage = _pageController.page?.round() ?? 0;
    if (currentPage != _currentPage) {
      setState(() {
        _currentPage = currentPage;
      });
      // 自动滚动 tile 列表到当前 exercise
      _scrollToCurrentTile(currentPage);
      // 页面切换不重置计时器
    }
  }

  /// 自动滚动到当前 tile (确保可见)
  void _scrollToCurrentTile(int index) {
    if (!_tileScrollController.hasClients) {
      return;
    }

    // 估算每个 tile 的宽度 (最小80px + 间距8px)
    const double estimatedTileWidth = 88.0;
    final double offset = index * estimatedTileWidth;

    _tileScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
      AppLogger.error('❌ 加载训练数据失败: $e');
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
    ref
        .read(exerciseRecordNotifierProvider.notifier)
        .startExerciseTimer(_currentPage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(exerciseRecordNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.trainingRecord),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: state.isTimerRunning ? null : _showStartTimerDialog,
          child: Icon(CupertinoIcons.timer, color: AppColors.primaryAction),
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
                completedCount: state.exercises
                    .where((e) => e.completed)
                    .length,
                exerciseNames: state.exercises.map((e) => e.name).toList(),
                onExerciseTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tileScrollController: _tileScrollController,
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
            onSetComplete: (setIndex, reps, weight) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .completeSet(index, setIndex, reps, weight);
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
            onMediaSelected: (file, type) {
              // 添加媒体到 state 并立即启动后台上传（MediaUploadManager）
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .addPendingMedia(index, file.path, type, thumbnailPath: null);
            },
            onMediaUploadCompleted:
                (mediaIndex, downloadUrl, thumbnailUrl, type) {
                  // 上传完成，更新状态并保存到 Firestore
                  ref
                      .read(exerciseRecordNotifierProvider.notifier)
                      .completeMediaUpload(
                        index,
                        mediaIndex,
                        downloadUrl,
                        thumbnailUrl: thumbnailUrl,
                      );
                },
            onMediaDeleted: (mediaIndex) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .deleteMedia(index, mediaIndex);
            },
          ),
        );
      },
    );
  }
}
