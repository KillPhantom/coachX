import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../routes/app_router.dart';

/// CoachX应用根组件
class CoachXApp extends ConsumerWidget {
  const CoachXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoApp.router(
      title: 'CoachX',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      locale: const Locale('zh', 'CN'),
      debugShowCheckedModeBanner: false,
      // 完整的本地化支持 (使用delegates复数形式自动包含Cupertino支持)
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    );
  }
}
