import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/edit_diet_conversation_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/diet_suggestion_review_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/chat_message_bubble.dart';

/// AI 编辑饮食计划对话面板
class AIEditDietChatPanel extends ConsumerStatefulWidget {
  final String planId;
  final DietPlanModel currentPlan;
  final Function(DietPlanModel) onPlanModified;
  final VoidCallback? onSuggestionApplied;

  const AIEditDietChatPanel({
    super.key,
    required this.planId,
    required this.currentPlan,
    required this.onPlanModified,
    this.onSuggestionApplied,
  });

  @override
  ConsumerState<AIEditDietChatPanel> createState() => _AIEditDietChatPanelState();
}

class _AIEditDietChatPanelState extends ConsumerState<AIEditDietChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editDietConversationNotifierProvider.notifier)
          .initConversation(widget.currentPlan, widget.planId);
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

    ref.read(editDietConversationNotifierProvider.notifier)
        .sendMessage(message, widget.planId);

    _messageController.clear();

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

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  Future<void> _applySuggestion() async {
    final notifier = ref.read(editDietConversationNotifierProvider.notifier);
    final suggestion = ref.read(pendingDietSuggestionProvider);

    if (suggestion != null) {
      // 1. 应用修改（通过 changes 生成新计划）
      await notifier.applySuggestion();

      // 2. 获取应用修改后的计划
      final updatedPlan = ref.read(editDietConversationNotifierProvider).currentPlan;
      if (updatedPlan != null) {
        // 同步新计划到父组件
        widget.onPlanModified(updatedPlan);

        // 3. 🆕 使用新计划启动 Diet Review Mode
        ref.read(dietSuggestionReviewNotifierProvider.notifier)
            .startReview(suggestion, updatedPlan);
        ref.read(isDietReviewModeProvider.notifier).state = true;
      }

      // 4. 通知父组件（让父组件关闭对话框）
      if (widget.onSuggestionApplied != null) {
        widget.onSuggestionApplied!();
      }
    }
  }

  Future<void> _rejectSuggestion() async {
    await ref.read(editDietConversationNotifierProvider.notifier).rejectSuggestion();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(dietMessagesProvider);
    final isAIResponding = ref.watch(isDietAIRespondingProvider);
    final pendingSuggestion = ref.watch(pendingDietSuggestionProvider);
    final canSendMessage = ref.watch(canSendDietMessageProvider);

    // 🆕 当收到建议时，自动应用并启动 Review Mode
    ref.listen<DietPlanEditSuggestion?>(pendingDietSuggestionProvider, (previous, next) {
      if (next != null && previous == null) {
        AppLogger.info('🚀 检测到新的饮食计划建议，自动应用并启动 Review Mode');

        // 自动滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }

          // 延迟一小段时间后自动应用建议
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _applySuggestion();
            }
          });
        });
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: Column(
              children: [

                // 对话列表
                Expanded(
                  child: messages.isEmpty
                      ? _buildWelcomeView(context)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return ChatMessageBubble(
                              message: message,
                              onSuggestionTap: message.suggestion != null
                                  ? () {}
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          if (pendingSuggestion == null && !isAIResponding)
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
              'AI Assistant',
              style: AppTextStyles.title3.copyWith(
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
                'Hello! How can I assist you with this diet plan today?',
                style: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Try asking me to adjust macros, modify meals, or change portions.',
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
      '减少10%碳水，增加10%蛋白质',
      '减少10%碳水',
      '增加10% kCal',
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
                onPressed: () => _sendQuickMessage(action),
                child: Text(
                  '"$action"',
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
