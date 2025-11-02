import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/supplement_conversation_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/chat_message_bubble.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/supplement_suggestion_card.dart';

/// AI 补剂计划创建面板
class AISupplementCreationPanel extends ConsumerStatefulWidget {
  const AISupplementCreationPanel({super.key});

  @override
  ConsumerState<AISupplementCreationPanel> createState() => _AISupplementCreationPanelState();
}

class _AISupplementCreationPanelState extends ConsumerState<AISupplementCreationPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplementConversationNotifierProvider.notifier).initConversation();
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    ref.read(supplementConversationNotifierProvider.notifier).sendMessage(message);
    _messageController.clear();

    _scrollToBottom();
  }

  void _handleQuickAction(String optionId, String label) {
    AppLogger.info('🚀 快捷操作: $optionId - $label');

    // 添加用户消息
    ref.read(supplementConversationNotifierProvider.notifier).sendMessage(
      label,
      optionType: optionId,
    );

    _scrollToBottom();
  }

  void _handleOptionSelected(dynamic option) {
    AppLogger.info('✅ 选项选择: ${option.id} - ${option.label}');

    ref.read(supplementConversationNotifierProvider.notifier).handleOptionSelected(option);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applySuggestion() {
    final notifier = ref.read(supplementConversationNotifierProvider.notifier);
    notifier.applySuggestion();

    // 应用后关闭面板
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _rejectSuggestion() {
    ref.read(supplementConversationNotifierProvider.notifier).rejectSuggestion();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(supplementMessagesProvider);
    final isAIResponding = ref.watch(isSupplementAIRespondingProvider);
    final pendingSuggestion = ref.watch(pendingSupplementSuggestionProvider);
    final canSendMessage = ref.watch(canSendSupplementMessageProvider);

    // 当收到新消息时自动滚动到底部
    ref.listen(supplementMessagesProvider, (previous, next) {
      if (next.length > (previous?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeView(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16, left: 0, right: 0),
                    itemCount: messages.length + (pendingSuggestion != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 如果是最后一项且有待处理建议，显示建议卡片
                      if (index == messages.length && pendingSuggestion != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                          child: SupplementSuggestionCard(
                            supplementDay: pendingSuggestion,
                            onApply: _applySuggestion,
                            onReject: _rejectSuggestion,
                          ),
                        );
                      }

                      // 显示聊天消息
                      final message = messages[index];
                      return ChatMessageBubble(
                        message: message,
                        onOptionSelected: _handleOptionSelected,
                      );
                    },
                  ),
          ),

          // 快捷操作（当没有待处理建议且AI不在响应时显示）
          if (pendingSuggestion == null && !isAIResponding && messages.isNotEmpty)
            _buildQuickActions(context),

          _buildInputArea(context, canSendMessage, isAIResponding),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI Supplement Assistant',
              style: AppTextStyles.subhead.copyWith(
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hello! I am your supplement recommendation assistant. I can recommend scientifically sound supplement plans based on your training and diet plans.',
                style: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose an option below to get started.',
              style: AppTextStyles.caption1.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final quickActions = [
      {'id': 'two_step', 'label': 'Based on Training & Diet'},
      {'id': 'basic', 'label': 'Basic Package'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
                minSize: 0,
                onPressed: () => _handleQuickAction(
                  action['id']!,
                  action['label']!,
                ),
                child: Text(
                  '"${action['label']}"',
                  style: AppTextStyles.footnote.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool canSendMessage, bool isAIResponding) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _messageController,
                        placeholder: 'Ask AI for suggestions...',
                        placeholderStyle: AppTextStyles.subhead.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                        style: AppTextStyles.subhead.copyWith(
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        enabled: canSendMessage,
                        onSubmitted: (_) => _sendMessage(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: canSendMessage && _hasText
                  ? _sendMessage
                  : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: canSendMessage && _hasText
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: canSendMessage && _hasText
                      ? null
                      : CupertinoColors.systemGrey4.resolveFrom(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAIResponding
                      ? CupertinoIcons.hourglass
                      : CupertinoIcons.arrow_up,
                  color: CupertinoColors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
