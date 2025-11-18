import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/student/training/data/models/keyframe_model.dart';

/// 视频关键帧垂直列表组件
///
/// 显示视频的关键帧图片（带时间戳），支持点击放大查看
class KeyframeGrid extends StatelessWidget {
  final List<KeyframeModel> keyframes;
  final Function(int index)? onTap;

  const KeyframeGrid({super.key, required this.keyframes, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (keyframes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 400, // 固定高度容纳5个关键帧
      child: SingleChildScrollView(
        child: Column(
          children: List.generate(
            keyframes.length,
            (index) => Padding(
              padding: EdgeInsets.only(
                bottom: index < keyframes.length - 1 ? 8.0 : 0,
              ),
              child: _KeyframeItem(
                keyframe: keyframes[index],
                index: index,
                onTap: () => onTap?.call(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个关键帧图片项
class _KeyframeItem extends StatelessWidget {
  final KeyframeModel keyframe;
  final int index;
  final VoidCallback? onTap;

  const _KeyframeItem({
    required this.keyframe,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dividerLight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 关键帧图片（支持本地和远程）
            _buildKeyframeImage(),

            // 时间戳标签
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  keyframe.formattedTimestamp,
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.backgroundWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建关键帧图片（支持本地文件和远程URL）
  Widget _buildKeyframeImage() {
    final localPath = keyframe.localPath;
    final remoteUrl = keyframe.url;

    // 优先显示本地图片（更快）
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.data == true) {
            // 本地文件存在，显示本地图片
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 本地图片加载失败，尝试显示远程图片
                if (remoteUrl != null && remoteUrl.isNotEmpty) {
                  return _buildRemoteImage(remoteUrl);
                }
                return _buildPlaceholder();
              },
            );
          } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
            // 本地文件已删除，显示远程图片
            return _buildRemoteImage(remoteUrl);
          } else {
            return const Center(child: CupertinoActivityIndicator());
          }
        },
      );
    } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
      // 只有远程URL
      return _buildRemoteImage(remoteUrl);
    } else {
      // 都没有，显示加载中
      return const Center(child: CupertinoActivityIndicator());
    }
  }

  /// 构建远程图片
  Widget _buildRemoteImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const Center(child: CupertinoActivityIndicator()),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        CupertinoIcons.photo,
        color: AppColors.textTertiary,
        size: 24,
      ),
    );
  }
}
