import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';
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

  @override
  void initState() {
    super.initState();
    // 监听滚动到顶部时加载更多
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 当滚动到顶部时加载更多历史消息
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      _loadMoreMessages();
    }
  }

  /// 加载更多历史消息
  Future<void> _loadMoreMessages() async {
    final isLoading = ref.read(isLoadingMoreMessagesProvider);
    if (isLoading) return;

    ref.read(isLoadingMoreMessagesProvider.notifier).state = true;

    // TODO: 实现加载更多消息
    // 使用 ChatRepository.fetchMoreMessages

    await Future.delayed(const Duration(milliseconds: 500));
    ref.read(isLoadingMoreMessagesProvider.notifier).state = false;
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );

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
              return MessageBubble(
                message: message,
                currentUserId: currentUser.id,
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
