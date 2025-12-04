import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/student/chat/presentation/controllers/ai_chat_controller.dart';
import 'package:coach_x/features/student/chat/presentation/widgets/ai_message_bubble.dart';
import 'package:coach_x/features/chat/presentation/widgets/common_input_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard.dart';

/// AI 对话页面
class AIChatPage extends ConsumerStatefulWidget {
  const AIChatPage({super.key});

  @override
  ConsumerState<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends ConsumerState<AIChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showInvitationCodeDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _InvitationCodeModal(
        onRedeem: (code) => _handleRedeemCode(context, code),
      ),
    );
  }

  Future<String?> _handleRedeemCode(BuildContext context, String code) async {
    final l10n = AppLocalizations.of(context)!;

    if (ValidationUtils.validateInvitationCode(code) != null) {
      return l10n.invalidCode;
    }

    try {
      // 调用 Cloud Function 验证并使用邀请码 (confirm: true)
      final result = await CloudFunctionsService.verifyInvitationCode(
        code,
        confirm: true,
      );

      if (!mounted) return null;

      if (result['valid'] == true) {
        // 关闭当前页面（Modal）
        Navigator.of(context).pop();
        
        // 显示成功提示
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.connectSuccess),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        
        // 页面会因为 User 状态更新而自动刷新
        return null;
      } else {
        // 返回错误信息供Modal显示
        return result['message'] ?? l10n.invalidCode;
      }
    } catch (e) {
      if (!mounted) return null;
      return e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(aiChatControllerProvider);
    final controller = ref.read(aiChatControllerProvider.notifier);
    final currentUser = FirebaseAuth.instance.currentUser;

    // 监听消息列表变化，自动滚动到底部
    ref.listen(aiChatControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          (next.messages.isNotEmpty &&
              previous?.messages.last.content != next.messages.last.content)) {
        // 稍微延迟以等待列表渲染
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.aiConversationTitle),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 连接教练 Banner
            _buildConnectCoachBanner(context),
            
            // 消息列表
            Expanded(
              child: state.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.chat_bubble_2,
                            size: 60,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isMine = message.senderId == currentUser?.uid;
                        return AIMessageBubble(
                          message: message,
                          isMine: isMine,
                        );
                      },
                    ),
            ),

            // 错误提示
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle_fill,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // 快捷操作 Chips
            if (!state.isGenerating)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildShortcutChip(
                        context,
                        label: l10n.aiAnalyzeTrainingHistory,
                        onPressed: () =>
                            controller.sendMessage(l10n.aiAnalyzeTrainingHistory),
                      ),
                      const SizedBox(width: 8),
                      _buildShortcutChip(
                        context,
                        label: l10n.aiAnalyzeDietPlan,
                        onPressed: () =>
                            controller.sendMessage(l10n.aiAnalyzeDietPlan),
                      ),
                      const SizedBox(width: 8),
                      _buildShortcutChip(
                        context,
                        label: l10n.aiAnalyzeTrainingPlan,
                        onPressed: () =>
                            controller.sendMessage(l10n.aiAnalyzeTrainingPlan),
                      ),
                    ],
                  ),
                ),
              ),

            // 输入栏
            CommonInputBar(
              isSubmitting: state.isGenerating,
              onSendText: (text) async {
                await controller.sendMessage(text);
              },
              onSendVoice: (path, duration) async {
                // TODO: 支持语音输入
              },
              onSendImage: (bytes) async {
                // TODO: 支持图片输入
              },
              onSendVideo: (path) async {
                // TODO: 支持视频输入
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildConnectCoachBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: double.infinity,
      color: AppColors.secondaryOrange.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: GestureDetector(
        onTap: () => _showInvitationCodeDialog(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_2_fill,
              size: 20,
              color: AppColors.secondaryOrange,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.connectWithCoach,
              style: const TextStyle(
                color: AppColors.secondaryOrange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.secondaryOrange,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCodeModal extends StatefulWidget {
  final Future<String?> Function(String) onRedeem;

  const _InvitationCodeModal({
    required this.onRedeem,
  });

  @override
  State<_InvitationCodeModal> createState() => _InvitationCodeModalState();
}

class _InvitationCodeModalState extends State<_InvitationCodeModal> {
  final TextEditingController _controller = TextEditingController();
  bool _isLocalConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLocalConnecting = true;
      _errorMessage = null;
    });

    try {
      final error = await widget.onRedeem(code);
      if (mounted && error != null) {
        setState(() {
          _errorMessage = error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocalConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPopupSurface(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: SafeArea(
          top: false,
          child: DismissKeyboard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和关闭按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.connectWithCoach, style: AppTextStyles.title3),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.xmark_circle,
                        size: 28,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 说明
                Text(
                  l10n.connectCoachModalDescription,
                  style: AppTextStyles.subhead,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 输入区域
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.enterInvitationCode, style: AppTextStyles.footnote),
                      const SizedBox(height: AppDimensions.spacingS),
                      CupertinoTextField(
                        controller: _controller,
                        placeholder: l10n.invitationCodePlaceholder,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spacingL),

                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                      ],

                      // 连接按钮
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: AppColors.primaryAction,
                          onPressed: _isLocalConnecting 
                              ? null 
                              : _handlePress,
                          child: _isLocalConnecting
                              ? const CupertinoActivityIndicator(color: AppColors.textWhite)
                              : Text(
                                  l10n.connect,
                                  style: const TextStyle(color: AppColors.textWhite),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

