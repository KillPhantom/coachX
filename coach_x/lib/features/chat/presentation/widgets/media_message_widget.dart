import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/chat/data/models/message_model.dart';
import 'video_player_widget.dart';
import 'audio_player_widget.dart';

/// 媒体消息组件
/// 支持图片、视频、语音消息的显示
class MediaMessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const MediaMessageWidget({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return _buildVideoMessage(context);
      case MessageType.voice:
        return _buildVoiceMessage(context);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 构建图片消息
  Widget _buildImageMessage(BuildContext context) {
    if (message.mediaUrl == null) {
      return const Text('[图片加载失败]');
    }

    return GestureDetector(
      onTap: () => _showImageFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            color: AppColors.backgroundSecondary,
            child: const Center(child: CupertinoActivityIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            color: AppColors.backgroundSecondary,
            child: const Center(
              child: Icon(
                CupertinoIcons.photo,
                color: AppColors.textTertiary,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建视频消息
  Widget _buildVideoMessage(BuildContext context) {
    if (message.mediaUrl == null) {
      return const Text('[视频加载失败]');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: VideoPlayerWidget(
        videoUrl: message.mediaUrl!,
        thumbnailUrl: message.mediaMetadata?.thumbnailUrl,
      ),
    );
  }

  /// 构建语音消息
  Widget _buildVoiceMessage(BuildContext context) {
    if (message.mediaUrl == null) {
      return const Text('[语音加载失败]');
    }

    return AudioPlayerWidget(
      audioUrl: message.mediaUrl!,
      duration: message.mediaMetadata?.duration ?? 0,
      isMine: isMine,
    );
  }

  /// 显示图片全屏
  void _showImageFullScreen(BuildContext context) {
    if (message.mediaUrl == null) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => _ImageFullScreenPage(imageUrl: message.mediaUrl!),
      ),
    );
  }
}

/// 图片全屏页面
class _ImageFullScreenPage extends StatelessWidget {
  final String imageUrl;

  const _ImageFullScreenPage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withOpacity(0.8),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
        ),
        middle: const Text(
          '图片',
          style: TextStyle(color: CupertinoColors.white),
        ),
        border: null,
      ),
      child: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(
            color: CupertinoColors.black,
          ),
          loadingBuilder: (context, event) => const Center(
            child: CupertinoActivityIndicator(color: CupertinoColors.white),
          ),
        ),
      ),
    );
  }
}
