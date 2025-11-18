import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../providers/exercise_library_providers.dart';

/// Tag Filter Chips - 标签筛选组件
class TagFilterChips extends ConsumerWidget {
  const TagFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(exerciseTagsProvider);
    final state = ref.watch(exerciseLibraryNotifierProvider);
    final selectedTags = state.selectedTags;

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = selectedTags.contains(tag.name);

          return GestureDetector(
            onTap: () {
              ref
                  .read(exerciseLibraryNotifierProvider.notifier)
                  .toggleTagFilter(tag.name);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  tag.name,
                  style: AppTextStyles.callout.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
