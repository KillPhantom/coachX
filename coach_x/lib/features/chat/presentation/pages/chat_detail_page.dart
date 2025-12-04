import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_detail_providers.dart';
import 'package:coach_x/features/chat/presentation/widgets/chat_tab_content.dart';
import 'package:coach_x/features/chat/presentation/widgets/feedback_tab_content.dart';
import 'package:coach_x/features/chat/presentation/widgets/common_input_bar.dart';
import 'package:coach_x/features/chat/presentation/widgets/quote_tile.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_providers.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'package:coach_x/features/chat/presentation/widgets/chat_ai_panel.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 对话详情页面
/// 支持聊天和反馈两个 Tab
class ChatDetailPage extends ConsumerWidget {
  final String conversationId;

  const ChatDetailPage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedChatTabProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isCoach = currentUser?.role == UserRole.coach;
    final conversationAsync = ref.watch(conversationDetailProvider(conversationId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
        border: null,
        leading: isCoach
            ? CupertinoNavigationBarBackButton(
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        middle: conversationAsync.when(
          data: (conversation) => Text(
            (currentUser != null && conversation != null)
                ? conversation.getOtherUserName(currentUser.id)
                : '',
            style: AppTextStyles.navTitle,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        trailing: isCoach
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showAIPanel(context, ref),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.activeBlue,
                  size: 24,
                ),
              )
            : null,
      ),
      child: conversationAsync.when(
        data: (conversation) => SafeArea(
          top: false,
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
            if (selectedTab == ChatDetailTab.chat) ...[
            // 引用消息展示
            Consumer(
              builder: (context, ref, child) {
                final quotedMessage = ref.watch(quotedMessageProvider);
                if (quotedMessage == null) return const SizedBox.shrink();

                // 获取发送者名称
                final conversationAsync = ref.watch(conversationDetailProvider(conversationId));
                final conversation = conversationAsync.value;
                String? senderName = quotedMessage.quotedMessageSenderName;
                
                if (senderName == null && conversation != null) {
                  if (quotedMessage.senderId == conversation.coachId) {
                    senderName = conversation.participantNames['coachName'];
                  } else if (quotedMessage.senderId == conversation.studentId) {
                    senderName = conversation.participantNames['studentName'];
                  }
                }

                return QuoteTile(
                  message: quotedMessage,
                  senderName: senderName,
                  onClose: () {
                    ref.read(quotedMessageProvider.notifier).state = null;
                  },
                );
              },
            ),
            CommonInputBar(
              isSubmitting: ref.watch(isSendingMessageProvider),
              onSendText: (text) => _handleSendText(context, ref, text),
              onSendVoice: (path, duration) =>
                  _handleSendVoice(context, ref, path, duration),
              onSendImage: (bytes) => _handleSendImage(context, ref, bytes),
              onSendVideo: (path) => _handleSendVideo(context, ref, path),
            ),
          ],
          ],
        ),
      ),
        loading: () => const Center(
          child: CupertinoActivityIndicator(radius: 16),
        ),
        error: (error, stack) => const Center(
          child: CupertinoActivityIndicator(radius: 16),
        ),
      ),
    );
  }

  /// 显示 AI 助手面板
  void _showAIPanel(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ChatAIPanel(
        conversationId: conversationId,
        onSuggestionApplied: (suggestion) {
          ref.read(messageInputTextProvider.notifier).state = suggestion;
        },
      ),
    );
  }

  // ==================== 发送逻辑 ====================

  /// 获取引用消息数据
  /// 返回 QuoteData: {quotedMessageId, quotedMessageContent, quotedMessageSenderId, quotedMessageSenderName}
  /// 并在成功获取后清除引用状态
  Future<Map<String, String?>> _getQuoteData(WidgetRef ref) async {
    final quotedMessage = ref.read(quotedMessageProvider);
    if (quotedMessage == null) return {};

    final quoteData = <String, String?>{
      'quotedMessageId': quotedMessage.id,
      'quotedMessageContent': _getMessageContent(quotedMessage),
      'quotedMessageSenderId': quotedMessage.senderId,
    };

    // 获取发送者名称
    final conversationAsync = ref.read(conversationDetailProvider(conversationId));
    final conversation = conversationAsync.value;
    
    if (conversation != null) {
      if (quotedMessage.senderId == conversation.coachId) {
        quoteData['quotedMessageSenderName'] = conversation.participantNames['coachName'];
      } else if (quotedMessage.senderId == conversation.studentId) {
        quoteData['quotedMessageSenderName'] = conversation.participantNames['studentName'];
      }
    }

    return quoteData;
  }
  
  String _getMessageContent(MessageModel message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '[图片]';
      case MessageType.video:
        return '[视频]';
      case MessageType.voice:
        return '[语音]';
    }
  }

  /// 获取接收者ID
  Future<String> _getReceiverId(WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) throw Exception('用户未登录');

    final conversation = await ref.read(
      conversationDetailProvider(conversationId).future,
    );
    if (conversation == null) throw Exception('对话不存在');

    return conversation.getOtherUserId(currentUser.id);
  }

  /// 发送文本消息
  Future<void> _handleSendText(
      BuildContext context, WidgetRef ref, String text) async {
    try {
      ref.read(isSendingMessageProvider.notifier).state = true;
      final receiverId = await _getReceiverId(ref);
      final chatRepository = ref.read(chatRepositoryProvider);
      final quoteData = await _getQuoteData(ref);

      await chatRepository.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        type: MessageType.text,
        content: text,
        quotedMessageId: quoteData['quotedMessageId'],
        quotedMessageContent: quoteData['quotedMessageContent'],
        quotedMessageSenderId: quoteData['quotedMessageSenderId'],
        quotedMessageSenderName: quoteData['quotedMessageSenderName'],
      );
      
      // 发送成功后清除引用
      ref.read(quotedMessageProvider.notifier).state = null;
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      ref.read(isSendingMessageProvider.notifier).state = false;
    }
  }

  /// 发送语音消息
  Future<void> _handleSendVoice(BuildContext context, WidgetRef ref,
      String filePath, int duration) async {
    try {
      ref.read(isSendingMessageProvider.notifier).state = true;
      final receiverId = await _getReceiverId(ref);
      final chatRepository = ref.read(chatRepositoryProvider);
      final quoteData = await _getQuoteData(ref);

      // 1. 上传语音文件
      final mediaUrl = await chatRepository.uploadMediaFile(
        filePath: filePath,
        conversationId: conversationId,
        mediaType: 'voice',
      );

      // 2. 发送消息
      await chatRepository.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        type: MessageType.voice,
        content: '[语音]',
        mediaUrl: mediaUrl,
        mediaMetadata: MessageMetadata(duration: duration),
        quotedMessageId: quoteData['quotedMessageId'],
        quotedMessageContent: quoteData['quotedMessageContent'],
        quotedMessageSenderId: quoteData['quotedMessageSenderId'],
        quotedMessageSenderName: quoteData['quotedMessageSenderName'],
      );
      
      // 发送成功后清除引用
      ref.read(quotedMessageProvider.notifier).state = null;
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      ref.read(isSendingMessageProvider.notifier).state = false;
    }
  }

  /// 发送图片消息 (已编辑的Uint8List)
  Future<void> _handleSendImage(
      BuildContext context, WidgetRef ref, Uint8List bytes) async {
    try {
      ref.read(isSendingMessageProvider.notifier).state = true;
      final receiverId = await _getReceiverId(ref);
      final chatRepository = ref.read(chatRepositoryProvider);
      final quoteData = await _getQuoteData(ref);

      // 1. 上传图片数据
      final mediaUrl = await chatRepository.uploadMediaBytes(
        bytes: bytes,
        conversationId: conversationId,
        mediaType: 'image',
      );

      // 2. 发送消息
      await chatRepository.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        type: MessageType.image,
        content: '[图片]',
        mediaUrl: mediaUrl,
        quotedMessageId: quoteData['quotedMessageId'],
        quotedMessageContent: quoteData['quotedMessageContent'],
        quotedMessageSenderId: quoteData['quotedMessageSenderId'],
        quotedMessageSenderName: quoteData['quotedMessageSenderName'],
      );
      
      // 发送成功后清除引用
      ref.read(quotedMessageProvider.notifier).state = null;
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      ref.read(isSendingMessageProvider.notifier).state = false;
    }
  }

  /// 发送视频消息
  Future<void> _handleSendVideo(
      BuildContext context, WidgetRef ref, String filePath) async {
    try {
      ref.read(isSendingMessageProvider.notifier).state = true;
      final receiverId = await _getReceiverId(ref);
      final chatRepository = ref.read(chatRepositoryProvider);
      final quoteData = await _getQuoteData(ref);

      // 1. 生成缩略图
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: filePath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 512,
        quality: 75,
      );

      if (thumbnailPath == null) throw Exception('生成缩略图失败');

      // 2. 上传视频和缩略图 (并发)
      final results = await Future.wait([
        chatRepository.uploadMediaFile(
          filePath: filePath,
          conversationId: conversationId,
          mediaType: 'video',
        ),
        chatRepository.uploadMediaFile(
          filePath: thumbnailPath,
          conversationId: conversationId,
          mediaType: 'video_thumbnail',
        ),
      ]);

      final videoUrl = results[0];
      final thumbnailUrl = results[1];

      // 3. 发送消息
      await chatRepository.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        type: MessageType.video,
        content: '[视频]',
        mediaUrl: videoUrl,
        mediaMetadata: MessageMetadata(thumbnailUrl: thumbnailUrl),
        quotedMessageId: quoteData['quotedMessageId'],
        quotedMessageContent: quoteData['quotedMessageContent'],
        quotedMessageSenderId: quoteData['quotedMessageSenderId'],
        quotedMessageSenderName: quoteData['quotedMessageSenderName'],
      );
      
      // 发送成功后清除引用
      ref.read(quotedMessageProvider.notifier).state = null;

      // 清理临时文件
      final thumbFile = File(thumbnailPath);
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    } catch (e) {
      AppLogger.error('发送视频失败', e);
      _showError(context, '发送视频失败');
    } finally {
      ref.read(isSendingMessageProvider.notifier).state = false;
    }
  }

  void _showError(BuildContext context, String message) {
    // 简单的错误提示
    if (!context.mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('发送失败'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定', style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ==================== UI 构建 ====================

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
}
