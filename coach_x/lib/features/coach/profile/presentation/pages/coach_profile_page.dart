import 'package:flutter/cupertino.dart';

/// 教练资料页面（占位）
class CoachProfilePage extends StatelessWidget {
  const CoachProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('我的')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person, size: 80),
            const SizedBox(height: 20),
            const Text('教练资料页面', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('待实现', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }
}
