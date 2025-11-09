import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'video_thumbnail_card.dart';
import 'video_placeholder_card.dart';
import 'video_player_modal.dart';

/// My Recordings 区域组件
///
/// 显示已录制的视频列表（横向滚动）和添加按钮
class MyRecordingsSection extends StatelessWidget {
  final List<String> videos;
  final Function(File) onVideoRecorded;
  final Function(int) onDeleteVideo;
  final int maxVideos;

  const MyRecordingsSection({
    super.key,
    required this.videos,
    required this.onVideoRecorded,
    required this.onDeleteVideo,
    this.maxVideos = 3,
  });

  bool get canAddMore => videos.length < maxVideos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          l10n.myRecordings,
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppDimensions.spacingS),

        // 视频列表（横向滚动）
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 显示已有视频
              if (index < videos.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                  child: VideoThumbnailCard(
                    videoUrl: videos[index],
                    onTap: () {
                      // 打开视频播放器
                      VideoPlayerModal.show(
                        context,
                        videoUrls: videos,
                      );
                    },
                    onDelete: () => onDeleteVideo(index),
                  ),
                );
              }

              // 显示添加按钮
              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                child: VideoPlaceholderCard(
                  onTap: () => _showRecordOptions(context),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 显示录制选项（相机录制 or 从相册选择）
  void _showRecordOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.recordVideo),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 打开相机录制页面
              // 使用 go_router 导航到 CameraRecordPage
              _showTodoAlert(context, l10n.recordingVideo);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.videocam, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n.recordingVideo,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 从相册选择视频
              _showTodoAlert(context, l10n.selectFromGallery);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.photo, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n.selectFromGallery,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 显示TODO提示
  void _showTodoAlert(BuildContext context, String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('TODO'),
        content: Text('$feature 功能开发中...'),
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
