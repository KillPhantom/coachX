import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/chat/presentation/pages/chat_detail_page.dart';

/// 学生对话页面
/// 直接显示与教练的对话
class StudentChatPage extends ConsumerWidget {
  const StudentChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, l10n, error),
      data: (user) {
        // 用户未登录
        if (user == null) {
          return _buildErrorState(context, l10n, '用户未登录');
        }

        // 学生没有教练
        if (user.coachId == null || user.coachId!.isEmpty) {
          return _buildNoCoachState(context, l10n);
        }

        // 构建 conversationId
        final conversationId = 'coach_${user.coachId}_student_${user.id}';

        // 直接显示对话详情页面
        return ChatDetailPage(conversationId: conversationId);
      },
    );
  }

  /// 加载状态
  Widget _buildLoadingState() {
    return const Center(child: CupertinoActivityIndicator(radius: 16));
  }

  /// 错误状态
  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l10n,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 20),
            Text(l10n.loadFailed, style: AppTextStyles.title3),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 没有教练状态
  Widget _buildNoCoachState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_2,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noCoachTitle,
              style: AppTextStyles.title3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noCoachMessage,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
