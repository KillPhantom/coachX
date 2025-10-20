import 'package:flutter/cupertino.dart';

/// 学生对话页面（占位）
class StudentChatPage extends StatelessWidget {
  const StudentChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('对话')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.chat_bubble_2, size: 80),
            const SizedBox(height: 20),
            const Text('学生对话页面', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('待实现', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }
}
