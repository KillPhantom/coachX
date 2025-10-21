import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/cupertino_card.dart';
import '../../data/models/recent_activity_model.dart';

/// Recent Activity单项组件
///
/// 用于显示单个学生的最近活跃记录
class RecentActivityItem extends StatelessWidget {
  /// Recent Activity数据
  final RecentActivityModel activity;

  /// 点击回调
  final VoidCallback? onTap;

  const RecentActivityItem({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoCard(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      onTap: onTap,
      child: Row(
        children: [
          // 头像
          _buildAvatar(),
          const SizedBox(width: AppDimensions.spacingM),

          // 学生信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.studentName, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2.0),
                Text(
                  activity.timeAgo,
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 箭头图标
          Icon(
            CupertinoIcons.chevron_right,
            size: 20.0,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.avatarM / 2),
      child: Container(
        width: AppDimensions.avatarM,
        height: AppDimensions.avatarM,
        color: AppColors.secondaryGrey,
        child: activity.avatarUrl != null && activity.avatarUrl!.isNotEmpty
            ? Image.network(
                activity.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildAvatarPlaceholder(),
              )
            : _buildAvatarPlaceholder(),
      ),
    );
  }

  /// 构建头像占位图标
  Widget _buildAvatarPlaceholder() {
    return Icon(
      CupertinoIcons.person_fill,
      size: 24.0,
      color: AppColors.textTertiary,
    );
  }
}
