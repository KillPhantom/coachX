import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../data/models/exercise_template_model.dart';

/// Exercise Template Card - 动作模板卡片
class ExerciseTemplateCard extends StatelessWidget {
  final ExerciseTemplateModel template;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExerciseTemplateCard({
    super.key,
    required this.template,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingS,
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 视频缩略图或占位符
            _buildThumbnail(),
            const SizedBox(width: AppDimensions.spacingM),

            // 内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 动作名称
                  Text(
                    template.name,
                    style: AppTextStyles.callout,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),

                  // 标签
                  if (template.tags.isNotEmpty) _buildTags(),
                ],
              ),
            ),

            // 箭头
            const Icon(
              CupertinoIcons.forward,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildThumbnailContent(),
      ),
    );
  }

  Widget _buildThumbnailContent() {
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Icon(
      Icons.fitness_center,
      size: 32,
      color: AppColors.primaryAction,
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: template.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: AppTextStyles.caption2.copyWith(
              color: AppColors.primaryAction,
            ),
          ),
        );
      }).toList(),
    );
  }
}
