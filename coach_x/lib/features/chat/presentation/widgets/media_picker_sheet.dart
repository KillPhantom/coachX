import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 媒体选择器底部弹出组件
class MediaPickerSheet extends StatelessWidget {
  final String conversationId;
  final Function(String mediaUrl, String mediaType) onMediaPicked;

  const MediaPickerSheet({
    super.key,
    required this.conversationId,
    required this.onMediaPicked,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('选择媒体类型'),
      message: const Text('支持图片、视频和语音消息'),
      actions: <CupertinoActionSheetAction>[
        // 拍照
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _pickImage(context, ImageSource.camera);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.camera, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                '拍照',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // 选择图片
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _pickImage(context, ImageSource.gallery);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.photo, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                '选择图片',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // 录制视频
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _pickVideo(context, ImageSource.camera);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.videocam, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                '录制视频',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // 选择视频
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _pickVideo(context, ImageSource.gallery);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.film, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                '选择视频',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // 录制语音
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            _recordVoice(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.mic, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                '录制语音',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('取消'),
      ),
    );
  }

  /// 选择图片
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && context.mounted) {
        // TODO: 上传图片到 Firebase Storage
        // 暂时使用本地路径
        _showToast(context, '图片选择成功，上传功能待实现');
        // onMediaPicked(image.path, 'image');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, '选择图片失败: $e');
      }
    }
  }

  /// 选择视频
  Future<void> _pickVideo(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null && context.mounted) {
        // TODO: 上传视频到 Firebase Storage
        _showToast(context, '视频选择成功，上传功能待实现');
        // onMediaPicked(video.path, 'video');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, '选择视频失败: $e');
      }
    }
  }

  /// 录制语音
  Future<void> _recordVoice(BuildContext context) async {
    // TODO: 实现语音录制功能
    _showToast(context, '语音录制功能待实现');
  }

  /// 显示提示消息
  void _showToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: AppTextStyles.body.copyWith(color: CupertinoColors.white),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  /// 显示错误消息
  void _showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
