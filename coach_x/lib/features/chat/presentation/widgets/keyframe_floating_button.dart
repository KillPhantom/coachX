import 'package:flutter/cupertino.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_text_styles.dart';

class KeyframeFloatingButton extends StatelessWidget {
  final VoidCallback onTap;

  const KeyframeFloatingButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.black.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.camera,
              size: 24,
              color: CupertinoColors.white,
            ),
            const SizedBox(height: 2),
            Text(
              l10n.extractKeyframe,
              style: AppTextStyles.caption2.copyWith(
                color: CupertinoColors.white,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
