import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/chat/presentation/pages/chat_list_page.dart';

/// 教练对话页面
/// 使用共享的ChatListPage组件
class CoachChatPage extends StatelessWidget {
  const CoachChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListPage();
  }
}
