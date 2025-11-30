import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_providers.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:logger/web.dart';
import 'message_bubble.dart';

/// Chat Tab 内容组件
/// 显示实时消息列表
class ChatTabContent extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatTabContent({super.key, required this.conversationId});

  @override
  ConsumerState<ChatTabContent> createState() => _ChatTabContentState();
}

class _ChatTabContentState extends ConsumerState<ChatTabContent> {
  final ScrollController _scrollController = ScrollController();
  Timer? _markAsReadTimer;

  @override
  void initState() {
    super.initState();
    // 监听滚动到顶部时加载更多
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _markAsReadTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 当滚动到视觉顶部时加载更多历史消息
    // 注意：ListView 使用 reverse: true，所以 maxScrollExtent 是视觉顶部（最早消息）
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  /// 加载更多历史消息
  Future<void> _loadMoreMessages() async {
    if (!mounted) return;

    final isLoading = ref.read(isLoadingMoreMessagesProvider);
    if (isLoading) return;

    ref.read(isLoadingMoreMessagesProvider.notifier).state = true;

    // TODO: 实现加载更多消息
    // 使用 ChatRepository.fetchMoreMessages

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    ref.read(isLoadingMoreMessagesProvider.notifier).state = false;
  }

  /// 滚动到底部
  /// 注意：ListView 使用 reverse: true，所以 minScrollExtent 是视觉底部（最新消息）
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 标记消息为已读
  Future<void> _markMessagesAsRead() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.markMessagesAsRead(
        widget.conversationId,
        currentUser.id,
      );

      AppLogger.info('标记消息已读成功: ${widget.conversationId}');
    } catch (e, stackTrace) {
      // 静默失败，仅记录日志
      AppLogger.error('标记消息已读失败', e, stackTrace);
    }
  }

  /// 获取用户头像URL
  String? _getAvatarUrl(
    String senderId,
    UserModel? currentUser,
    UserModel? otherUser,
  ) {
    // 1. 如果是当前用户，直接使用当前用户的最新头像
    if (currentUser != null && senderId == currentUser.id) {
      return currentUser.avatarUrl;
    }

    // 2. 如果是对方，使用对方的最新头像
    if (otherUser != null && senderId == otherUser.id) {
      return otherUser.avatarUrl;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );
    final otherUser =
        ref.watch(otherUserProvider(widget.conversationId)).value;

    if (currentUser == null) {
      return const Center(child: Text('用户未登录'));
    }

    return messagesAsync.when(
      loading: () =>
          const Center(child: CupertinoActivityIndicator(radius: 16)),
      error: (error, stack) => _buildErrorState(context, error),
      data: (messages) {
        // 自动滚动到底部（当有新消息时）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();

          // 标记消息为已读（带防抖）
          if (messages.isNotEmpty) {
            // 检查是否有未读消息（当前用户是接收者且状态不是已读）
            final hasUnread = messages.any((msg) =>
                msg.receiverId == currentUser.id &&
                msg.status != MessageStatus.read);

            if (hasUnread) {
              AppLogger.info('📨 检测到未读消息，准备标记为已读');
              _markAsReadTimer?.cancel();
              _markAsReadTimer = Timer(
                const Duration(milliseconds: 300),
                () => _markMessagesAsRead(),
              );
            } else {
              AppLogger.info('✅ 无未读消息，跳过标记已读调用（优化）');
            }
          }
        });

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return DismissKeyboardOnScroll(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            // 反转列表，使最新消息在底部
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];

              // 计算是否显示时间戳
              // 注意：列表是反转的 (index 0 是最新消息)
              bool showTimestamp = false;
              if (index == messages.length - 1) {
                // 最早的一条消息总是显示时间戳
                showTimestamp = true;
              } else {
                // 与上一条消息（列表中的下一个元素）比较
                final previousMessage = messages[index + 1];
                final diff =
                    message.createdAt.difference(previousMessage.createdAt);
                // 超过5分钟显示时间戳
                if (diff.abs().inMinutes > 5) {
                  showTimestamp = true;
                }
              }

                final avatarUrl = _getAvatarUrl(
                  message.senderId,
                  currentUser,
                  otherUser,
                );

                return MessageBubble(
                message: message,
                currentUserId: currentUser.id,
                avatarUrl: avatarUrl,
                showTimestamp: showTimestamp,
              );
            },
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 20),
          Text(
            '暂无消息',
            style: AppTextStyles.title3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始对话吧',
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, Object error) {
    Logger().e(error.toString());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 20),
            const Text('加载消息失败', style: AppTextStyles.title3),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                // 重新加载
                ref.invalidate(messagesStreamProvider(widget.conversationId));
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
