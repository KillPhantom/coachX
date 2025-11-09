import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_providers.dart';
import 'media_picker_sheet.dart';

/// 消息输入栏组件
/// 包含媒体按钮、文本输入框、发送按钮
class MessageInputBar extends ConsumerStatefulWidget {
  final String conversationId;
  final VoidCallback onMessageSent;

  const MessageInputBar({
    super.key,
    required this.conversationId,
    required this.onMessageSent,
  });

  @override
  ConsumerState<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends ConsumerState<MessageInputBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 监听输入框变化
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // 更新输入文本到 provider
    ref.read(messageInputTextProvider.notifier).state = _textController.text
        .trim();
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 防止重复发送
    final isSending = ref.read(isSendingMessageProvider);
    if (isSending) return;

    try {
      // 设置发送状态
      ref.read(isSendingMessageProvider.notifier).state = true;

      // 获取当前用户
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        final l10n = AppLocalizations.of(context)!;
        throw Exception(l10n.userNotLoggedIn);
      }

      // 获取对话信息
      final conversationAsync = await ref.read(
        conversationDetailProvider(widget.conversationId).future,
      );

      if (conversationAsync == null) {
        throw Exception('对话不存在');
      }

      // 获取接收者ID
      final receiverId = conversationAsync.getOtherUserId(currentUser.id);

      // 调用Repository发送消息
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.sendMessage(
        conversationId: widget.conversationId,
        receiverId: receiverId,
        type: MessageType.text,
        content: text,
      );

      // 发送成功，清空输入框
      _textController.clear();
      ref.read(messageInputTextProvider.notifier).state = '';

      // 通知父组件消息已发送
      widget.onMessageSent();
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.sendFailed),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      // 恢复发送状态
      ref.read(isSendingMessageProvider.notifier).state = false;
    }
  }

  /// 显示媒体选择器
  void _showMediaPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => MediaPickerSheet(
        conversationId: widget.conversationId,
        onMediaPicked: (String mediaUrl, String mediaType) {
          // TODO: 发送媒体消息
          widget.onMessageSent();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasText = ref.watch(messageInputTextProvider).isNotEmpty;
    final uploadProgress = ref.watch(mediaUploadProgressProvider);
    final isSending = ref.watch(isSendingMessageProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          top: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 媒体按钮
          if (!uploadProgress.isUploading)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: _showMediaPicker,
              child: const Icon(
                CupertinoIcons.photo,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),

          // 上传进度指示器
          if (uploadProgress.isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 6),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CupertinoActivityIndicator(
                      radius: 12,
                      color: AppColors.primary,
                    ),
                    Text(
                      '${(uploadProgress.progress * 100).toInt()}%',
                      style: AppTextStyles.caption2.copyWith(
                        color: AppColors.primary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 8),

          // 文本输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoTextField(
                controller: _textController,
                focusNode: _focusNode,
                placeholder: l10n.messageInputPlaceholder,
                placeholderStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textTertiary,
                ),
                style: AppTextStyles.body,
                decoration: null,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 发送按钮
          GestureDetector(
            onTap: (hasText && !isSending) ? _sendMessage : null,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: (hasText && !isSending)
                    ? AppColors.primaryAction
                    : AppColors.primaryAction.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const CupertinoActivityIndicator(
                      radius: 8,
                      color: AppColors.textPrimary,
                    )
                  : Icon(
                      CupertinoIcons.arrow_up,
                      color: hasText
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.5),
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
