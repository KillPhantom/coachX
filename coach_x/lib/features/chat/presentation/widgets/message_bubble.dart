import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/message_popup_menu.dart';
import 'media_message_widget.dart';

/// 消息气泡组件
/// 根据发送者显示左对齐或右对齐的消息气泡，类似微信风格
class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final String currentUserId;
  final String? avatarUrl;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.avatarUrl,
    this.showTimestamp = false,
  });

  /// 是否是我发送的消息
  bool get _isMine => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              _formatTimestamp(message.createdAt),
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment:
                _isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 对方消息：头像在左
              if (!_isMine) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
                _buildBubble(context, ref),
              ],
              // 我的消息：头像在右
              if (_isMine) ...[
                _buildBubble(context, ref),
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return ClipOval(
      child: Container(
        width: 40,
        height: 40,
        color: AppColors.backgroundSecondary,
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CupertinoActivityIndicator()),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(
        CupertinoIcons.person_fill,
        color: AppColors.textTertiary,
        size: 24,
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildBubble(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (bubbleContext) {
        return GestureDetector(
          onLongPress: () => _showMessageMenu(bubbleContext, ref),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            decoration: message.type == MessageType.text
                ? BoxDecoration(
                    color: _isMine
                        ? AppColors.primaryLight // 我的消息：暖色
                        : CupertinoColors.systemGrey6
                            .resolveFrom(context), // 对方：浅灰色
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 引用消息内容
                if (message.quotedMessageContent != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.quotedMessageSenderName != null)
                            Text(
                              '${message.quotedMessageSenderName}:',
                              style: AppTextStyles.caption1.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 2),
                          Text(
                            message.quotedMessageContent!,
                            style: AppTextStyles.caption1.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 消息内容
                _buildMessageContent(),
              ],
            ),
          ),
        );
      },
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
  void _showMessageMenu(BuildContext context, WidgetRef ref) {
    // 获取RenderBox以计算位置
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    // 创建OverlayEntry
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => MessagePopupMenu(
        targetRect: rect,
        onQuote: () {
          ref.read(quotedMessageProvider.notifier).state = message;
        },
        onDelete: _isMine ? () async {
          try {
            final chatRepository = ref.read(chatRepositoryProvider);
            await chatRepository.deleteMessage(
              conversationId: message.conversationId,
              messageId: message.id,
            );
            _showToast(context, '已删除');
          } catch (e) {
            _showToast(context, '删除失败');
          }
        } : null,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    // 插入Overlay
    Overlay.of(context).insert(overlayEntry);
  }

  /// 显示提示消息
  void _showToast(BuildContext context, String message) {
    if (!context.mounted) return;
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
