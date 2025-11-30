import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/core/enums/user_role.dart';
import '../providers/chat_providers.dart';

/// 对话卡片组件
/// 用于在对话列表中显示单个对话项
class ConversationCard extends ConsumerWidget {
  final ConversationItem item;

  const ConversationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          border: Border(
            bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // 头像
            _buildAvatar(context, ref),
            const SizedBox(width: 12),

            // 中间内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 姓名和时间
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.userName,
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.lastMessage != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(item.lastMessageTime),
                          style: AppTextStyles.caption1.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // 最后消息预览
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getMessagePreview(),
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 未读Badge
                      if (item.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildUnreadBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(BuildContext context, WidgetRef ref) {
    Widget avatarWidget;

    if (item.avatarUrl != null && item.avatarUrl!.isNotEmpty) {
      // 显示网络头像
      avatarWidget = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(item.avatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // 显示默认头像（姓名首字母）
      avatarWidget = Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundSecondary,
        ),
        child: Center(
          child: Text(
            _getNameInitial(),
            style: AppTextStyles.title3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // 包裹GestureDetector添加点击事件
    return GestureDetector(
      onTap: () => _handleAvatarTap(context, ref),
      child: avatarWidget,
    );
  }

  /// 处理头像点击
  void _handleAvatarTap(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider).value;

    // 只有教练点击学生头像时跳转到学生详情页
    if (currentUser?.role == UserRole.coach) {
      context.push('/student-detail/${item.userId}');
    }
    // 学生点击教练头像暂不处理
  }

  /// 获取姓名首字母
  String _getNameInitial() {
    if (item.userName.isEmpty) return '?';
    return item.userName[0].toUpperCase();
  }

  /// 构建未读Badge
  Widget _buildUnreadBadge() {
    final count = item.unreadCount;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        displayCount,
        style: AppTextStyles.caption2.copyWith(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 获取消息预览文本
  String _getMessagePreview() {
    final lastMessage = item.lastMessage;

    if (lastMessage == null) {
      return '开始对话';
    }

    // 根据消息类型显示不同的预览
    switch (lastMessage.type) {
      case 'text':
        return lastMessage.content;
      case 'image':
        return '[图片]';
      case 'video':
        return '[视频]';
      case 'voice':
        return '[语音]';
      default:
        return lastMessage.content;
    }
  }

  /// 格式化时间戳
  /// 今天：显示时间 "HH:mm"
  /// 昨天：显示"昨天"
  /// 更早：显示日期 "MM/dd"
  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';

    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      messageTime.year,
      messageTime.month,
      messageTime.day,
    );

    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      // 今天 - 显示时间
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      // 昨天
      return '昨天';
    } else if (difference < 7) {
      // 一周内 - 显示星期
      const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
      return weekdays[messageTime.weekday % 7];
    } else {
      // 更早 - 显示日期
      return '${messageTime.month}/${messageTime.day}';
    }
  }

  /// 处理点击事件
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    String? conversationId = item.conversationId;

    // 如果对话ID不存在，先创建对话
    if (conversationId == null || conversationId.isEmpty) {
      try {
        // 显示加载状态
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CupertinoActivityIndicator(radius: 16)),
        );

        // 获取或创建对话
        final conversation = await ref.read(
          conversationProvider(item.userId).future,
        );
        conversationId = conversation?.id;

        // 关闭加载对话框
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (conversationId == null) {
          // 创建失败
          if (context.mounted) {
            _showErrorDialog(context, '无法创建对话，请稍后重试');
          }
          return;
        }
      } catch (e) {
        // 关闭加载对话框
        if (context.mounted) {
          Navigator.of(context).pop();
          _showErrorDialog(context, '创建对话失败: ${e.toString()}');
        }
        return;
      }
    }

    // 导航到对话详情页
    if (context.mounted) {
      context.push(RouteNames.getChatDetailRoute(conversationId));
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定', style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
