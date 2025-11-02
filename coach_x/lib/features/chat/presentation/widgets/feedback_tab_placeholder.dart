import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// Feedback Tab 占位符组件
/// 显示"Coming Soon"提示，待后续实现完整功能
class FeedbackTabPlaceholder extends StatelessWidget {
  const FeedbackTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.star_circle,
                size: 50,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            // 标题
            Text(
              'Feedback 功能',
              style: AppTextStyles.title2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // 副标题
            Text(
              'Coming Soon',
              style: AppTextStyles.title3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // 描述
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                '训练反馈功能正在开发中\n敬请期待',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // 功能预览
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '即将推出：',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('✓ 训练视频反馈'),
                  _buildFeatureItem('✓ 饮食记录反馈'),
                  _buildFeatureItem('✓ 按日期筛选'),
                  _buildFeatureItem('✓ 搜索功能'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能列表项
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
