import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/features/chat/presentation/providers/feedback_providers.dart';

/// 训练反馈搜索栏
///
/// 提供搜索功能，可以按以下内容搜索：
/// - 训练摘要（exercises, sets, diet等）
/// - 教练反馈内容
class FeedbackSearchBar extends ConsumerWidget {
  const FeedbackSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(feedbackSearchQueryProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSearchTextField(
        placeholder: 'Search feedback...',
        controller: TextEditingController(text: searchQuery),
        onChanged: (value) {
          ref.read(feedbackSearchQueryProvider.notifier).state = value;
        },
        onSubmitted: (value) {
          ref.read(feedbackSearchQueryProvider.notifier).state = value;
        },
        backgroundColor: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemColor: AppColors.textSecondary,
        placeholderStyle: const TextStyle(color: AppColors.textTertiary),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
