import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../providers/exercise_library_providers.dart';

/// Add Tag Dialog - 新增标签对话框
class AddTagDialog extends ConsumerStatefulWidget {
  const AddTagDialog({super.key});

  @override
  ConsumerState<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends ConsumerState<AddTagDialog> {
  final _controller = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final tagName = _controller.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (tagName.isEmpty) return;

    // 检查是否重复
    final tags = ref.read(exerciseTagsProvider);
    if (tags.any((t) => t.name == tagName)) {
      _showError(l10n.tagAlreadyExists);
      return;
    }

    setState(() => _isCreating = true);

    try {
      await ref
          .read(exerciseLibraryNotifierProvider.notifier)
          .createTag(tagName);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: Text(l10n.addTag),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CupertinoTextField(
          controller: _controller,
          placeholder: l10n.tagNameHint,
          autofocus: true,
          enabled: !_isCreating,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          onPressed: _isCreating ? null : _createTag,
          isDefaultAction: true,
          child: _isCreating
              ? const CupertinoActivityIndicator()
              : Text(l10n.save),
        ),
      ],
    );
  }
}
