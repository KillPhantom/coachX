import 'package:flutter/cupertino.dart';
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
      // 使用Material Localizations支持Cupertino组件
      localizationsDelegates: const [DefaultCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    );
  }
}
