import 'package:flutter/cupertino.dart';

/// 教练对话页面（占位）
class CoachChatPage extends StatelessWidget {
  const CoachChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.chat_bubble_2, size: 80),
            const SizedBox(height: 20),
            const Text(
              '教练对话页面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '待实现',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}
