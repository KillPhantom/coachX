import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../home/presentation/pages/student_home_page.dart';
import '../../training/presentation/pages/training_page.dart';
import '../../chat/presentation/pages/student_chat_page.dart';
import '../../profile/presentation/pages/student_profile_page.dart';

/// 学生Tab容器
///
/// 使用CupertinoTabScaffold实现学生端的底部导航
/// 包含5个Tab: Home, Plan, Add(中间突出), Chat, Profile
class StudentTabScaffold extends StatelessWidget {
  /// 初始Tab索引
  final int initialTabIndex;

  const StudentTabScaffold({super.key, this.initialTabIndex = 0});

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
            icon: Icon(CupertinoIcons.house),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: l10n.tabHome,
          ),

          // Tab 1 - Plan
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            activeIcon: Icon(CupertinoIcons.calendar_today),
            label: l10n.tabPlan,
          ),

          // Tab 2 - Add (特殊中间突出按钮)
          BottomNavigationBarItem(
            icon: Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.add,
                size: 28.0,
                color: AppColors.primaryText,
              ),
            ),
            label: '',
          ),

          // Tab 3 - Chat
          // TODO: 添加未读消息Badge
          // 实现方式: 使用Badge widget包裹图标
          // Provider: unreadMessageCountProvider (StreamProvider<int>)
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
            label: l10n.tabChat,
          ),

          // Tab 4 - Profile
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: l10n.tabProfile,
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) => const StudentHomePage(),
            );
          case 1:
            return CupertinoTabView(builder: (context) => const TrainingPage());
          case 2:
            // Add按钮点击显示ActionSheet
            return CupertinoTabView(
              builder: (context) {
                // 自动显示ActionSheet
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showAddActionSheet(context);
                });
                return const StudentHomePage(); // 保持在Home页面
              },
            );
          case 3:
            return CupertinoTabView(
              builder: (context) => const StudentChatPage(),
            );
          case 4:
            return CupertinoTabView(
              builder: (context) => const StudentProfilePage(),
            );
          default:
            return CupertinoTabView(
              builder: (context) => const StudentHomePage(),
            );
        }
      },
    );
  }

  /// 显示添加选项ActionSheet
  void _showAddActionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.addRecordTitle),
        message: Text(l10n.chooseRecordType),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 跳转到训练记录页面
              // 路由: /student/training/add
              _showTodoAlert(context, l10n.trainingRecord, '跳转到训练记录添加页面');
            },
            child: Text(l10n.trainingRecord),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 跳转到饮食记录页面
              // 路由: /student/diet/add
              _showTodoAlert(context, l10n.dietRecord, '跳转到饮食记录添加页面');
            },
            child: Text(l10n.dietRecord),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 跳转到补剂记录页面
              // 路由: /student/supplement/add
              _showTodoAlert(context, l10n.supplementRecord, '跳转到补剂记录添加页面');
            },
            child: Text(l10n.supplementRecord),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 跳转到身体测量页面
              // 路由: /student/body-stats/add
              _showTodoAlert(context, l10n.bodyMeasurement, '跳转到身体测量添加页面');
            },
            child: Text(l10n.bodyMeasurement),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 显示TODO提示
  void _showTodoAlert(BuildContext context, String title, String message) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('TODO: $title'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.know),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
