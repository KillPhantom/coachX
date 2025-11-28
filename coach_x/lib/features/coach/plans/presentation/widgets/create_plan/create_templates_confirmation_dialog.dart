import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';

class CreateTemplatesConfirmationDialog extends StatelessWidget {
  final int newExerciseCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CreateTemplatesConfirmationDialog({
    super.key,
    required this.newExerciseCount,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int newExerciseCount,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CreateTemplatesConfirmationDialog(
        newExerciseCount: newExerciseCount,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: Text(
        l10n.confirmCreateTemplatesTitle,
        style: AppTextStyles.bodyMedium,
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          l10n.confirmCreateTemplates(newExerciseCount),
          style: AppTextStyles.body,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel,
          child: Text(l10n.cancel, style: AppTextStyles.buttonMedium),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: onConfirm,
          child: Text(l10n.confirmCreateButton, style: AppTextStyles.buttonMedium),
        ),
      ],
    );
  }
}
