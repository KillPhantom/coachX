import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/routes/route_names.dart';
import '../providers/student_home_providers.dart';

/// 今日训练计划区块
///
/// 显示今日训练计划的详细内容
class TodayTrainingPlanSection extends ConsumerWidget {
  const TodayTrainingPlanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.watch(studentPlansProvider);
    final dayNumbers = ref.watch(currentDayNumbersProvider);
    final latestTrainingAsync = ref.watch(latestTrainingProvider);

    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (plans) {
        if (plans.exercisePlan == null) {
          return const SizedBox.shrink();
        }

        final dayNum = dayNumbers['exercise'] ?? 1;
        final trainingDay = plans.exercisePlan!.days.firstWhere(
          (day) => day.day == dayNum,
          orElse: () => plans.exercisePlan!.days.first,
        );

        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 训练日名称 + 导航按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：训练日名称
                  Text(trainingDay.name, style: AppTextStyles.body),

                  // 右侧：导航按钮
                  GestureDetector(
                    onTap: () => context.push(RouteNames.studentExerciseRecord),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          latestTrainingAsync.when(
                            data: (latestTraining) {
                              // 判断今天是否已有训练记录
                              final hasRecordToday =
                                  latestTraining != null &&
                                  _isToday(latestTraining.date);
                              return hasRecordToday
                                  ? l10n.viewRecords
                                  : l10n.startRecording;
                            },
                            loading: () => l10n.startRecording,
                            error: (_, __) => l10n.startRecording,
                          ),
                          style: AppTextStyles.footnote.copyWith(
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.arrow_right,
                          color: CupertinoColors.systemBlue,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // 动作列表
              _buildExercisesList(trainingDay.exercises, l10n, context),
            ],
          ),
        );
      },
    );
  }

  /// 构建动作列表
  Widget _buildExercisesList(
    List exercises,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    if (exercises.isEmpty) {
      return Text(
        l10n.noExercises,
        style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;
        final isLast = index == exercises.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppDimensions.spacingS),
          child: _buildExerciseCard(exercise, l10n, context),
        );
      }).toList(),
    );
  }

  /// 构建单个动作卡片
  Widget _buildExerciseCard(
    dynamic exercise,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧内容区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Exercise 名称
                Text(
                  exercise.name,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),

                // Sets 信息
                Text(
                  'x ${_formatExerciseSets(exercise.sets, l10n)}',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimensions.spacingM),

          // 右侧 Video 按钮
          GestureDetector(
            onTap: () => _showVideoOrPlaceholder(context, exercise, l10n),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.play_circle,
                  color: CupertinoColors.systemBlue,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.video,
                  style: AppTextStyles.footnote.copyWith(
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示视频或 placeholder
  void _showVideoOrPlaceholder(
    BuildContext context,
    dynamic exercise,
    AppLocalizations l10n,
  ) {
    // 检查是否有视频
    if (exercise.demoVideos == null || exercise.demoVideos.isEmpty) {
      _showComingSoonDialog(context, l10n);
    } else {
      // TODO: 未来实现视频播放功能
      _showComingSoonDialog(context, l10n);
    }
  }

  /// 显示即将推出的提示弹窗
  void _showComingSoonDialog(BuildContext context, AppLocalizations l10n) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(l10n.comingSoon),
          content: Text(l10n.aiGuidanceInDevelopment),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  /// 格式化 Sets 信息
  /// 规则：
  /// 1. 如果所有 sets 的 reps 和 weight 相同: "4组 x 12次 @ 20kg"
  /// 2. 如果 reps 相同但 weight 不同: "4组 x 12次" (不显示重量)
  /// 3. 如果都不相同: "4组" (只显示组数)
  String _formatExerciseSets(List sets, AppLocalizations l10n) {
    if (sets.isEmpty) {
      return '';
    }

    final totalSets = sets.length;

    // 检查所有 reps 是否相同
    final firstReps = sets[0].reps;
    final allRepsSame = sets.every((set) => set.reps == firstReps);

    // 检查所有 weight 是否相同且非空
    final firstWeight = sets[0].weight;
    final allWeightsSame = sets.every((set) => set.weight == firstWeight);
    final hasWeight = firstWeight.isNotEmpty;

    if (allRepsSame && allWeightsSame && hasWeight) {
      // 情况1: reps 和 weight 都相同
      return l10n.exerciseSetsWithWeight(totalSets, firstReps, firstWeight);
    } else if (allRepsSame) {
      // 情况2: reps 相同但 weight 不同或为空
      return l10n.exerciseSetsNoWeight(totalSets, firstReps);
    } else {
      // 情况3: reps 不同
      return l10n.exerciseSetsOnly(totalSets);
    }
  }

  /// 判断日期是否为今天
  ///
  /// 参数 dateString 格式: "yyyy-MM-dd"
  bool _isToday(String dateString) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final date = DateTime.parse(dateString);
      final dateOnly = DateTime(date.year, date.month, date.day);
      return dateOnly.isAtSameMomentAs(today);
    } catch (e) {
      return false;
    }
  }
}
