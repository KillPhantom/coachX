import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/models/voice_record_state.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/voice_recorder.dart';
import 'package:coach_x/core/widgets/image_editor_page.dart';

/// 通用输入栏状态 Provider
final commonInputVoiceStateProvider =
    StateProvider.autoDispose<VoiceRecordState>((ref) {
  return const VoiceRecordState();
});

final commonInputTextProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

/// 通用输入栏
/// 支持文字、语音、图片、视频输入
class CommonInputBar extends ConsumerStatefulWidget {
  final Future<void> Function(String text) onSendText;
  final Future<void> Function(String path, int duration) onSendVoice;
  final Future<void> Function(Uint8List bytes) onSendImage;
  final Future<void> Function(String path) onSendVideo;
  final bool isSubmitting;

  const CommonInputBar({
    super.key,
    required this.onSendText,
    required this.onSendVoice,
    required this.onSendImage,
    required this.onSendVideo,
    this.isSubmitting = false,
  });

  @override
  ConsumerState<CommonInputBar> createState() => _CommonInputBarState();
}

class _CommonInputBarState extends ConsumerState<CommonInputBar> {
  final TextEditingController _textController = TextEditingController();
  final VoiceRecorder _voiceRecorder = VoiceRecorder();
  final ImagePicker _imagePicker = ImagePicker();

  // 是否处于语音输入模式
  bool _isVoiceInputMode = false;

  OverlayEntry? _recordingOverlayEntry;

