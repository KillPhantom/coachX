import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';

/// 引用消息展示组件
/// 用于在输入框下方显示当前引用的消息
class QuoteTile extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onClose;
  final String? senderName;

  const QuoteTile({
    super.key,
    required this.message,
    required this.onClose,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 引用内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senderName != null)
                  Text(
                    '$senderName:',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  _getMessageContent(message),
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 关闭按钮
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取消息内容展示文本
  String _getMessageContent(MessageModel message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '[图片]';
      case MessageType.video:
        return '[视频]';
      case MessageType.voice:
        return '[语音]';
    }
  }
}

