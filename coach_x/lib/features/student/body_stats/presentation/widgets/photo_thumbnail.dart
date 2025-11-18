import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 照片缩略图组件
///
/// 显示照片缩略图，右上角有删除按钮
class PhotoThumbnail extends StatelessWidget {
  /// 照片本地路径
  final String localPath;

  /// 删除回调
  final VoidCallback onDelete;

  /// 尺寸
  final double size;

  const PhotoThumbnail({
    super.key,
    required this.localPath,
    required this.onDelete,
    this.size = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.dividerLight, width: 1.0),
      ),
      child: Stack(
        children: [
          // 照片
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Image.file(
              File(localPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.dividerLight,
                  child: const Icon(
                    CupertinoIcons.photo,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),

          // 删除按钮（右上角）
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 14,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
