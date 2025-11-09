import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 评论输入组件
class CommentsInputField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CommentsInputField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoTextField(
      placeholder: l10n.typeYourMessageHere,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        ),
      onChanged: onChanged,
      minLines: 4,
      maxLines: 8,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(12),
      ),
      style: AppTextStyles.footnote,
    );
  }
}
