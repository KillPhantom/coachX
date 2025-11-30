import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/common_input_bar.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:path_provider/path_provider.dart';

/// 反馈输入栏
///
/// 支持文字、语音、图片、视频输入
/// 仿微信交互风格
class FeedbackInputBar extends ConsumerStatefulWidget {
  final String dailyTrainingId;
  final String? exerciseName;
  final String? exerciseTemplateId;

  const FeedbackInputBar({
    super.key,
    required this.dailyTrainingId,
    this.exerciseName,
    this.exerciseTemplateId,
  });

  @override
  ConsumerState<FeedbackInputBar> createState() => _FeedbackInputBarState();
}

class _FeedbackInputBarState extends ConsumerState<FeedbackInputBar> {
  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(isSubmittingFeedbackProvider);

    return CommonInputBar(
      isSubmitting: isSubmitting,
      onSendText: _sendTextFeedback,
      onSendVoice: _sendVoiceFeedback,
      onSendImage: _sendEditedImageFeedback,
      onSendVideo: _sendVideoFeedback,
    );
  }

  // ==================== 发送处理 ====================

  Future<void> _sendTextFeedback(String text) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) throw Exception('Review data not found');

      final repository = ref.read(feedbackRepositoryProvider);
      await repository.addFeedback(
        dailyTrainingId: widget.dailyTrainingId,
        studentId: reviewData.dailyTraining.studentId,
        coachId: reviewData.dailyTraining.coachId,
        trainingDate: reviewData.dailyTraining.date,
        exerciseTemplateId: widget.exerciseTemplateId,
        exerciseName: widget.exerciseName,
        feedbackType: 'text',
        textContent: text,
      );

      AppLogger.info('发送文字反馈成功');
    } catch (e, stackTrace) {
      AppLogger.error('发送文字反馈失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToSendFeedback);
      }
    } finally {
      ref.read(isSubmittingFeedbackProvider.notifier).state = false;
    }
  }

  Future<void> _sendVoiceFeedback(String filePath, int duration) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) throw Exception('Review data not found');

      final repository = ref.read(feedbackRepositoryProvider);

      final voiceUrl = await repository.uploadVoiceFile(
        filePath,
        widget.dailyTrainingId,
      );

      await repository.addFeedback(
        dailyTrainingId: widget.dailyTrainingId,
        studentId: reviewData.dailyTraining.studentId,
        coachId: reviewData.dailyTraining.coachId,
        trainingDate: reviewData.dailyTraining.date,
        exerciseTemplateId: widget.exerciseTemplateId,
        exerciseName: widget.exerciseName,
        feedbackType: 'voice',
        voiceUrl: voiceUrl,
        voiceDuration: duration,
      );

      // 删除本地文件
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      AppLogger.info('发送语音反馈成功');
    } catch (e, stackTrace) {
      AppLogger.error('发送语音反馈失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToSendVoice);
      }
    } finally {
      ref.read(isSubmittingFeedbackProvider.notifier).state = false;
    }
  }

  Future<void> _sendEditedImageFeedback(Uint8List bytes) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) throw Exception('Review data not found');

      final repository = ref.read(feedbackRepositoryProvider);

      final imageUrl = await repository.uploadEditedImageBytes(
        bytes,
        widget.dailyTrainingId,
      );

      await repository.addFeedback(
        dailyTrainingId: widget.dailyTrainingId,
        studentId: reviewData.dailyTraining.studentId,
        coachId: reviewData.dailyTraining.coachId,
        trainingDate: reviewData.dailyTraining.date,
        exerciseTemplateId: widget.exerciseTemplateId,
        exerciseName: widget.exerciseName,
        feedbackType: 'image',
        imageUrl: imageUrl,
      );

      AppLogger.info('发送编辑后图片反馈成功');
    } catch (e, stackTrace) {
      AppLogger.error('发送编辑后图片反馈失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToSendFeedback);
      }
    } finally {
      ref.read(isSubmittingFeedbackProvider.notifier).state = false;
    }
  }

  Future<void> _sendVideoFeedback(String filePath) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) throw Exception('Review data not found');
      
      // 1. 生成缩略图
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: filePath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 512,
        quality: 75,
      );

      if (thumbnailPath == null) throw Exception('Failed to generate thumbnail');

      final repository = ref.read(feedbackRepositoryProvider);

      // 2. 上传视频和缩略图 (可以并发)
      final results = await Future.wait([
        repository.uploadVideoFile(filePath, widget.dailyTrainingId),
        repository.uploadVideoThumbnail(thumbnailPath, widget.dailyTrainingId),
      ]);
      
      final videoUrl = results[0];
      final thumbnailUrl = results[1];

      // 3. 获取视频时长 (可以使用 video_player 或其他方式，这里暂时简化或估算，或者需要额外库)
      // 目前 image_picker 返回的 XFile 没有直接 duration，需要 video_player controller 或 flutter_video_info
      // 暂时设为 null 或 0，后续优化
      int? duration = 0; 

      await repository.addFeedback(
        dailyTrainingId: widget.dailyTrainingId,
        studentId: reviewData.dailyTraining.studentId,
        coachId: reviewData.dailyTraining.coachId,
        trainingDate: reviewData.dailyTraining.date,
        exerciseTemplateId: widget.exerciseTemplateId,
        exerciseName: widget.exerciseName,
        feedbackType: 'video',
        videoUrl: videoUrl,
        videoThumbnailUrl: thumbnailUrl,
        videoDuration: duration,
      );
      
      // Cleanup
      final thumbFile = File(thumbnailPath);
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }

      AppLogger.info('发送视频反馈成功');
    } catch (e, stackTrace) {
      AppLogger.error('发送视频反馈失败', e, stackTrace);
      if (mounted) {
        // final l10n = AppLocalizations.of(context)!;
        _showError('Failed to send video feedback'); // TODO: Localize
      }
    } finally {
      ref.read(isSubmittingFeedbackProvider.notifier).state = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok, style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
