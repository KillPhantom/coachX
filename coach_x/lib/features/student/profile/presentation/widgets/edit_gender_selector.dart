import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/enums/gender.dart';

/// 性别选择器
class EditGenderSelector extends StatelessWidget {
  final Gender? currentGender;
  final Future<void> Function(Gender newGender) onSave;

  const EditGenderSelector({
    super.key,
    this.currentGender,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoActionSheet(
      title: Text(l10n.selectGender),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.of(context).pop();
            await onSave(Gender.male);
          },
          child: Text(l10n.male, style: AppTextStyles.body),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.of(context).pop();
            await onSave(Gender.female);
          },
          child: Text(l10n.female, style: AppTextStyles.body),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDestructiveAction: true,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.cancel, style: AppTextStyles.body),
      ),
    );
  }
}
