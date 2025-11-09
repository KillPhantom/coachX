import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import '../../home/presentation/pages/student_home_page.dart';
import '../../training/presentation/pages/training_page.dart';
import '../../chat/presentation/pages/student_chat_page.dart';
import '../../profile/presentation/pages/student_profile_page.dart';
import 'record_activity_bottom_sheet.dart';

/// 学生Tab容器
///
/// 使用CupertinoTabScaffold实现学生端的底部导航
/// 包含5个Tab: Home, Plan, Add(中间突出), Chat, Profile
class StudentTabScaffold extends StatefulWidget {
  /// 初始Tab索引
  final int initialTabIndex;

  const StudentTabScaffold({super.key, this.initialTabIndex = 0});

  @override
  State<StudentTabScaffold> createState() => _StudentTabScaffoldState();
}

class _StudentTabScaffoldState extends State<StudentTabScaffold> {
  late CupertinoTabController _tabController;
  bool _isHandlingAddTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// 处理 Tab 切换
  void _handleTabChange() {
    if (_tabController.index == 2 && !_isHandlingAddTab) {
      _isHandlingAddTab = true;

      // 立即切回 Home tab
      Future.microtask(() {
        if (mounted) {
          _tabController.index = 0;
        }
      });

      // 显示 RecordActivityBottomSheet
      Future.microtask(() {
        if (mounted) {
          RecordActivityBottomSheet.show(context).then((_) {
            // 弹窗关闭后重置标志位
            _isHandlingAddTab = false;
          });
        }
      });
    }
  }

  /// 处理浮动按钮点击
  void _handleFloatingButtonTap() {
    if (!_isHandlingAddTab) {
      _isHandlingAddTab = true;
      RecordActivityBottomSheet.show(context).then((_) {
        _isHandlingAddTab = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // 主要的 TabScaffold
        CupertinoTabScaffold(
          controller: _tabController,
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

              // Tab 2 - Add (占位符，实际按钮在 Stack 顶层)
              BottomNavigationBarItem(
                icon: Opacity(opacity: 0.0, child: Icon(CupertinoIcons.add)),
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
                return CupertinoTabView(
                  builder: (context) => const TrainingPage(),
                );
              case 2:
                // Tab 2 由 listener 处理，这里返回空白页
                return CupertinoTabView(
                  builder: (context) => const SizedBox.shrink(),
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
        ),

        // 浮动的中间按钮（覆盖在 TabBar 上方）
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -10.0),
                child: GestureDetector(
                  onTap: _handleFloatingButtonTap,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20.0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.shadowColor.withValues(alpha: 0.12),
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      size: 32,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
