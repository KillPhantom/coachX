import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 学生训练页面（占位）
class TrainingPage extends StatelessWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.sportscourt, size: 80),
            const SizedBox(height: 20),
            Text(
              l10n.trainingPageTitle,
              style: AppTextStyles.title2,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.toBeImplemented,
              style: AppTextStyles.callout,
            ),
          ],
        ),
      ),
    );
  }
}
