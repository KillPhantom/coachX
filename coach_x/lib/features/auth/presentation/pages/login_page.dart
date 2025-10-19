import 'package:flutter/cupertino.dart';

/// 登录页面（占位）
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('登录')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_circle, size: 80),
            const SizedBox(height: 20),
            const Text(
              '登录页面',
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
