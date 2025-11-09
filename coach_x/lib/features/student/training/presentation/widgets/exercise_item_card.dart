import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'video_player_modal.dart';

/// 单个动作卡片组件
///
/// 显示动作名称、所有 TrainingSet、视频链接、Coach Notes
class ExerciseItemCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseItemCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.dividerLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动作名称
          Text(exercise.name, style: AppTextStyles.callout),
          const SizedBox(height: AppDimensions.spacingS),

          // 显示所有 TrainingSet
          _buildTrainingSets(l10n),

          // Coach Notes
          if (exercise.note.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
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

          // 视频链接
          if (exercise.demoVideos.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            GestureDetector(
              onTap: () {
                VideoPlayerModal.show(context, videoUrls: exercise.demoVideos);
              },
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.play_circle,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Text(
                    l10n.video,
                    style: AppTextStyles.subhead.copyWith(
                      color: AppColors.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainingSets(AppLocalizations l10n) {
    if (exercise.sets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: 4,
      children: exercise.sets.asMap().entries.map((entry) {
        final set = entry.value;

        // 构建显示文本
        final repsText = set.reps.isNotEmpty
            ? 'x ${set.reps} ${l10n.reps}'
            : '';
        final weightText = set.weight.isNotEmpty
            ? '@ ${set.weight} ${l10n.kg}'
            : '';

        String displayText = '';
        if (repsText.isNotEmpty && weightText.isNotEmpty) {
          displayText = '$repsText $weightText';
        } else if (repsText.isNotEmpty) {
          displayText = repsText;
        } else if (weightText.isNotEmpty) {
          displayText = weightText;
        }

        if (displayText.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            displayText,
            style: AppTextStyles.caption2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
