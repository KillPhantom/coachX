import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'badge_chip.dart';

/// Profile 页面头部组件
///
/// 显示用户头像、姓名、角色标签或认证标签
class ProfileHeader extends StatelessWidget {
  /// 头像 URL
  final String? avatarUrl;

  /// 用户姓名
  final String name;

  /// 角色文本（如 "Student" 或 "Coach"）
  final String? roleText;

  /// 认证标签列表（如 ["IFFF Pro", "Certified"]）
  final List<String>? tags;

  /// 编辑按钮点击回调
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    this.avatarUrl,
    required this.name,
    this.roleText,
    this.tags,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.spacingL),

        // 头像和编辑按钮
        _buildAvatar(),

        const SizedBox(height: AppDimensions.spacingL),

        // 姓名
        Text(
          name,
          style: AppTextStyles.title1,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppDimensions.spacingS),

        // 角色文本或认证标签
        if (roleText != null && (tags == null || tags!.isEmpty))
          Text(
            roleText!,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

        // 认证标签
        if (tags != null && tags!.isNotEmpty)
          _buildTags(),
      ],
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Stack(
      children: [
        // 头像
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundSecondary,
          ),
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    width: 128,
                    height: 128,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  ),
                )
              : _buildDefaultAvatar(),
        ),

        // 编辑按钮
        if (onEditTap != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryGrey,
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return const Icon(
      CupertinoIcons.person_fill,
      size: 64,
      color: AppColors.textTertiary,
    );
  }

  /// 构建认证标签
  Widget _buildTags() {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      alignment: WrapAlignment.center,
      children: tags!.map((tag) => BadgeChip(tag: tag)).toList(),
    );
  }
}
