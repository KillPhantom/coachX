import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 昵称编辑对话框
class EditNameDialog extends StatefulWidget {
  final String currentName;
  final Future<void> Function(String newName) onSave;

  const EditNameDialog({
    super.key,
    required this.currentName,
    required this.onSave,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    final newName = _controller.text.trim();

    if (newName.isEmpty) {
      return;
    }

    if (newName == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(newName);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: Text(l10n.editNickname),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CupertinoTextField(
          controller: _controller,
          placeholder: l10n.nicknamePlaceholder,
          autofocus: true,
          enabled: !_isSaving,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: AppTextStyles.body),
        ),
        CupertinoDialogAction(
          onPressed: _isSaving ? null : _handleSave,
          isDefaultAction: true,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(l10n.save, style: AppTextStyles.body),
        ),
      ],
    );
  }
}
