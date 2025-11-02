import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../home/presentation/pages/coach_home_page.dart';
import '../../students/presentation/pages/students_page.dart';
import '../../plans/presentation/pages/plans_page.dart';
import '../../chat/presentation/pages/coach_chat_page.dart';
import '../../profile/presentation/pages/coach_profile_page.dart';

/// 教练Tab容器
///
/// 使用CupertinoTabScaffold实现教练端的底部导航
/// 包含5个Tab: Home, Students, Plans, Chat, Profile
class CoachTabScaffold extends StatelessWidget {
  /// 初始Tab索引
  final int initialTabIndex;

  const CoachTabScaffold({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.backgroundWhite.withValues(alpha: 0.9),
        activeColor: AppColors.primaryText,
        inactiveColor: AppColors.textSecondary,
        border: const Border(
          top: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
        iconSize: 24.0,
        items: [
          // Tab 0 - Home
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.house),
            activeIcon: const Icon(CupertinoIcons.house_fill),
            label: l10n.tabHome,
          ),

          // Tab 1 - Students
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.group),
            activeIcon: const Icon(CupertinoIcons.group_solid),
            label: l10n.tabStudents,
          ),

          // Tab 2 - Plans
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.list_bullet),
            activeIcon: const Icon(CupertinoIcons.list_bullet),
            label: l10n.tabPlans,
          ),

          // Tab 3 - Chat
          // TODO: 添加未读消息Badge
          // 实现方式: 使用Badge widget包裹图标
          // Provider: unreadMessageCountProvider (StreamProvider<int>)
          // Collection: messages
          // Query: where('receiverId', '==', currentUserId).where('isRead', '==', false)
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chat_bubble_2),
            activeIcon: const Icon(CupertinoIcons.chat_bubble_2_fill),
            label: l10n.tabChat,
          ),

          // Tab 4 - Profile
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person),
            activeIcon: const Icon(CupertinoIcons.person_fill),
            label: l10n.tabProfile,
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) => const CoachHomePage(),
            );
          case 1:
            return CupertinoTabView(builder: (context) => const StudentsPage());
          case 2:
            return CupertinoTabView(builder: (context) => const PlansPage());
          case 3:
            return CupertinoTabView(
              builder: (context) => const CoachChatPage(),
            );
          case 4:
            return CupertinoTabView(
              builder: (context) => const CoachProfilePage(),
            );
          default:
            return CupertinoTabView(
              builder: (context) => const CoachHomePage(),
            );
        }
      },
    );
  }
}
