import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/models/voice_record_state.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/voice_recorder.dart';
import 'package:coach_x/core/widgets/image_editor_page.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/app/providers.dart';

/// 反馈输入栏
///
/// 支持文字、语音、图片三种输入方式
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
  final TextEditingController _textController = TextEditingController();
  final VoiceRecorder _voiceRecorder = VoiceRecorder();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(isSubmittingFeedbackProvider);
    final voiceState = ref.watch(feedbackVoiceStateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 主输入栏
            Row(
              children: [
                // 语音按钮
                _VoiceRecordButton(
                  onLongPressStart: _handleVoiceRecordStart,
                  onLongPressEnd: _handleVoiceRecordEnd,
                  onLongPressMoveUpdate: _handleVoiceRecordMove,
                  isRecording: voiceState.isRecording,
                ),
                const SizedBox(width: 8),
                // 文本输入框
                Expanded(
                  child: _TextInputField(
                    controller: _textController,
                    enabled: !isSubmitting && !voiceState.isRecording,
                    onChanged: (value) {
                      print('🔍 [FeedbackInputBar] Text changed: "$value"');
                      ref.read(feedbackTextInputProvider.notifier).state =
                          value;
                      final updatedValue = ref.read(feedbackTextInputProvider);
                      print('📊 [FeedbackInputBar] Provider updated to: "$updatedValue"');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 图片按钮
                _ImagePickButton(
                  onTap: _handleImagePick,
                  enabled: !isSubmitting && !voiceState.isRecording,
                ),
                const SizedBox(width: 8),
                // 发送按钮
                _SendButton(
                  onTap: _handleSend,
                  enabled: !isSubmitting && _canSend(),
                ),
              ],
            ),
            // 录制浮层
            if (voiceState.isRecording)
              Positioned.fill(
                child: _VoiceRecordingOverlay(duration: voiceState.duration),
              ),
          ],
        ),
      ),
    );
  }

  bool _canSend() {
    final textInput = ref.read(feedbackTextInputProvider);
    final voiceState = ref.read(feedbackVoiceStateProvider);
    final imageState = ref.read(feedbackImageStateProvider);

    final canSend = textInput.trim().isNotEmpty ||
        voiceState.isCompleted ||
        imageState != null;

    print('🔍 [_canSend] textInput: "$textInput", voiceCompleted: ${voiceState.isCompleted}, hasImage: ${imageState != null}, canSend: $canSend');
    return canSend;
  }

  // ==================== 语音录制处理 ====================

  void _handleVoiceRecordStart(LongPressStartDetails details) async {
    try {
      AppLogger.info('开始录音');
      await _voiceRecorder.startRecording();

      ref
          .read(feedbackVoiceStateProvider.notifier)
          .state = const VoiceRecordState(
        status: VoiceRecordStatus.recording,
        duration: 0,
      );

      // 监听录制时长
      _voiceRecorder.recordingDuration.listen((duration) {
        if (mounted) {
          ref.read(feedbackVoiceStateProvider.notifier).state = ref
              .read(feedbackVoiceStateProvider)
              .copyWith(duration: duration.inSeconds);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('开始录音失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToStartRecording);
      }
    }
  }

  void _handleVoiceRecordEnd(LongPressEndDetails details) async {
    try {
      final currentState = ref.read(feedbackVoiceStateProvider);
      if (!currentState.isRecording) return;

      // 检查录制时长（至少1秒）
      if (currentState.duration < 1) {
        AppLogger.warning('录音时长过短');
        await _voiceRecorder.cancelRecording();
        ref.read(feedbackVoiceStateProvider.notifier).state =
            const VoiceRecordState();
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.voiceTooShort);
        return;
      }

      // 停止录制
      final filePath = await _voiceRecorder.stopRecording();
      AppLogger.info('录音完成: $filePath');

      ref.read(feedbackVoiceStateProvider.notifier).state = currentState
          .copyWith(status: VoiceRecordStatus.completed, filePath: filePath);

      // 自动发送语音
      await _sendVoiceFeedback(filePath, currentState.duration);
    } catch (e, stackTrace) {
      AppLogger.error('停止录音失败', e, stackTrace);
      ref.read(feedbackVoiceStateProvider.notifier).state =
          const VoiceRecordState();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToStopRecording);
      }
    }
  }

  void _handleVoiceRecordMove(LongPressMoveUpdateDetails details) {
    // 上滑取消录制（手势 Y 坐标 < -50）
    if (details.localOffsetFromOrigin.dy < -50) {
      _handleVoiceRecordCancel();
    }
  }

  void _handleVoiceRecordCancel() async {
    try {
      AppLogger.info('取消录音');
      await _voiceRecorder.cancelRecording();
      ref.read(feedbackVoiceStateProvider.notifier).state =
          const VoiceRecordState(status: VoiceRecordStatus.cancelled);

      // 重置状态
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(feedbackVoiceStateProvider.notifier).state =
              const VoiceRecordState();
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('取消录音失败', e, stackTrace);
    }
  }

  // ==================== 图片选择处理 ====================

  void _handleImagePick() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      AppLogger.info('选择图片: ${image.path}');

      // 跳转到编辑器
      final bytes = await Navigator.of(context).push<Uint8List?>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => ImageEditorPage(localPath: image.path),
        ),
      );

      if (bytes == null) {
        // 用户取消编辑
        AppLogger.info('用户取消图片编辑');
        return;
      }

      // 上传编辑后的图片
      await _sendEditedImageFeedback(bytes);
    } catch (e, stackTrace) {
      AppLogger.error('选择图片失败', e, stackTrace);
      final l10n = AppLocalizations.of(context)!;
      _showError(l10n.failedToPickImage);
    }
  }

  // ==================== 发送处理 ====================

  void _handleSend() async {
    print('🔍 [_handleSend] Called');
    final textInput = ref.read(feedbackTextInputProvider);
    print('📊 [_handleSend] textInput from provider: "$textInput"');

    if (textInput.trim().isEmpty) {
      print('❌ [_handleSend] Text is empty, returning');
      return;
    }

    print('✅ [_handleSend] Calling _sendTextFeedback with: "${textInput.trim()}"');
    await _sendTextFeedback(textInput.trim());
  }

  Future<void> _sendTextFeedback(String text) async {
    try {
      print('📤 [_sendTextFeedback] Start');
      print('📊 [_sendTextFeedback] text: "$text"');
      print('📊 [_sendTextFeedback] dailyTrainingId: ${widget.dailyTrainingId}');
      print('📊 [_sendTextFeedback] exerciseTemplateId: ${widget.exerciseTemplateId}');
      print('📊 [_sendTextFeedback] exerciseName: ${widget.exerciseName}');

      ref.read(isSubmittingFeedbackProvider.notifier).state = true;
      print('📊 [_sendTextFeedback] isSubmitting set to true');

      print('📊 [_sendTextFeedback] Fetching reviewData...');
      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) {
        print('❌ [_sendTextFeedback] reviewData is null');
        throw Exception('Review data not found');
      }
      print('✅ [_sendTextFeedback] reviewData fetched successfully');

      final repository = ref.read(feedbackRepositoryProvider);
      print('📊 [_sendTextFeedback] Calling repository.addFeedback...');
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
      print('✅ [_sendTextFeedback] repository.addFeedback completed');

      // 清空输入
      _textController.clear();
      ref.read(feedbackTextInputProvider.notifier).state = '';
      print('📊 [_sendTextFeedback] Input cleared');

      AppLogger.info('发送文字反馈成功');
    } catch (e, stackTrace) {
      print('❌ [_sendTextFeedback] Error: $e');
      AppLogger.error('发送文字反馈失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToSendFeedback);
      }
    } finally {
      ref.read(isSubmittingFeedbackProvider.notifier).state = false;
      print('📊 [_sendTextFeedback] isSubmitting set to false');
    }
  }

  Future<void> _sendVoiceFeedback(String filePath, int duration) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) {
        throw Exception('Review data not found');
      }

      final repository = ref.read(feedbackRepositoryProvider);

      // 上传语音文件
      final voiceUrl = await repository.uploadVoiceFile(
        filePath,
        widget.dailyTrainingId,
      );

      // 保存反馈
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

      // 重置语音状态
      ref.read(feedbackVoiceStateProvider.notifier).state =
          const VoiceRecordState();

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

  Future<void> _sendImageFeedback(String filePath) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) {
        throw Exception('Review data not found');
      }

      final repository = ref.read(feedbackRepositoryProvider);

      // 上传图片文件
      final imageUrl = await repository.uploadImageFile(
        filePath,
        widget.dailyTrainingId,
      );

      // 保存反馈
      await repository.addFeedback(
        dailyTrainingId: widget.dailyTrainingId,
        studentId: reviewData.dailyTraining.studentId,
        coachId: reviewData.dailyTraining.coachId,
        trainingDate: reviewData.dailyTraining.date,
        feedbackType: 'image',
        imageUrl: imageUrl,
      );

      // 重置图片状态
      ref.read(feedbackImageStateProvider.notifier).state = null;

      AppLogger.info('发送图片反馈成功');
    } catch (e, stackTrace) {
      AppLogger.error('发送图片反馈失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToSendFeedback);
      }
    } finally {
      ref.read(isSubmittingFeedbackProvider.notifier).state = false;
    }
  }

  /// 发送编辑后的图片反馈
  Future<void> _sendEditedImageFeedback(Uint8List bytes) async {
    try {
      ref.read(isSubmittingFeedbackProvider.notifier).state = true;

      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId).future,
      );

      if (reviewData == null) {
        throw Exception('Review data not found');
      }

      final repository = ref.read(feedbackRepositoryProvider);

      // 上传编辑后的图片字节数据
      final imageUrl = await repository.uploadEditedImageBytes(
        bytes,
        widget.dailyTrainingId,
      );

      // 保存反馈
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
            child: Text(l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ==================== 子组件 ====================

/// 语音录制按钮
class _VoiceRecordButton extends StatelessWidget {
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressEndDetails) onLongPressEnd;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final bool isRecording;

  const _VoiceRecordButton({
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressMoveUpdate,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isRecording ? AppColors.error : AppColors.backgroundSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.mic,
          color: isRecording ? AppColors.background : AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

/// 录制中浮层
class _VoiceRecordingOverlay extends StatelessWidget {
  final int duration; // 时长（秒）

  const _VoiceRecordingOverlay({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.waveform,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '${duration}s',
              style: AppTextStyles.title1.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.slideUpToCancel,
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 文本输入框
class _TextInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _TextInputField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoTextField(
      controller: controller,
      enabled: enabled,
      placeholder: l10n.feedbackInputPlaceholder,
      style: AppTextStyles.body,
      placeholderStyle: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      maxLines: 4,
      minLines: 1,
      onChanged: onChanged,
    );
  }
}

/// 图片选择按钮
class _ImagePickButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _ImagePickButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.photo,
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

/// 发送按钮
class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _SendButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    print('🔍 [_SendButton] build, enabled: $enabled');
    return GestureDetector(
      onTap: enabled ? () {
        print('🔍 [_SendButton] onTap triggered!');
        onTap();
      } : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.backgroundSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.arrow_up,
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
