import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../providers/plan_page_providers.dart';

/// 部位筛选标签组件
///
/// 显示训练计划中所有不同的部位（基于 ExerciseTrainingDay.name）
/// 支持点击切换选中状态
class BodyPartChips extends ConsumerWidget {
  final List<String> bodyParts;

  const BodyPartChips({super.key, required this.bodyParts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBodyPart = ref.watch(selectedBodyPartProvider);

    if (bodyParts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bodyParts.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spacingS),
        itemBuilder: (context, index) {
          final bodyPart = bodyParts[index];
          final isSelected = selectedBodyPart == bodyPart;

          return GestureDetector(
            onTap: () {
              // 如果点击已选中的部位，则取消选中（显示全部）
              if (isSelected) {
                ref.read(selectedBodyPartProvider.notifier).state = null;
              } else {
                ref.read(selectedBodyPartProvider.notifier).state = bodyPart;
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.dividerLight,
                  width: 1,
                ),
              ),
              child: Text(
                bodyPart,
                style: AppTextStyles.callout.copyWith(
                  color: isSelected
                      ? AppColors.primaryText
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
