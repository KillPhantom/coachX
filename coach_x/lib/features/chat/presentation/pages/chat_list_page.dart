import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/app/providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/conversation_card.dart';

/// 对话列表页面
/// 教练端和学生端共用此页面
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(conversationItemsProvider);

    return CustomScrollView(
      slivers: [
        // 顶部导航栏
        CupertinoSliverNavigationBar(
          backgroundColor: AppColors.backgroundWhite,
          largeTitle: Text(l10n.messagesTitle),
          border: const Border(
            bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
          ),
        ),

        // 下拉刷新
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            // 刷新对话列表
            ref.invalidate(conversationItemsProvider);
            // 等待刷新完成
            await ref.read(conversationItemsProvider.future);
          },
        ),

        // 对话列表内容
        conversationsAsync.when(
          // 加载中
          loading: () => const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator(radius: 16)),
          ),

          // 加载错误
          error: (error, stack) =>
              SliverFillRemaining(child: _buildErrorState(context, ref, error)),

          // 加载成功
          data: (conversations) {
            // 空状态
            if (conversations.isEmpty) {
              return SliverFillRemaining(child: _buildEmptyState(context, ref));
            }

            // 显示对话列表
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final conversation = conversations[index];
                return ConversationCard(item: conversation);
              }, childCount: conversations.length),
            );
          },
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider).value;
    final isCoach = currentUser?.role.isCoach ?? false;

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
            isCoach ? l10n.noConversations : l10n.noConversations,
            style: AppTextStyles.title3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCoach ? l10n.noStudentsMessage : l10n.noCoachOrConversations,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final l10n = AppLocalizations.of(context)!;

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
            Text(l10n.loadFailed, style: AppTextStyles.title3),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                // 重新加载
                ref.invalidate(conversationItemsProvider);
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
