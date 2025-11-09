import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/shared/profile/presentation/widgets/badge_chip.dart';
import 'package:intl/intl.dart';

/// 教练信息卡片组件（学生专用）
///
/// 显示学生的教练信息，包括头像、姓名、认证标签、合约有效期
class CoachInfoCard extends StatelessWidget {
  /// 教练信息
  final UserModel coach;

  /// 合约有效期
  final DateTime? contractExpiresAt;

  const CoachInfoCard({super.key, required this.coach, this.contractExpiresAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          // 教练头像
          _buildAvatar(),

          const SizedBox(width: AppDimensions.spacingL),

          // 教练信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 教练姓名
                Text(coach.name, style: AppTextStyles.title3),

                const SizedBox(height: AppDimensions.spacingS),

                // 认证标签
                if (coach.tags != null && coach.tags!.isNotEmpty)
                  Wrap(
                    spacing: AppDimensions.spacingS,
                    runSpacing: AppDimensions.spacingS,
                    children: coach.tags!
                        .map((tag) => BadgeChip(tag: tag))
                        .toList(),
                  ),

                const SizedBox(height: AppDimensions.spacingS),

                // 合约有效期
                if (contractExpiresAt != null)
                  Text(
                    'until ${_formatDate(contractExpiresAt!)}',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建教练头像
  Widget _buildAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundSecondary,
      ),
      child: coach.avatarUrl != null && coach.avatarUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                coach.avatarUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return const Icon(
      CupertinoIcons.person_fill,
      size: 32,
      color: AppColors.textTertiary,
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
