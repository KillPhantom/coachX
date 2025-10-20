import 'package:flutter/cupertino.dart';

/// 学生列表页面（占位）
class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('学生列表')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.group, size: 80),
            const SizedBox(height: 20),
            const Text('学生列表页面', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('待实现', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }
}
