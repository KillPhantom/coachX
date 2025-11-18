import 'package:hive_flutter/hive_flutter.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'cache_metadata.dart';

/// 通用缓存辅助工具
///
/// 提供 Hive 缓存的通用操作方法
class CacheHelper {
  CacheHelper._();

  /// 初始化 Hive
  ///
  /// 在应用启动时调用，初始化 Hive 存储
  static Future<void> initializeHive() async {
    try {
      AppLogger.info('初始化 Hive...');
      await Hive.initFlutter();
      AppLogger.info('✅ Hive 初始化成功');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Hive 初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 打开 Box
  ///
  /// [boxName] Box 名称
  /// 返回打开的 Box 实例
  static Future<Box<T>> openBox<T>(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      }

      AppLogger.info('打开 Box: $boxName');
      final box = await Hive.openBox<T>(boxName);
      AppLogger.info('✅ Box 已打开: $boxName');
      return box;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 打开 Box 失败: $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// 清除过期缓存
  ///
  /// [box] Box 实例
  /// [validity] 有效期（超过此时间的缓存将被清除）
  static Future<void> clearExpiredCache(Box box, Duration validity) async {
    try {
      final now = DateTime.now();
      final keysToDelete = <dynamic>[];

      for (final key in box.keys) {
        if (key.toString().endsWith('_metadata')) {
          final metadata = box.get(key) as CacheMetadata?;
          if (metadata != null && now.isAfter(metadata.expiresAt)) {
            // 过期了，标记删除
            keysToDelete.add(key);
            keysToDelete.add(metadata.key); // 同时删除对应的数据
          }
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        AppLogger.info('🗑️ 清除过期缓存: ${keysToDelete.length ~/ 2} 条');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除过期缓存失败', e, stackTrace);
    }
  }

  /// 创建缓存元数据
  ///
  /// [key] 缓存键
  /// [validity] 有效期
  /// 返回新创建的元数据实例
  static CacheMetadata createMetadata(String key, Duration validity) {
    return CacheMetadata.create(key, validity);
  }

  /// 检查元数据有效性
  ///
  /// [metadata] 缓存元数据
  /// 返回 true 表示缓存有效，false 表示缓存无效或不存在
  static bool isMetadataValid(CacheMetadata? metadata) {
    if (metadata == null) {
      return false;
    }
    return metadata.isValid();
  }

  /// 关闭 Box
  ///
  /// [boxName] Box 名称
  static Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        AppLogger.info('📦 Box 已关闭: $boxName');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 关闭 Box 失败: $boxName', e, stackTrace);
    }
  }

  /// 删除 Box
  ///
  /// [boxName] Box 名称
  /// 彻底删除 Box 及其所有数据
  static Future<void> deleteBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      AppLogger.info('🗑️ Box 已删除: $boxName');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 删除 Box 失败: $boxName', e, stackTrace);
    }
  }

  /// 清除所有缓存
  ///
  /// 删除所有 Hive Box（通常在用户登出时调用）
  static Future<void> clearAllCache() async {
    try {
      AppLogger.info('清除所有缓存...');
      await Hive.deleteFromDisk();
      AppLogger.info('✅ 所有缓存已清除');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除所有缓存失败', e, stackTrace);
    }
  }
}
