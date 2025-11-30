import 'package:flutter/cupertino.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../l10n/app_localizations.dart';

/// 删除模板错误对话框
///
/// 当尝试删除正在被使用的模板时显示
class DeleteTemplateErrorDialog {
  /// 显示错误对话框
  static void show(BuildContext context, int planCount) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.cannotDeleteTemplate),
        content: Text(l10n.templateInUse(planCount)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok, style: AppTextStyles.body),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
