import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/student/training/data/models/student_exercise_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/core/enums/video_source.dart';
import 'package:coach_x/core/widgets/video_upload_section.dart';
import 'set_input_row.dart';
import 'exercise_time_header.dart';

/// 动作记录卡片（增强版）
///
/// 集成 Set 编辑、教练备注、视频录制功能
class ExerciseRecordCard extends StatelessWidget {
  final StudentExerciseModel exercise;
  final int exerciseIndex;
  final Function(int setIndex, String reps, String weight) onSetComplete;
  final Function(int setIndex) onToggleSetEdit;
  final VoidCallback onQuickComplete;
  final Function(File) onVideoUploaded;
  final Function(int) onVideoDeleted;
  final Function(int)? onVideoRetry;
  final Function(int videoIndex, String downloadUrl, String? thumbnailUrl)?
  onVideoUploadCompleted;
  final bool isSaving;

  const ExerciseRecordCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onSetComplete,
    required this.onToggleSetEdit,
    required this.onQuickComplete,
    required this.onVideoUploaded,
    required this.onVideoDeleted,
    this.onVideoRetry,
    this.onVideoUploadCompleted,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: exercise.completed
            ? Border.all(color: AppColors.successGreen, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise 耗时 Header（如果已完成）
          if (exercise.timeSpent != null) ...[
            ExerciseTimeHeader(timeSpent: exercise.timeSpent!),
            const SizedBox(height: AppDimensions.spacingS),
          ],

          // 动作名称 + 快捷完成按钮
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                size: 24,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.name,
                  style: AppTextStyles.callout.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: isSaving ? null : onQuickComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: exercise.completed
                        ? AppColors.primaryColor
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    exercise.completed ? l10n.completed : l10n.quickComplete,
                    style: AppTextStyles.footnote.copyWith(
                      color: exercise.completed
                          ? AppColors.primaryText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // 教练备注（移到 Sets 之前）
          if (exercise.note.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.coachNote}:',
                    style: AppTextStyles.caption2.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.note,
                    style: AppTextStyles.subhead.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // Sets 列表（每个 Set 一行）
          ...List.generate(exercise.sets.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: SetInputRow(
                set: exercise.sets[index],
                setNumber: index + 1,
                onComplete: (reps, weight) =>
                    onSetComplete(index, reps, weight),
                onToggleEdit: () => onToggleSetEdit(index),
              ),
            );
          }),

          // My Recordings
          const SizedBox(height: AppDimensions.spacingM),
          VideoUploadSection(
            storagePathPrefix:
                'students/trainings/${FirebaseAuth.instance.currentUser!.uid}/',
            maxVideos: 3,
            maxSeconds: 60,
            videoSource: VideoSource.both,
            initialVideos: exercise.videos,
            onVideoSelected: (index, file) {
              // 添加 pending 状态视频到 notifier（不启动上传）
              // 上传由 VideoUploadSection 负责
              onVideoUploaded(file);
            },
            onUploadCompleted: (index, videoUrl, thumbnailUrl) {
              // 视频上传完成，同步状态到 notifier 并保存
              onVideoUploadCompleted?.call(index, videoUrl, thumbnailUrl);
            },
            onVideoDeleted: (index) {
              onVideoDeleted(index);
            },
          ),
        ],
      ),
    );
  }
}
