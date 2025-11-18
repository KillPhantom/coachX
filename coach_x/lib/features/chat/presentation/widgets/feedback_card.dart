import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';

/// 训练反馈卡片组件
///
/// 显示训练反馈的摘要信息：
/// - 训练日期
/// - 反馈类型和 exercise 信息
/// - 反馈内容预览
/// - 点击跳转到详情页
class FeedbackCard extends StatelessWidget {
  final TrainingFeedbackModel feedback;

  const FeedbackCard({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 跳转到训练详情页（使用 dailyTrainingId）
        context.push('/training-review/${feedback.dailyTrainingId}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
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
            // 顶部：训练日期
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Exercise 名称（如果有）
                if (feedback.exerciseName != null)
                  Text(
                    feedback.exerciseName!,
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                // 训练日期
                Text(
                  _formatDate(feedback.trainingDate),
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 反馈类型标签
            Text(
              _getFeedbackTypeLabel(),
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // 反馈内容预览
            Text(
              _getContentPreview(),
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 获取反馈类型标签
  String _getFeedbackTypeLabel() {
    switch (feedback.feedbackType) {
      case 'text':
        return feedback.isExerciseFeedback
            ? 'Exercise Feedback'
            : 'Overall Feedback';
      case 'voice':
        return 'Voice Feedback';
      case 'image':
        return 'Image Feedback';
      default:
        return 'Feedback';
    }
  }

  /// 获取内容预览
  String _getContentPreview() {
    switch (feedback.feedbackType) {
      case 'text':
        return feedback.textContent ?? '';
      case 'voice':
        final duration = feedback.voiceDuration ?? 0;
        return 'Voice message ($duration seconds)';
      case 'image':
        return 'Image attachment';
      default:
        return '';
    }
  }

  /// 格式化日期显示
  /// 格式: "MMM d, yyyy" (e.g., "Oct 26, 2024")
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
