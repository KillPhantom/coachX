import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/providers/feedback_providers.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 训练反馈排序按钮
///
/// 提供 Asc / Desc 排序切换
class FeedbackSortButton extends ConsumerWidget {
  const FeedbackSortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDescending = ref.watch(feedbackSortOrderProvider);

    return Container(
      width: 80,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _SortSegment(
            label: l10n.feedbackSortAscLabel,
            isActive: !isDescending,
            isFirst: true,
            onTap: () =>
                ref.read(feedbackSortOrderProvider.notifier).state = false,
          ),
          _SortSegment(
            label: l10n.feedbackSortDescLabel,
            isActive: isDescending,
            isFirst: false,
            onTap: () =>
                ref.read(feedbackSortOrderProvider.notifier).state = true,
          ),
        ],
      ),
    );
  }
}

class _SortSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isFirst;
  final VoidCallback onTap;

  const _SortSegment({
    required this.label,
    required this.isActive,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(18) : Radius.zero,
      right: isFirst ? Radius.zero : const Radius.circular(18),
    );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryLight
                : CupertinoColors.transparent,
            borderRadius: radius,
          ),
          child: Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: isActive
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
