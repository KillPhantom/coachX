import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 祝贺横幅
///
/// 当所有 exercise 完成时显示，带有缩放动画效果
class CongratsBanner extends StatefulWidget {
  const CongratsBanner({super.key});

  @override
  State<CongratsBanner> createState() => _CongratsBannerState();
}

class _CongratsBannerState extends State<CongratsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 创建动画控制器 (1秒周期，循环播放)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // 创建缩放动画 (1.0 → 1.2 → 1.0)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        // 返回到 home page
        context.pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 庆祝图标（带缩放动画）
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                Icons.celebration,
                size: 24.0,
                color: AppColors.primaryAction,
              ),
            ),

            const SizedBox(width: 8.0),

            // 合并文字（单行）
            Flexible(
              child: Text(
                l10n.congratsMessageCompact,
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
