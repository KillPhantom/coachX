import 'package:flutter/cupertino.dart';

/// 教练首页（占位）
class CoachHomePage extends StatelessWidget {
  const CoachHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('教练首页')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.home, size: 80),
            const SizedBox(height: 20),
            const Text('教练首页', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('待实现', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }
}
