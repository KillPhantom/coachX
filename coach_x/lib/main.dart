import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/utils/logger.dart';
import 'core/services/firebase_init_service.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志
  AppLogger.info('CoachX应用启动');

  // 初始化Firebase
  try {
    await FirebaseInitService.initialize();
  } catch (e, stackTrace) {
    AppLogger.error('Firebase初始化失败', e, stackTrace);
    // 继续运行应用，以便看到错误信息
  }

  // 初始化Hive
  try {
    await Hive.initFlutter();
    AppLogger.info('Hive初始化成功');
  } catch (e, stackTrace) {
    AppLogger.error('Hive初始化失败', e, stackTrace);
  }

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: CupertinoColors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 设置首选方向（仅竖屏）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 运行应用
  runApp(const ProviderScope(child: CoachXApp()));
}
