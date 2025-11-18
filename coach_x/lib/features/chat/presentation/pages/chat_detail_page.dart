import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/chat_tab_content.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_tab_content.dart';
import 'package:coach_x/features/chat/presentation/widgets/message_input_bar.dart';
import 'package:coach_x/features/chat/presentation/widgets/chat_ai_panel.dart';

/// 对话详情页面
/// 支持聊天和反馈两个 Tab
class ChatDetailPage extends ConsumerWidget {
  final String conversationId;

  const ChatDetailPage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTab = ref.watch(selectedChatTabProvider);
    final conversationAsync = ref.watch(
      conversationDetailProvider(conversationId),
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
        middle: conversationAsync.when(
          data: (conversation) {
            if (conversation == null) {
              return Text(l10n.conversationTitle);
            }
            // 获取对方用户名
            // TODO: 需要从 conversation 中获取对方用户信息
            return Text(l10n.conversationTitle);
          },
          loading: () => const CupertinoActivityIndicator(),
          error: (_, __) => Text(l10n.conversationTitle),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAIPanel(context, ref),
          child: const Icon(
            CupertinoIcons.sparkles,
            color: CupertinoColors.activeBlue,
            size: 28,
          ),
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Tab 切换器
          _buildTabBar(context, ref, selectedTab),

          // Tab 内容
          Expanded(
            child: selectedTab == ChatDetailTab.chat
                ? ChatTabContent(conversationId: conversationId)
                : FeedbackTabContent(conversationId: conversationId),
          ),

          // 消息输入栏（仅在 Chat Tab 显示）
          if (selectedTab == ChatDetailTab.chat)
            MessageInputBar(
              conversationId: conversationId,
              onMessageSent: () {
                // 消息发送成功后的回调
                // 可以在这里滚动到底部或显示提示
              },
            ),
        ],
      ),
    );
  }

  /// 构建 Tab 切换器
  Widget _buildTabBar(
    BuildContext context,
    WidgetRef ref,
    ChatDetailTab selectedTab,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              context,
              ref,
              l10n.chatTabLabel,
              ChatDetailTab.chat,
              selectedTab == ChatDetailTab.chat,
            ),
          ),
          Expanded(
            child: _buildTabItem(
              context,
              ref,
              l10n.feedbackTabLabel,
              ChatDetailTab.feedback,
              selectedTab == ChatDetailTab.feedback,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个 Tab 项
  Widget _buildTabItem(
    BuildContext context,
    WidgetRef ref,
    String label,
    ChatDetailTab tab,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedChatTabProvider.notifier).state = tab;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? AppColors.primaryText
                  : CupertinoColors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? AppColors.primaryText : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 显示 AI 面板
  void _showAIPanel(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => ChatAIPanel(
        conversationId: conversationId,
        onSuggestionApplied: (suggestion) {
          // 将 AI 建议填充到输入框
          ref.read(messageInputTextProvider.notifier).state = suggestion;
        },
      ),
    );
  }
}
