import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import '../../data/models/plan_base_model.dart';
import 'package:flutter/material.dart' show Icons;

/// 计划卡片组件
class PlanCard extends StatelessWidget {
  final PlanBaseModel plan;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingS,
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：图标、标题、更多按钮
            Row(
              children: [
                // 彩色圆形图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getPlanColor().withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getPlanIcon(), color: _getPlanColor(), size: 24),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                // 计划名称和描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTextStyles.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (plan.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          plan.description,
                          style: AppTextStyles.footnote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // 更多按钮
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onMoreTap, minimumSize: Size(32, 32),
                  child: const Icon(
                    CupertinoIcons.ellipsis,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            // 分割线
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingM,
              ),
              child: Container(height: 0.5, color: AppColors.dividerLight),
            ),
            // 底部：学生数量
            Text(
              'Used by ${plan.studentCount} student${plan.studentCount != 1 ? 's' : ''}',
              style: AppTextStyles.footnote,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据计划类型获取图标
  IconData _getPlanIcon() {
    switch (plan.planType) {
      case 'exercise':
        return Icons.fitness_center;
      case 'diet':
        return CupertinoIcons.square_favorites_alt_fill;
      case 'supplement':
        return CupertinoIcons.capsule_fill;
      default:
        return CupertinoIcons.list_bullet;
    }
  }

  /// 根据计划类型获取颜色
  Color _getPlanColor() {
    switch (plan.planType) {
      case 'exercise':
        return const Color(0xFFEC1313); // 红色
      case 'diet':
        return AppColors.successGreen; // 绿色
      case 'supplement':
        return AppColors.infoBlue; // 蓝色
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
