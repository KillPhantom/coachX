import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/core/services/local_keyframe_extractor.dart';
import 'package:coach_x/core/models/video_upload_state.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';
import 'package:coach_x/features/student/training/data/models/keyframe_model.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/chat/data/models/training_summary.dart';
import 'package:coach_x/features/chat/presentation/widgets/read_only_feedback_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_bottom_sheet.dart';
import 'package:coach_x/core/widgets/image_preview_page.dart';
import 'package:coach_x/core/widgets/linear_progress_bar.dart';
import 'package:coach_x/core/widgets/video_player_dialog.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 训练详情审核页面
class DailyTrainingReviewPage extends ConsumerWidget {
  final String dailyTrainingId;

  const DailyTrainingReviewPage({super.key, required this.dailyTrainingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pageDataAsync = ref.watch(reviewPageDataProvider(dailyTrainingId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
        middle: pageDataAsync.when(
          data: (data) => data?.studentInfo != null
              ? _HeaderStudentInfo(student: data!.studentInfo!)
              : Text(l10n.trainingReviews, style: AppTextStyles.navTitle),
          loading: () =>
              Text(l10n.trainingReviews, style: AppTextStyles.navTitle),
          error: (_, __) =>
              Text(l10n.trainingReviews, style: AppTextStyles.navTitle),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: pageDataAsync.when(
          data: (data) => data != null ? _CompleteButton(data: data) : null,
          loading: () => null,
          error: (_, __) => null,
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: pageDataAsync.when(
          data: (data) {
            if (data == null) {
              return Center(
                child: Text(
                  l10n.noDataFound,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            // 新布局：只有可滚动内容，底部区域已移除
            return _PageContent(data: data, dailyTrainingId: dailyTrainingId);
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.failedToSave,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () =>
                      ref.refresh(reviewPageDataProvider(dailyTrainingId)),
                  child: Text(l10n.feedbackRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends ConsumerWidget {
  final ReviewPageData data;

  const _CompleteButton({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isSaving = ref.watch(isSavingProvider);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isSaving
          ? null
          : () async {
              ref.read(isSavingProvider.notifier).state = true;
              try {
                // 标记为已审核（反馈已通过 FeedbackInputBar 实时保存）
                await ref
                    .read(dailyTrainingRepositoryProvider)
                    .markAsReviewed(data.dailyTraining.id);

                if (context.mounted) {
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text(l10n.failedToSave),
                      content: Text(e.toString()),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } finally {
                ref.read(isSavingProvider.notifier).state = false;
              }
            },
      child: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(),
            )
          : Text(
              l10n.complete,
              style: AppTextStyles.callout.copyWith(
                color: AppColors.primaryAction,
              ),
            ),
    );
  }
}

class _HeaderStudentInfo extends StatelessWidget {
  final UserModel student;

  const _HeaderStudentInfo({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundSecondary,
          ),
          child: student.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    student.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        CupertinoIcons.person_fill,
                        size: 20,
                        color: AppColors.textSecondary,
                      );
                    },
                  ),
                )
              : const Icon(
                  CupertinoIcons.person_fill,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
        ),
        const SizedBox(width: 8),
        // Student Name
        Flexible(
          child: Text(
            student.name,
            style: AppTextStyles.navTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PageContent extends ConsumerWidget {
  final ReviewPageData data;
  final String dailyTrainingId;

  const _PageContent({required this.data, required this.dailyTrainingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExerciseIndex = ref.watch(selectedExerciseIndexProvider);
    final exercises = data.dailyTraining.exercises ?? [];

    return CustomScrollView(
      slivers: [
        // Summary Card
        SliverToBoxAdapter(child: _TrainingSummaryCard(data: data)),

        // Exercise Video Section (if有视频)
        if (exercises.isNotEmpty && exercises.any((e) => e.videos.isNotEmpty))
          SliverToBoxAdapter(
            child: _ExerciseVideoSection(dailyTraining: data.dailyTraining),
          ),

        // 只读反馈历史区域
        if (exercises.isNotEmpty &&
            selectedExerciseIndex < exercises.length &&
            exercises[selectedExerciseIndex].exerciseTemplateId != null)
          SliverToBoxAdapter(
            child: ReadOnlyFeedbackSection(
              studentId: data.dailyTraining.studentId,
              exerciseTemplateId:
                  exercises[selectedExerciseIndex].exerciseTemplateId!,
              exerciseName: exercises[selectedExerciseIndex].name,
              onAddFeedbackTap: () => _showFeedbackBottomSheet(
                context,
                ref,
                dailyTrainingId,
                data.dailyTraining.studentId,
                exercises[selectedExerciseIndex].exerciseTemplateId!,
                exercises[selectedExerciseIndex].name,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _TrainingSummaryCard extends ConsumerWidget {
  final ReviewPageData data;

  const _TrainingSummaryCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final diet = data.dailyTraining.diet;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Detail Button
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.todaySummary,
                  style: AppTextStyles.callout.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _showDetailDialog(context, data),
                child: Text(
                  l10n.details,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.primaryAction,
                  ),
                ),
              ),
            ],
          ),

          // Main Summary Text
          _MainSummaryText(
            summary: _calculateTrainingSummary(data.dailyTraining),
          ),

          const SizedBox(height: 8),

          // Compact Nutrition Row
          _CompactNutritionRow(macros: diet?.macros),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ReviewPageData data) {
    final l10n = AppLocalizations.of(context)!;
    final diet = data.dailyTraining.diet;
    final exercises = data.dailyTraining.exercises;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.trainingDetails),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Nutrition Section
              if (diet?.macros != null) ...[
                Text(
                  l10n.nutritionDetails,
                  style: AppTextStyles.footnote.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _NutritionDataRow(macros: diet!.macros),
                const SizedBox(height: 16),
              ],

              // Exercise Section
              if (exercises != null && exercises.isNotEmpty) ...[
                Text(
                  l10n.exerciseRecordVideo,
                  style: AppTextStyles.footnote.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...exercises.map((e) => _ExerciseComparisonItem(exercise: e)),
              ],
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _NutritionDataRow extends StatelessWidget {
  final Macros macros;

  const _NutritionDataRow({required this.macros});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _NutritionCard(
            label: l10n.calories,
            value: '${macros.calories.toInt()}',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _NutritionCard(
            label: l10n.protein,
            value: '${macros.protein.toInt()}g',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _NutritionCard(
            label: l10n.carbs,
            value: '${macros.carbs.toInt()}g',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _NutritionCard(
            label: l10n.fats,
            value: '${macros.fat.toInt()}g',
          ),
        ),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.caption1.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _ExerciseComparisonItem extends StatelessWidget {
  final StudentExerciseModel exercise;

  const _ExerciseComparisonItem({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.name,
                style: AppTextStyles.footnote.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${exercise.sets.length} ${l10n.sets}',
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (exercise.sets.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${exercise.sets.first.weight} × ${exercise.sets.first.reps}',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MainSummaryText extends StatelessWidget {
  final TrainingSummary summary;

  const _MainSummaryText({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Text(
      summary.toDisplayString(),
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _CompactNutritionRow extends StatelessWidget {
  final Macros? macros;

  const _CompactNutritionRow({this.macros});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (macros == null) {
      return Text(
        l10n.noNutritionData,
        style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary),
      );
    }

    final parts = [
      'Cal: ${macros!.calories.toInt()}',
      'P: ${macros!.protein.toInt()}g',
      'C: ${macros!.carbs.toInt()}g',
      'F: ${macros!.fat.toInt()}g',
    ];

    return Text(
      parts.join(' | '),
      style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _ExerciseVideoSection extends ConsumerWidget {
  final DailyTrainingModel dailyTraining;

  const _ExerciseVideoSection({required this.dailyTraining});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = ref.watch(selectedExerciseIndexProvider);
    final loadingStates = ref.watch(keyframeExtractionLoadingProvider);
    final errorStates = ref.watch(keyframeExtractionErrorProvider);

    final exercises = dailyTraining.exercises ?? [];
    final trainingId = dailyTraining.id;

    // 过滤出有视频的 exercises 和它们的原始索引
    final exercisesWithVideos = <int, StudentExerciseModel>{};
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i].videos.isNotEmpty) {
        exercisesWithVideos[i] = exercises[i];
      }
    }

    // 如果没有任何 exercise 有视频，不显示整个 section
    if (exercisesWithVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取原始索引列表（保持顺序）
    final videoExerciseIndices = exercisesWithVideos.keys.toList();

    // 确保 selectedIndex 在有效范围内，默认选择第一个有视频的 exercise
    int validSelectedIndex = selectedIndex;
    if (!exercisesWithVideos.containsKey(validSelectedIndex)) {
      validSelectedIndex = videoExerciseIndices.first;
      // 更新 provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedExerciseIndexProvider.notifier).state =
            validSelectedIndex;
      });
    }

    final currentExercise = exercises[validSelectedIndex];
    final isLoading = loadingStates[validSelectedIndex] ?? false;
    final errorMessage = errorStates[validSelectedIndex];

    // 从 extractedKeyFrames 读取关键帧
    final exerciseIndexStr = validSelectedIndex.toString();
    final extractedKeyFrame =
        dailyTraining.extractedKeyFrames[exerciseIndexStr];
    final keyframes = extractedKeyFrame?.keyframes ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.exerciseRecordVideo,
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _InfoIconWithPopup(),
            ],
          ),
          const SizedBox(height: 8),

          // Exercise Navigation - 第一层 Tab（仅显示有视频的 exercises）
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: videoExerciseIndices.length,
              itemBuilder: (context, displayIndex) {
                final originalIndex = videoExerciseIndices[displayIndex];
                final exercise = exercises[originalIndex];
                final isSelected = originalIndex == validSelectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: isSelected ? AppColors.primary : null,
                    borderRadius: BorderRadius.circular(6),
                    onPressed: () {
                      ref.read(selectedExerciseIndexProvider.notifier).state =
                          originalIndex;
                      // 切换 Exercise 时重置 Video 索引
                      ref.read(selectedVideoIndexProvider.notifier).state = 0;
                    },
                    child: Text(
                      exercise.name,
                      style: AppTextStyles.callout.copyWith(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Video SubTab（第二层，条件显示：仅当有多个视频时）
          if (currentExercise.videos.length > 1) ...[
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currentExercise.videos.length,
                itemBuilder: (context, videoIndex) {
                  final selectedVideoIndex = ref.watch(
                    selectedVideoIndexProvider,
                  );
                  final isSelected = videoIndex == selectedVideoIndex;

                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: isSelected
                          ? AppColors.primaryAction
                          : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(4),
                      onPressed: () {
                        ref.read(selectedVideoIndexProvider.notifier).state =
                            videoIndex;
                      },
                      child: Text(
                        l10n.videoWithNumber(videoIndex + 1),
                        style: AppTextStyles.caption1.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Video + Keyframes - 左右分屏布局 (3:2)
          Builder(
            builder: (context) {
              // 获取选中的视频索引，确保在有效范围内
              final selectedVideoIndex = ref.watch(selectedVideoIndexProvider);
              final videoCount = currentExercise.videos.length;
              final validVideoIndex = videoCount > 0
                  ? (selectedVideoIndex < videoCount ? selectedVideoIndex : 0)
                  : 0;

              // 获取当前选中的视频
              final currentVideo = currentExercise.videos.isNotEmpty
                  ? currentExercise.videos[validVideoIndex]
                  : null;

              return SizedBox(
                height: 300,
                child: Row(
                  children: [
                    // 左侧：视频区域 (60%)
                    Expanded(
                      flex: 3,
                      child: _VideoPlayerArea(
                        video: currentVideo,
                        trainingId: trainingId,
                        exerciseIndex: validSelectedIndex,
                        exerciseName: currentExercise.name,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 右侧：关键帧区域 (40%)
                    Expanded(
                      flex: 2,
                      child: _KeyframeListArea(
                        keyframes: keyframes,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        hasVideo: currentExercise.videos.isNotEmpty,
                        onExtract: () => _handleExtractKeyframes(
                          context,
                          ref,
                          validSelectedIndex,
                          trainingId,
                          currentVideo?.downloadUrl ?? '',
                        ),
                        dailyTrainingId: trainingId,
                        exerciseIndex: validSelectedIndex,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 视频播放区域（显示缩略图+播放按钮）
class _VideoPlayerArea extends StatelessWidget {
  final VideoUploadState? video;
  final String? trainingId;
  final int? exerciseIndex;
  final String? exerciseName;

  const _VideoPlayerArea({
    this.video,
    this.trainingId,
    this.exerciseIndex,
    this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: trainingId != null && exerciseIndex != null && exerciseName != null
          ? () => _handleVideoPlay(
              context,
              video,
              trainingId!,
              exerciseIndex!,
              exerciseName!,
            )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 缩略图
            if (video?.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: video!.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CupertinoActivityIndicator()),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),

            // 播放按钮叠加层
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.black.withValues(alpha: 0.5),
                ),
                child: const Icon(
                  CupertinoIcons.play_fill,
                  size: 32,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 关键帧列表区域（封装4种状态）
class _KeyframeListArea extends StatelessWidget {
  final List<KeyframeModel> keyframes;
  final bool isLoading;
  final String? errorMessage;
  final bool hasVideo;
  final VoidCallback onExtract;
  final String dailyTrainingId;
  final int exerciseIndex;

  const _KeyframeListArea({
    required this.keyframes,
    required this.isLoading,
    this.errorMessage,
    required this.hasVideo,
    required this.onExtract,
    required this.dailyTrainingId,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 状态1：有keyframes - 显示紧凑版关键帧列表
    if (keyframes.isNotEmpty) {
      return _CompactKeyframeList(
        keyframes: keyframes,
        dailyTrainingId: dailyTrainingId,
        exerciseIndex: exerciseIndex,
      );
    }

    // 状态2：正在提取 - 显示进度指示器
    if (isLoading) {
      return _KeyframeExtractingIndicator(exerciseIndex: exerciseIndex);
    }

    // 状态3：提取失败 - 显示错误信息和重试按钮
    if (errorMessage != null) {
      return _KeyframeErrorView(
        errorMessage: errorMessage!,
        onRetry: onExtract,
        isLoading: isLoading,
      );
    }

    // 状态4：有视频但无keyframes - 显示提取按钮
    if (hasVideo) {
      return _KeyframePlaceholder(onExtract: onExtract, isLoading: isLoading);
    }

    // 无视频 - 显示空状态
    return const SizedBox.shrink();
  }
}

/// 紧凑版关键帧列表（用于右侧区域）
class _CompactKeyframeList extends StatelessWidget {
  final List<KeyframeModel> keyframes;
  final String dailyTrainingId;
  final int exerciseIndex;

  const _CompactKeyframeList({
    required this.keyframes,
    required this.dailyTrainingId,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerLight, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: keyframes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final keyframe = keyframes[index];
          final hasImage =
              (keyframe.url != null && keyframe.url!.isNotEmpty) ||
              (keyframe.localPath != null && keyframe.localPath!.isNotEmpty);

          return _CompactKeyframeItem(
            keyframe: keyframe,
            onTap: hasImage
                ? () => _handleKeyframeTap(
                    context,
                    dailyTrainingId,
                    imageUrl: keyframe.url,
                    localPath: keyframe.localPath,
                    exerciseIndex: exerciseIndex,
                    keyframeIndex: index,
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// 单个关键帧项（紧凑版，60px高度）
class _CompactKeyframeItem extends StatelessWidget {
  final KeyframeModel keyframe;
  final VoidCallback? onTap;

  const _CompactKeyframeItem({required this.keyframe, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 关键帧图片（支持本地和远程）
            _buildKeyframeImage(),

            // 时间戳标签（右上角）
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  keyframe.formattedTimestamp,
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.backgroundWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关键帧图片（支持本地文件和远程URL）
  Widget _buildKeyframeImage() {
    final localPath = keyframe.localPath;
    final remoteUrl = keyframe.url;

    // 优先显示本地图片（更快）
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.data == true) {
            // 本地文件存在，显示本地图片
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 本地图片加载失败，尝试显示远程图片
                if (remoteUrl != null && remoteUrl.isNotEmpty) {
                  return _buildRemoteImage(remoteUrl);
                }
                return _buildPlaceholder();
              },
            );
          } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
            // 本地文件已删除，显示远程图片
            return _buildRemoteImage(remoteUrl);
          } else {
            return const Center(child: CupertinoActivityIndicator());
          }
        },
      );
    } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
      // 只有远程URL
      return _buildRemoteImage(remoteUrl);
    } else {
      // 都没有，显示加载中
      return const Center(child: CupertinoActivityIndicator());
    }
  }

  /// 构建远程图片
  Widget _buildRemoteImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const Center(child: CupertinoActivityIndicator()),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        CupertinoIcons.photo,
        color: AppColors.textTertiary,
        size: 20,
      ),
    );
  }
}

/// 关键帧提取失败视图（紧凑版）
class _KeyframeErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final bool isLoading;

  const _KeyframeErrorView({
    required this.errorMessage,
    required this.onRetry,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 32,
            color: AppColors.error,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.extractionFailed,
            style: AppTextStyles.caption1.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              errorMessage,
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isLoading
                ? AppColors.backgroundSecondary
                : AppColors.primaryAction,
            borderRadius: BorderRadius.circular(6),
            onPressed: isLoading ? null : onRetry,
            child: Text(
              l10n.retryExtraction,
              style: AppTextStyles.caption1.copyWith(
                color: isLoading
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 关键帧相关组件 ====================

/// 关键帧占位符（无关键帧时显示）
class _KeyframePlaceholder extends StatelessWidget {
  final VoidCallback onExtract;
  final bool isLoading;

  const _KeyframePlaceholder({
    required this.onExtract,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noKeyframesYet,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isLoading
                ? AppColors.backgroundSecondary
                : AppColors.primary,
            borderRadius: BorderRadius.circular(6),
            onPressed: isLoading ? null : onExtract,
            child: Text(
              l10n.extractKeyframes,
              style: AppTextStyles.caption1.copyWith(
                color: isLoading
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 关键帧提取中指示器
class _KeyframeExtractingIndicator extends ConsumerWidget {
  final int exerciseIndex;

  const _KeyframeExtractingIndicator({required this.exerciseIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progressMap = ref.watch(keyframeExtractionProgressProvider);
    final progressData = progressMap[exerciseIndex];

    final progress = progressData?.progress ?? 0.0;
    final infoText = progressData?.infoText;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.arrow_down_circle,
            size: 32,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          LinearProgressBar(progress: progress, infoText: infoText),
          const SizedBox(height: 8),
          Text(
            l10n.extractingKeyframes,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 处理关键帧提取
Future<void> _handleExtractKeyframes(
  BuildContext context,
  WidgetRef ref,
  int exerciseIndex,
  String trainingId,
  String videoUrl,
) async {
  // 设置loading状态
  final loadingMap = {...ref.read(keyframeExtractionLoadingProvider)};
  loadingMap[exerciseIndex] = true;
  ref.read(keyframeExtractionLoadingProvider.notifier).state = loadingMap;

  // 清除之前的错误
  final errorMap = {...ref.read(keyframeExtractionErrorProvider)};
  errorMap.remove(exerciseIndex);
  ref.read(keyframeExtractionErrorProvider.notifier).state = errorMap;

  // 初始化进度状态
  final progressMap = {...ref.read(keyframeExtractionProgressProvider)};
  progressMap[exerciseIndex] = const KeyframeExtractionProgress(
    progress: 0.0,
    infoText: 'Starting...',
  );
  ref.read(keyframeExtractionProgressProvider.notifier).state = progressMap;

  // 创建本地提取器实例
  final extractor = LocalKeyframeExtractor();

  try {
    // 使用本地提取器，传递进度回调
    await extractor.extractKeyframes(
      videoUrl,
      trainingId,
      exerciseIndex,
      onProgress: (progress, infoText) {
        // 更新进度状态
        final updatedProgressMap = {
          ...ref.read(keyframeExtractionProgressProvider),
        };
        updatedProgressMap[exerciseIndex] = KeyframeExtractionProgress(
          progress: progress,
          infoText: infoText,
        );
        ref.read(keyframeExtractionProgressProvider.notifier).state =
            updatedProgressMap;
      },
    );

    // 成功：清除loading和进度状态（Firestore会自动更新UI）
    final updatedLoadingMap = {...ref.read(keyframeExtractionLoadingProvider)};
    updatedLoadingMap.remove(exerciseIndex);
    ref.read(keyframeExtractionLoadingProvider.notifier).state =
        updatedLoadingMap;

    final updatedProgressMap = {
      ...ref.read(keyframeExtractionProgressProvider),
    };
    updatedProgressMap.remove(exerciseIndex);
    ref.read(keyframeExtractionProgressProvider.notifier).state =
        updatedProgressMap;
  } catch (e) {
    // 失败：设置error状态，清除loading和进度
    final updatedLoadingMap = {...ref.read(keyframeExtractionLoadingProvider)};
    updatedLoadingMap.remove(exerciseIndex);
    ref.read(keyframeExtractionLoadingProvider.notifier).state =
        updatedLoadingMap;

    final updatedErrorMap = {...ref.read(keyframeExtractionErrorProvider)};
    updatedErrorMap[exerciseIndex] = e.toString();
    ref.read(keyframeExtractionErrorProvider.notifier).state = updatedErrorMap;

    final updatedProgressMap = {
      ...ref.read(keyframeExtractionProgressProvider),
    };
    updatedProgressMap.remove(exerciseIndex);
    ref.read(keyframeExtractionProgressProvider.notifier).state =
        updatedProgressMap;
  } finally {
    // 释放资源
    extractor.dispose();
  }
}

/// 从 DailyTrainingModel 计算 TrainingSummary
TrainingSummary _calculateTrainingSummary(DailyTrainingModel dailyTraining) {
  final exercises = dailyTraining.exercises ?? [];
  final exerciseCount = exercises.where((e) => e.completed).length;
  final totalSets = exercises.fold<int>(0, (sum, e) => sum + e.sets.length);
  final completedSets = exercises.fold<int>(
    0,
    (sum, e) => sum + e.completedSetsCount,
  );
  final completionRate = totalSets > 0
      ? (completedSets / totalSets * 100)
      : 0.0;
  final dietCompleted = dailyTraining.diet != null;

  return TrainingSummary(
    exerciseCount: exerciseCount,
    dietCompleted: dietCompleted,
    totalSets: totalSets,
    completionRate: completionRate,
  );
}

/// 处理视频点击（全屏播放）
void _handleVideoPlay(
  BuildContext context,
  VideoUploadState? video,
  String trainingId,
  int exerciseIndex,
  String exerciseName,
) {
  // 检查视频是否存在且有有效的下载URL
  if (video == null ||
      video.downloadUrl == null ||
      video.downloadUrl!.isEmpty) {
    return;
  }

  // 检查视频状态是否为已完成
  if (video.status != VideoUploadStatus.completed) {
    return;
  }

  // 显示全屏播放器
  VideoPlayerDialog.show(
    context,
    videoUrls: [video.downloadUrl!],
    initialIndex: 0,
    dailyTrainingId: trainingId,
    exerciseIndex: exerciseIndex,
    exerciseName: exerciseName,
  );
}

/// 处理关键帧点击
Future<void> _handleKeyframeTap(
  BuildContext context,
  String dailyTrainingId, {
  String? imageUrl,
  String? localPath,
  int? exerciseIndex,
  int? keyframeIndex,
}) async {
  Navigator.of(context).push(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (context) => ImagePreviewPage(
        imageUrl: imageUrl,
        localPath: localPath,
        showEditButton: true,
        dailyTrainingId: dailyTrainingId,
        exerciseIndex: exerciseIndex,
        keyframeIndex: keyframeIndex,
        onImageUpdated: (newUrl) {
          AppLogger.info('关键帧替换成功');
          // Firestore stream will auto-update UI
        },
      ),
    ),
  );
}

/// 显示反馈 Bottom Sheet
void _showFeedbackBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String dailyTrainingId,
  String studentId,
  String exerciseTemplateId,
  String exerciseName,
) {
  FeedbackBottomSheet.show(
    context,
    dailyTrainingId: dailyTrainingId,
    studentId: studentId,
    exerciseTemplateId: exerciseTemplateId,
    exerciseName: exerciseName,
  );
}

/// Info icon with popup widget
class _InfoIconWithPopup extends StatefulWidget {
  const _InfoIconWithPopup();

  @override
  State<_InfoIconWithPopup> createState() => _InfoIconWithPopupState();
}

class _InfoIconWithPopupState extends State<_InfoIconWithPopup>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _showPopup() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _removeOverlay() {
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final l10n = AppLocalizations.of(context)!;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Popup positioned next to icon
          Positioned(
            width: 240,
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.centerRight,
              followerAnchor: Alignment.centerLeft,
              offset: const Offset(10, 0),
              child: FadeTransition(
                opacity: _animationController,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.keyframeEditNote,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_overlayEntry == null) {
            _showPopup();
          } else {
            _removeOverlay();
          }
        },
        child: Icon(
          CupertinoIcons.info_circle,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
