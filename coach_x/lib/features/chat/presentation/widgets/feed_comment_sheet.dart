import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/presentation/widgets/exercise_feedback_history_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_input_bar.dart';

/// Feed 评论区 Bottom Sheet
///
/// 支持视频项和图文项的批阅
/// - 视频项：显示该 exercise 的历史反馈（基于 exerciseTemplateId）
/// - 图文项：显示该 dailyTraining 的整体反馈（基于 dailyTrainingId）
class FeedCommentSheet extends ConsumerWidget {
  final String dailyTrainingId;
  final String studentId;
  final String? exerciseTemplateId; // 视频项有值，图文项为 null
  final String? exerciseName;

  const FeedCommentSheet({
    super.key,
    required this.dailyTrainingId,
    required this.studentId,
    this.exerciseTemplateId,
    this.exerciseName,
  });

  /// 显示 Bottom Sheet
  static Future<void> show(
    BuildContext context, {
    required String dailyTrainingId,
    required String studentId,
    String? exerciseTemplateId,
    String? exerciseName,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => FeedCommentSheet(
        dailyTrainingId: dailyTrainingId,
        studentId: studentId,
        exerciseTemplateId: exerciseTemplateId,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isVideoItem = exerciseTemplateId != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),

              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isVideoItem
                            ? l10n.exerciseFeedbackHistory(exerciseName ?? '')
                            : l10n.dailyTrainingFeedback,
                        style: AppTextStyles.title3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.textTertiary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 历史反馈区域
              Expanded(
                child: isVideoItem
                    ? ExerciseFeedbackHistorySection(
                        studentId: studentId,
                        exerciseTemplateId: exerciseTemplateId!,
                        scrollController: scrollController,
                      )
                    : _DailyTrainingFeedbackSection(
                        dailyTrainingId: dailyTrainingId,
                        scrollController: scrollController,
                      ),
              ),

              // 输入栏
              FeedbackInputBar(
                dailyTrainingId: dailyTrainingId,
                exerciseTemplateId: exerciseTemplateId,
                exerciseName: exerciseName,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 图文项反馈区域（整体反馈）
class _DailyTrainingFeedbackSection extends ConsumerWidget {
  final String dailyTrainingId;
  final ScrollController scrollController;

  const _DailyTrainingFeedbackSection({
    required this.dailyTrainingId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // TODO: 使用 getDailyTrainingFeedbacks 查询图文项反馈
    // final feedbacksAsync = ref.watch(dailyTrainingFeedbacksProvider(dailyTrainingId));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          l10n.noDailyTrainingFeedbackYet,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
