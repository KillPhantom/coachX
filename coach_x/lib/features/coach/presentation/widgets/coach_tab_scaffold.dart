import 'package:flutter/cupertino.dart';
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
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.backgroundWhite.withValues(alpha: 0.9),
        activeColor: AppColors.primaryText,
        inactiveColor: AppColors.textSecondary,
        border: const Border(
          top: BorderSide(color: AppColors.dividerLight, width: 0.5),
        ),
        iconSize: 24.0,
        items: const [
          // Tab 0 - Home
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),

          // Tab 1 - Students
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.group),
            activeIcon: Icon(CupertinoIcons.group_solid),
            label: 'Students',
          ),

          // Tab 2 - Plans
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            activeIcon: Icon(CupertinoIcons.list_bullet),
            label: 'Plans',
          ),

          // Tab 3 - Chat
          // TODO: 添加未读消息Badge
          // 实现方式: 使用Badge widget包裹图标
          // Provider: unreadMessageCountProvider (StreamProvider<int>)
          // Collection: messages
          // Query: where('receiverId', '==', currentUserId).where('isRead', '==', false)
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
            label: 'Chat',
          ),

          // Tab 4 - Profile
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Profile',
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
