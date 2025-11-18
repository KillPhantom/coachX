import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'core/utils/logger.dart';
import 'core/services/firebase_init_service.dart';
import 'core/services/user_cache_service.dart';
import 'core/services/bootstrap_service.dart';
import 'core/services/cache/cache_helper.dart';
import 'core/services/cache/cache_metadata.dart';
import 'core/models/video_cache_metadata.dart';
import 'core/services/video_cache_service.dart';
import 'features/coach/exercise_library/data/models/exercise_template_model.dart';
import 'features/coach/exercise_library/data/models/exercise_tag_model.dart';
import 'features/coach/students/data/models/student_list_item_model.dart';
import 'features/coach/students/data/models/student_plan_info.dart';

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

  // 初始化用户缓存服务
  try {
    await UserCacheService.initialize();
  } catch (e, stackTrace) {
    AppLogger.error('UserCacheService初始化失败', e, stackTrace);
  }

  // 确定初始路由
  final initialRoute = await BootstrapService.determineInitialRoute();

  // 初始化Hive
  try {
    await CacheHelper.initializeHive();

    // 注册 TypeAdapter
    // Cache Infrastructure
    Hive.registerAdapter(CacheMetadataAdapter());
    Hive.registerAdapter(VideoCacheMetadataAdapter());

    // Exercise Library
    Hive.registerAdapter(ExerciseTemplateModelAdapter());
    Hive.registerAdapter(ExerciseTagModelAdapter());

    // Students
    Hive.registerAdapter(StudentListItemModelAdapter());
    Hive.registerAdapter(StudentPlanInfoAdapter());

    AppLogger.info('✅ Hive 和所有 TypeAdapter 初始化成功');

    // 初始化视频缓存服务
    final videoCacheService = VideoCacheService();
    await videoCacheService.initializeCache();

    // 清理过期的视频缓存
    await videoCacheService.clearExpiredCache();

    AppLogger.info('✅ 视频缓存服务初始化成功');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Hive初始化失败', e, stackTrace);
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
  runApp(ProviderScope(child: CoachXApp(initialRoute: initialRoute)));
}
