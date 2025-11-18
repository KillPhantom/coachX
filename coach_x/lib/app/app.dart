import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/locale_providers.dart';
import '../routes/app_router.dart';
import '../routes/route_names.dart';

/// CoachX应用根组件
class CoachXApp extends ConsumerWidget {
  final String initialRoute;

  const CoachXApp({super.key, this.initialRoute = RouteNames.login});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听用户的语言偏好
    final locale = ref.watch(currentLocaleProvider);

    // 获取路由配置（单例，避免热重载时重新创建）
    final router = getAppRouter(initialRoute);

    return CupertinoApp.router(
      title: 'CoachX',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      // 使用用户设置的语言，如果为 null 则使用系统默认语言
      locale: locale,
      debugShowCheckedModeBanner: false,
      // 完整的本地化支持
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
    );
  }
}
