import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/presentation/widgets/exercise_feedback_history_section.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_input_bar.dart';

/// 反馈 Bottom Sheet
///
/// 包含完整的反馈功能（历史 + 输入栏）
/// 支持拖动调整高度
class FeedbackBottomSheet extends ConsumerWidget {
  final String dailyTrainingId;
  final String studentId;
  final String exerciseTemplateId;
  final String exerciseName;

  const FeedbackBottomSheet({
    super.key,
    required this.dailyTrainingId,
    required this.studentId,
    required this.exerciseTemplateId,
    required this.exerciseName,
  });

  /// 显示 Bottom Sheet
  static Future<void> show(
    BuildContext context, {
    required String dailyTrainingId,
    required String studentId,
    required String exerciseTemplateId,
    required String exerciseName,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => FeedbackBottomSheet(
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
                        l10n.exerciseFeedbackHistory(exerciseName),
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

              const SizedBox(height: 8),

              // 反馈历史（可滚动，支持分页）
              Expanded(
                child: ExerciseFeedbackHistorySection(
                  studentId: studentId,
                  exerciseTemplateId: exerciseTemplateId,
                  maxHeight: double.infinity, // 占满可用空间
                  showLoadMoreButton: true, // 显示"加载更多"按钮
                  showHeader: false, // 隐藏内部标题，使用顶部标题栏
                ),
              ),

              // 输入栏（固定在底部）
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.dividerLight, width: 0.5),
                  ),
                ),
                child: FeedbackInputBar(
                  dailyTrainingId: dailyTrainingId,
                  exerciseTemplateId: exerciseTemplateId,
                  exerciseName: exerciseName,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
