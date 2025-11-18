import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../providers/training_review_providers.dart';

/// 训练审核筛选栏组件
///
/// 包含：搜索框 + 状态筛选按钮组
class TrainingReviewFilterBar extends ConsumerWidget {
  const TrainingReviewFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(reviewSearchQueryProvider);
    final statusFilter = ref.watch(reviewStatusFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // 搜索框
          CupertinoSearchTextField(
            placeholder: l10n.searchStudentName,
            controller: TextEditingController(text: searchQuery)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: searchQuery.length),
              ),
            onChanged: (value) {
              ref.read(reviewSearchQueryProvider.notifier).state = value;
            },
            onSubmitted: (value) {
              ref.read(reviewSearchQueryProvider.notifier).state = value;
            },
            backgroundColor: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            itemColor: AppColors.textSecondary,
            placeholderStyle: AppTextStyles.body.copyWith(
              color: AppColors.textTertiary,
            ),
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),

          const SizedBox(height: 12),

          // 状态筛选按钮组
          Row(
            children: [
              _FilterButton(
                label: l10n.filterAll,
                isActive: statusFilter == null,
                onTap: () {
                  ref.read(reviewStatusFilterProvider.notifier).state = null;
                },
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: l10n.filterPending,
                isActive: statusFilter == false,
                onTap: () {
                  ref.read(reviewStatusFilterProvider.notifier).state = false;
                },
              ),
              const SizedBox(width: 8),
              _FilterButton(
                label: l10n.filterReviewed,
                isActive: statusFilter == true,
                onTap: () {
                  ref.read(reviewStatusFilterProvider.notifier).state = true;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 筛选按钮组件
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.callout.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
