import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';

/// 聊天消息气泡组件
class ChatMessageBubble extends StatelessWidget {
  final LLMChatMessage message;
  final VoidCallback? onSuggestionTap;
  final Function(InteractiveOption)? onOptionSelected;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTap,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == LLMMessageType.user;
    final isSystem = message.type == LLMMessageType.system;

    if (isSystem) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(context, isUser: false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context, isUser),
                if (message.options != null && message.options!.isNotEmpty)
                  _buildInteractiveOptions(context),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(context, isUser: true),
          ],
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(BuildContext context, {required bool isUser}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isUser ? CupertinoIcons.person_fill : CupertinoIcons.sparkles,
        size: 18,
        color: AppColors.primaryText,
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(BuildContext context, bool isUser) {
    // 计算最大宽度：屏幕宽度 - avatar(36) - spacing(12) - padding(32) - 安全边距(20)
    final maxWidth = MediaQuery.of(context).size.width - 100;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFFD4C5D9) // 浅紫色，接近截图
            : CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: message.isLoading
          ? _buildLoadingIndicator(context)
          : MarkdownBody(
              data: message.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                // 段落文本 - 15px
                p: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  height: 1.4,
                ),
                // 标题 - 都使用较小字体
                h1: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                h2: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                h3: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                h4: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                h5: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                h6: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                // 粗体
                strong: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                // 斜体
                em: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                // 列表
                listBullet: AppTextStyles.subhead.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  height: 1.4,
                ),
                // 行内代码
                code: AppTextStyles.footnote.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  backgroundColor: CupertinoColors.systemGrey5.resolveFrom(
                    context,
                  ),
                  fontFamily: 'monospace',
                ),
                // 代码块
                codeblockDecoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CupertinoActivityIndicator(radius: 10),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            message.content.isNotEmpty ? message.content : 'Thinking...',
            style: AppTextStyles.subhead.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: AppTextStyles.caption1.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// 构建交互式选项卡片
  Widget _buildInteractiveOptions(BuildContext context) {
    if (message.options == null || message.options!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.options!.map((option) {
          return _buildOptionCard(context, option);
        }).toList(),
      ),
    );
  }

  /// 构建单个选项卡片
  Widget _buildOptionCard(BuildContext context, InteractiveOption option) {
    IconData icon;

    // 根据类型选择图标
    if (option.type == 'training_plan') {
      icon = CupertinoIcons.sportscourt;
    } else if (option.type == 'diet_plan') {
      icon = CupertinoIcons.chart_bar_alt_fill;
    } else {
      icon = CupertinoIcons.doc_text;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onOptionSelected != null
            ? () => onOptionSelected!(option)
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryText, size: 20),
              ),
              const SizedBox(width: 12),
              // 文本内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTextStyles.subhead.copyWith(
                        color: CupertinoColors.label.resolveFrom(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        style: AppTextStyles.caption1.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 箭头
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
