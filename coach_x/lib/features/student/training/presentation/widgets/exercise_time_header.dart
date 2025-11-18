import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 动作耗时 Header 组件
///
/// 显示某个 Exercise 完成后的耗时
class ExerciseTimeHeader extends StatelessWidget {
  final int timeSpent; // 秒数

  const ExerciseTimeHeader({super.key, required this.timeSpent});

  /// 格式化耗时为 MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.timer,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${l10n.timeSpentLabel}: ${_formatTime(timeSpent)}',
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
