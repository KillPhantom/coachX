import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/exercise_library/data/models/exercise_template_model.dart';
import '../providers/exercise_template_search_providers.dart';

/// 动作自动完成输入框
///
/// 支持从动作库搜索并选择模板，或手动输入动作名称
class ExerciseAutocompleteField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<ExerciseTemplateModel?>? onTemplateSelected;
  final String? placeholder;

  const ExerciseAutocompleteField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onTemplateSelected,
    this.placeholder,
  });

  @override
  ConsumerState<ExerciseAutocompleteField> createState() =>
      _ExerciseAutocompleteFieldState();
}

class _ExerciseAutocompleteFieldState
    extends ConsumerState<ExerciseAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions =
          _focusNode.hasFocus && widget.controller.text.isNotEmpty;
    });
  }

  void _onTextChanged(String value) {
    setState(() {
      _showSuggestions = value.isNotEmpty && _focusNode.hasFocus;
    });
    widget.onChanged?.call(value);
  }

  void _selectTemplate(ExerciseTemplateModel template) {
    widget.controller.text = template.name;
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onTemplateSelected?.call(template);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = widget.controller.text.isNotEmpty
        ? ref.watch(exerciseTemplateSearchProvider(widget.controller.text))
        : <ExerciseTemplateModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 输入框
        CupertinoTextField(
          style: AppTextStyles.caption1,
          placeholder: widget.placeholder ?? l10n.exerciseNamePlaceholder,
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // 建议列表
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
              itemBuilder: (context, index) {
                final template = suggestions[index];
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  onPressed: () => _selectTemplate(template), minimumSize: Size(0, 0),
                  child: Row(
                    children: [
                      // 模板图标
                      Icon(
                        CupertinoIcons.square_stack_3d_up,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),

                      // 名称和标签
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: AppTextStyles.caption1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (template.tags.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                template.tags.join(', '),
                                style: AppTextStyles.caption2.copyWith(
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
