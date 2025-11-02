import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// Chat AI 面板组件
/// 用于生成回复建议
class ChatAIPanel extends ConsumerStatefulWidget {
  final String conversationId;
  final Function(String suggestion) onSuggestionApplied;

  const ChatAIPanel({
    super.key,
    required this.conversationId,
    required this.onSuggestionApplied,
  });

  @override
  ConsumerState<ChatAIPanel> createState() => _ChatAIPanelState();
}

class _ChatAIPanelState extends ConsumerState<ChatAIPanel> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  final List<_AIMessage> _messages = [];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 生成 AI 回复建议
  Future<void> _generateSuggestion() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    // 添加用户消息
    setState(() {
      _messages.add(_AIMessage(
        text: prompt,
        isUser: true,
      ));
      _isGenerating = true;
    });

    _promptController.clear();

    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // TODO: 调用 AI Service 生成回复建议
    // 暂时使用模拟数据
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _messages.add(_AIMessage(
          text: '这是一个 AI 生成的回复建议示例。\n\n您可以点击下方的"应用建议"按钮将其填充到输入框中。',
          isUser: false,
        ));
        _isGenerating = false;
      });

      _scrollToBottom();
    }
  }

  /// 应用 AI 建议
  void _applySuggestion(String suggestion) {
    widget.onSuggestionApplied(suggestion);
    Navigator.of(context).pop();
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部拖拽条
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.dividerLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.activeBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 回复助手',
                  style: AppTextStyles.title3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppColors.textTertiary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 0.5,
            color: AppColors.dividerLight,
          ),

          // 对话区域
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // 加载指示器
          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(radius: 10),
                  const SizedBox(width: 8),
                  Text(
                    'AI 正在思考中...',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          Container(
            height: 0.5,
            color: AppColors.dividerLight,
          ),

          // 输入栏
          _buildInputBar(),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.lightbulb,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '让 AI 帮你生成回复建议',
            style: AppTextStyles.title3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              '描述你想要的回复内容，AI 会为你生成专业的建议',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(_AIMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: CupertinoColors.activeBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: !message.isUser
                  ? () => _applySuggestion(message.text)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppColors.primaryAction
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!message.isUser) ...[
                      const SizedBox(height: 8),
                      Text(
                        '点击应用此建议',
                        style: AppTextStyles.caption2.copyWith(
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建输入栏
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _promptController,
              placeholder: '描述你想要的回复内容...',
              placeholderStyle: AppTextStyles.body.copyWith(
                color: AppColors.textTertiary,
              ),
              style: AppTextStyles.body,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isGenerating ? null : _generateSuggestion,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.arrow_up,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 消息模型
class _AIMessage {
  final String text;
  final bool isUser;

  _AIMessage({
    required this.text,
    required this.isUser,
  });
}