  @override
  void dispose() {
    _textController.dispose();
    _voiceRecorder.dispose();
    _recordingOverlayEntry?.remove();
    _recordingOverlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(commonInputVoiceStateProvider);
    final textInput = ref.watch(commonInputTextProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 1. 左侧语音/键盘切换按钮
            _IconButton(
              icon: _isVoiceInputMode
                  ? CupertinoIcons.keyboard
                  : CupertinoIcons.mic,
              onTap: () {
                setState(() {
                  _isVoiceInputMode = !_isVoiceInputMode;
                });
              },
            ),
            const SizedBox(width: 8),

            // 2. 中间输入区域
            Expanded(
              child: _isVoiceInputMode
                  ? _HoldToSpeakButton(
                      onLongPressStart: _handleVoiceRecordStart,
                      onLongPressEnd: _handleVoiceRecordEnd,
                      onLongPressMoveUpdate: _handleVoiceRecordMove,
                      isRecording: voiceState.isRecording,
                    )
                  : _TextInputField(
                      controller: _textController,
                      enabled: !widget.isSubmitting && !voiceState.isRecording,
                      onChanged: (value) {
                        ref.read(commonInputTextProvider.notifier).state =
                            value;
                      },
                    ),
            ),
            const SizedBox(width: 8),

            // 3. 右侧按钮区域 (发送 或 媒体选择)
            if (textInput.trim().isNotEmpty)
              _SendButton(
                onTap: _handleSend,
                enabled: !widget.isSubmitting,
              )
            else
              _IconButton(
                icon: CupertinoIcons.add_circled,
                onTap: _handleGalleryPick,
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 语音录制处理 ====================

  void _handleVoiceRecordStart(LongPressStartDetails details) async {
    try {
      AppLogger.info('开始录音');
      await _voiceRecorder.startRecording();

      // 显示全屏覆盖层
      _showRecordingOverlay();

      ref.read(commonInputVoiceStateProvider.notifier).state =
          const VoiceRecordState(
        status: VoiceRecordStatus.recording,
        duration: 0,
      );

      // 监听录制时长
      _voiceRecorder.recordingDuration.listen((duration) {
        if (mounted) {
          ref.read(commonInputVoiceStateProvider.notifier).state = ref
              .read(commonInputVoiceStateProvider)
              .copyWith(duration: duration.inSeconds);
        }
      });
    } catch (e, stackTrace) {
      _hideRecordingOverlay();
      AppLogger.error('开始录音失败', e, stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.failedToStartRecording);
      }
    }
  }

  void _showRecordingOverlay() {
    if (_recordingOverlayEntry != null) return;

    _recordingOverlayEntry = OverlayEntry(
      builder: (context) => const _VoiceRecordingOverlay(),
    );

    Overlay.of(context).insert(_recordingOverlayEntry!);
  }

  void _hideRecordingOverlay() {
    _recordingOverlayEntry?.remove();
    _recordingOverlayEntry = null;
  }

  void _handleVoiceRecordEnd(LongPressEndDetails details) async {
    _hideRecordingOverlay(); // 立即隐藏
    try {
      final currentState = ref.read(commonInputVoiceStateProvider);
      if (!currentState.isRecording) return;

      // 检查录制时长（至少1秒）
      if (currentState.duration < 1) {
        AppLogger.warning('录音时长过短');
        await _voiceRecorder.cancelRecording();
        ref.read(commonInputVoiceStateProvider.notifier).state =
            const VoiceRecordState();
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showError(l10n.voiceTooShort);
        }
        return;
      }

      // 停止录制
      final filePath = await _voiceRecorder.stopRecording();
      AppLogger.info('录音完成: $filePath');

      ref.read(commonInputVoiceStateProvider.notifier).state = currentState
          .copyWith(status: VoiceRecordStatus.completed, filePath: filePath);

      // 发送语音回调
      await widget.onSendVoice(filePath, currentState.duration);

      // 重置状态
      ref.read(commonInputVoiceStateProvider.notifier).state =
          const VoiceRecordState();
    } catch (e, stackTrace) {
      AppLogger.error('停止录音失败', e, stackTrace);
      ref.read(commonInputVoiceStateProvider.notifier).state =
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
    _hideRecordingOverlay();
    try {
      AppLogger.info('取消录音');
      await _voiceRecorder.cancelRecording();
      ref.read(commonInputVoiceStateProvider.notifier).state =
          const VoiceRecordState(status: VoiceRecordStatus.cancelled);

      // 重置状态
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(commonInputVoiceStateProvider.notifier).state =
              const VoiceRecordState();
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('取消录音失败', e, stackTrace);
    }
  }

  // ==================== 媒体选择处理 ====================

  Future<void> _handleGalleryPick() async {
    try {
      final media = await _imagePicker.pickMedia();

      if (media == null) return;

      AppLogger.info('选择媒体: ${media.path}');
      final path = media.path.toLowerCase();
      final isVideo = path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.m4v');

      if (isVideo) {
        await widget.onSendVideo(media.path);
      } else {
        // Assume image
        if (!mounted) return;
        final bytes = await Navigator.of(context).push<Uint8List?>(
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => ImageEditorPage(localPath: media.path),
          ),
        );

        if (bytes == null) {
          AppLogger.info('用户取消图片编辑');
          return;
        }

        await widget.onSendImage(bytes);
      }
    } catch (e, stackTrace) {
      AppLogger.error('选择媒体失败', e, stackTrace);
      if (mounted) {
        // final l10n = AppLocalizations.of(context)!;
        _showError('Failed to pick media'); // TODO: Localize
      }
    }
  }

  // ==================== 发送处理 ====================

  void _handleSend() async {
    final textInput = ref.read(commonInputTextProvider);
    if (textInput.trim().isEmpty) return;

    try {
      await widget.onSendText(textInput.trim());

      // 清空输入
      _textController.clear();
      ref.read(commonInputTextProvider.notifier).state = '';
    } catch (e) {
      // Error handling is done in callback usually, but fallback here
      AppLogger.error('CommonInputBar send error', e);
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

// ==================== 子组件 ====================

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _SendButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 50,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '发送', // TODO: Localize
          style: TextStyle(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _HoldToSpeakButton extends StatelessWidget {
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressEndDetails) onLongPressEnd;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final bool isRecording;

  const _HoldToSpeakButton({
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
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isRecording
              ? AppColors.textSecondary.withOpacity(0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Text(
          isRecording ? '松开 发送' : '按住 说话', // TODO: Localize
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _VoiceRecordingOverlay extends ConsumerWidget {
  const _VoiceRecordingOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(commonInputVoiceStateProvider);
    final duration = voiceState.duration;

    return Container(
      color: Colors.black12,
      child: Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.mic,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                '${duration}s',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                '松开 发送',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Text(
                '上滑 取消',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return CupertinoTextField(
      controller: controller,
      enabled: enabled,
      placeholder: '',
      style: AppTextStyles.body,
      placeholderStyle: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      maxLines: 4,
      minLines: 1,
      onChanged: onChanged,
      textInputAction: TextInputAction.newline,
    );
  }
}

