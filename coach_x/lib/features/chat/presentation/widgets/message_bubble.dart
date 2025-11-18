import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'media_message_widget.dart';

/// 消息气泡组件
/// 根据发送者显示左对齐或右对齐的消息气泡
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  /// 是否是我发送的消息
  bool get _isMine => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: _isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 对方消息：左侧显示
          if (!_isMine) _buildBubble(context),
          // 我的消息：右侧显示
          if (_isMine) _buildBubble(context),
        ],
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildBubble(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageMenu(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: _isMine
              ? AppColors
                    .primaryAction // 我的消息：暖色
              : CupertinoColors.systemGrey5.resolveFrom(context), // 对方：灰色
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 消息内容
            _buildMessageContent(),

            const SizedBox(height: 4),

            // 时间戳
            Text(
              _formatTimestamp(message.createdAt),
              style: AppTextStyles.caption1.copyWith(
                color: _isMine
                    ? AppColors.textPrimary.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建消息内容
  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: AppTextStyles.body.copyWith(
            color: _isMine ? AppColors.textPrimary : AppColors.textPrimary,
          ),
        );

      case MessageType.image:
      case MessageType.video:
      case MessageType.voice:
        return MediaMessageWidget(message: message, isMine: _isMine);
    }
  }

  /// 格式化时间戳为 HH:mm 格式
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// 显示消息菜单（长按）
  void _showMessageMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          // 复制消息
          if (message.type == MessageType.text)
            CupertinoActionSheetAction(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                _showToast(context, l10n.copy);
              },
              child: Text(l10n.copy),
            ),
          // 删除消息（仅自己的消息）
          if (_isMine)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                // TODO: 实现删除消息功能
                _showToast(context, l10n.toBeImplemented);
              },
              child: Text(l10n.delete),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 显示提示消息
  void _showToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(color: CupertinoColors.white),
          ),
        ),
      ),
    );

    // 1.5秒后自动关闭
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }
}
