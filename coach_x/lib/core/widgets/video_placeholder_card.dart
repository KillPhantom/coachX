import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 视频占位符卡片
///
/// 显示虚线边框和上传图标，点击打开相机录制
class VideoPlaceholderCard extends StatelessWidget {
  final VoidCallback onTap;
  final double width;
  final double height;

  const VideoPlaceholderCard({
    super.key,
    required this.onTap,
    this.width = 100,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.dividerLight,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 相机图标
            Icon(
              CupertinoIcons.videocam,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            // 文字
            Text(
              l10n.recordVideo,
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
