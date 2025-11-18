import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../data/models/exercise_tag_model.dart';
import 'add_tag_dialog.dart';

/// Tag Selector - 标签选择器
///
/// 横向滚动的标签列表，支持多选和新增标签
class TagSelector extends StatelessWidget {
  final List<String> selectedTags;
  final List<ExerciseTagModel> availableTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.availableTags,
    required this.onTagsChanged,
  });

  void _toggleTag(String tagName) {
    final newTags = List<String>.from(selectedTags);
    if (newTags.contains(tagName)) {
      newTags.remove(tagName);
    } else {
      newTags.add(tagName);
    }
    onTagsChanged(newTags);
  }

  Future<void> _showAddTagDialog(BuildContext context) async {
    return showCupertinoDialog(
      context: context,
      builder: (context) => const AddTagDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectTags, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppDimensions.spacingS),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: availableTags.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              // 最后一个是添加按钮
              if (index == availableTags.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                    ),
                    color: AppColors.dividerLight,
                    minimumSize: Size.zero,
                    onPressed: () => _showAddTagDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.add,
                          size: 16,
                          color: AppColors.primaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.addTag,
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final tag = availableTags[index];
              final isSelected = selectedTags.contains(tag.name);

              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                  ),
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.dividerLight,
                  minimumSize: Size.zero,
                  onPressed: () => _toggleTag(tag.name),
                  child: Text(
                    tag.name,
                    style: AppTextStyles.footnote.copyWith(
                      color: isSelected
                          ? AppColors.primaryText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 验证提示
        if (selectedTags.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacingS),
            child: Text(
              l10n.atLeastOneTag,
              style: AppTextStyles.caption1.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
      ],
    );
  }
}
