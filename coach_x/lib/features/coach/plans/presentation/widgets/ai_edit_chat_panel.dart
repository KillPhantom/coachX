import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/edit_conversation_providers.dart';
import 'package:coach_x/features/coach/plans/presentation/widgets/chat_message_bubble.dart';

/// AI 编辑对话面板
class AIEditChatPanel extends ConsumerStatefulWidget {
  final String planId;
  final ExercisePlanModel currentPlan;
  final Function(ExercisePlanModel) onPlanModified;
  final VoidCallback? onSuggestionApplied; // 新增：当建议被应用时的回调

  const AIEditChatPanel({
    super.key,
    required this.planId,
    required this.currentPlan,
    required this.onPlanModified,
    this.onSuggestionApplied,
  });

  @override
  ConsumerState<AIEditChatPanel> createState() => _AIEditChatPanelState();
}

class _AIEditChatPanelState extends ConsumerState<AIEditChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // 监听输入框变化
    _messageController.addListener(_onTextChanged);

    // 初始化对话并自动总结
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(editConversationNotifierProvider.notifier)
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

    ref
        .read(editConversationNotifierProvider.notifier)
        .sendMessage(message, widget.planId);

    _messageController.clear();

    // 滚动到底部
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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final isAIResponding = ref.watch(isAIRespondingProvider);
    final pendingSuggestion = ref.watch(pendingSuggestionProvider);
    final canSendMessage = ref.watch(canSendMessageProvider);

    // 监听建议卡片出现，自动滚动到底部
    ref.listen<PlanEditSuggestion?>(pendingSuggestionProvider, (
      previous,
      next,
    ) {
      if (next != null && previous == null) {
        // 建议卡片刚出现，延迟滚动确保布局完成
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
    });

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          _buildHeader(context),

          // 对话列表
          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeView(context)
                : DismissKeyboardOnScroll(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ChatMessageBubble(
                          message: message,
                          onSuggestionTap: message.suggestion != null
                              ? () {
                                  // 滚动到建议卡片
                                }
                              : null,
                        );
                      },
                    ),
                  ),
          ),

          // 快捷操作按钮（没有待处理建议时显示）
          if (pendingSuggestion == null && !isAIResponding)
            _buildQuickActions(context),

          // 输入区域
          _buildInputArea(context, canSendMessage, isAIResponding),
        ],
      ),
    );
  }

  /// 构建顶部标题栏
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
          // AI 图标
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
              color: AppColors.primaryAction,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Expanded(
            child: Text(
              'AI Assistant',
              style: AppTextStyles.title3.copyWith(
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 关闭按钮
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

  /// 构建欢迎界面
  Widget _buildWelcomeView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI 消息气泡
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Hello! How can I assist you with this training plan today?',
                style: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // 提示文本
            Text(
              'Try asking me to modify exercises, adjust intensity, or add new training days.',
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

  /// 构建快捷操作按钮
  Widget _buildQuickActions(BuildContext context) {
    final quickActions = ['分析一下计划的优缺点', '降低所有重量 10%'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
                minimumSize: Size.zero,
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

  /// 构建输入区域
  Widget _buildInputArea(
    BuildContext context,
    bool canSendMessage,
    bool isAIResponding,
  ) {
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
            // 输入框
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
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
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
            // 发送按钮
            GestureDetector(
              onTap: canSendMessage && _hasText ? _sendMessage : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: canSendMessage && _hasText
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
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
