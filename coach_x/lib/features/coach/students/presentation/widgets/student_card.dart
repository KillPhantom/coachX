import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/cupertino_card.dart';
import '../../data/models/student_list_item_model.dart';
import 'package:flutter/material.dart' show Icons;

/// 学生卡片组件
class StudentCard extends StatelessWidget {
  final StudentListItemModel student;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Row(
        children: [
          // 头像
          _buildAvatar(),

          const SizedBox(width: AppDimensions.spacingL),

          // 学生信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 姓名
                Text(student.name, style: AppTextStyles.bodyMedium),

                const SizedBox(height: AppDimensions.spacingS),

                // 训练计划
                if (student.exercisePlan != null)
                  _buildPlanInfo(
                    icon: Icons.fitness_center,
                    label: student.exercisePlan!.name,
                  ),

                // 饮食计划
                if (student.dietPlan != null) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  _buildPlanInfo(
                    icon: CupertinoIcons.square_list,
                    label: student.dietPlan!.name,
                  ),
                ],

                // 补剂计划
                if (student.supplementPlan != null) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  _buildPlanInfo(
                    icon: CupertinoIcons.capsule,
                    label: student.supplementPlan!.name,
                  ),
                ],

                // 无计划提示
                if (!student.hasAnyPlan) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '未分配计划',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 更多按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onMoreTap,
            child: const Icon(
              CupertinoIcons.ellipsis_vertical,
              color: AppColors.textSecondary,
              size: AppDimensions.iconM,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    if (student.avatarUrl != null && student.avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: CachedNetworkImage(
          imageUrl: student.avatarUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 48,
            height: 48,
            color: AppColors.primaryLight,
            child: Center(
              child: Text(
                student.nameInitial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        ),
      );
    }

    return _buildDefaultAvatar();
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          student.nameInitial,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  /// 构建计划信息
  Widget _buildPlanInfo({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconS, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingXS),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
