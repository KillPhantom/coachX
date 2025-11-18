import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:coach_x/firebase_options.dart';
import 'package:coach_x/core/constants/app_constants.dart';
import 'package:coach_x/core/utils/logger.dart';

/// Firebase初始化服务
///
/// 负责应用启动时初始化Firebase相关服务
class FirebaseInitService {
  FirebaseInitService._();

  /// 初始化Firebase
  ///
  /// 在应用启动时调用，初始化Firebase核心服务
  /// 并配置Firestore、Storage等服务
  static Future<void> initialize() async {
    try {
      AppLogger.info('开始初始化Firebase...');

      // 初始化Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      AppLogger.info('Firebase Core 初始化成功');

      // 🔧 开发模式：连接到本地模拟器
      // Release 模式：连接到生产 Firebase Cloud APIs
      if (kDebugMode) {
        AppLogger.info('🔧 Debug 模式 - 使用本地 Firebase Emulators');
        AppLogger.info(
          '📡 Emulator 地址: ${AppConstants.firebaseEmulatorHost}:${AppConstants.firebaseFunctionsEmulatorPort}',
        );

        // Functions Emulator
        FirebaseFunctions.instance.useFunctionsEmulator(
          AppConstants.firebaseEmulatorHost,
          AppConstants.firebaseFunctionsEmulatorPort,
        );

        // Firestore Emulator (如果需要)
        // FirebaseFirestore.instance.useFirestoreEmulator(
        //   AppConstants.firebaseEmulatorHost,
        //   AppConstants.firebaseFirestoreEmulatorPort,
        // );
      } else {
        AppLogger.info('🚀 Release 模式 - 使用生产 Firebase Cloud APIs');
      }

      // 配置Firestore
      _configureFirestore();

      AppLogger.info('Firebase 初始化完成');
    } catch (e, stackTrace) {
      AppLogger.error('Firebase 初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 配置Firestore设置
  static void _configureFirestore() {
    try {
      final firestore = FirebaseFirestore.instance;

      // 启用离线持久化
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      AppLogger.info('Firestore 配置完成');
    } catch (e, stackTrace) {
      AppLogger.error('Firestore 配置失败', e, stackTrace);
      // 不抛出异常，因为这不是致命错误
    }
  }

  /// 检查Firebase是否已初始化
  static bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
