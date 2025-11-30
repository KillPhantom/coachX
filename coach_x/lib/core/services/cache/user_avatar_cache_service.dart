import 'package:hive_flutter/hive_flutter.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/firestore_service.dart';
import 'cache_helper.dart';
import 'cache_metadata.dart';

/// 用户头像缓存服务
///
/// 缓存用户的 avatarUrl，减少 Firestore 调用次数
/// 有效期：1天
class UserAvatarCacheService {
  UserAvatarCacheService._();

  static const String _boxName = 'user_avatars_cache';
  static const Duration _validity = Duration(days: 1);

  /// 获取 Box 实例
  static Future<Box<dynamic>> _getBox() async {
    return await CacheHelper.openBox<dynamic>(_boxName);
  }

  /// 获取用户头像 URL（带缓存）
  ///
  /// [userId] 用户 ID
  /// 返回 avatarUrl（可能为 null）
  ///
  /// 流程：
  /// 1. 检查缓存是否存在且有效
  /// 2. 命中 → 返回缓存的 avatarUrl
  /// 3. 未命中 → 从 Firestore 获取并缓存
  static Future<String?> getAvatarUrl(String userId) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(userId);
      final metadataKey = _getMetadataKey(userId);

      // 检查缓存是否有效
      final metadata = box.get(metadataKey) as CacheMetadata?;
      if (CacheHelper.isMetadataValid(metadata)) {
        final cachedUrl = box.get(cacheKey) as String?;
        AppLogger.info('✅ 头像缓存命中: $userId');
        return cachedUrl;
      }

      // 缓存无效，从 Firestore 获取
      AppLogger.info('❌ 头像缓存未命中，从 Firestore 获取: $userId');
      final avatarUrl = await _fetchAvatarFromFirestore(userId);

      // 写入缓存
      await cacheAvatarUrl(userId, avatarUrl);

      return avatarUrl;
    } catch (e, stackTrace) {
      AppLogger.error('获取头像 URL 失败: $userId', e, stackTrace);
      return null;
    }
  }

  /// 缓存用户头像 URL
  ///
  /// [userId] 用户 ID
  /// [avatarUrl] 头像 URL（可以为 null）
  static Future<void> cacheAvatarUrl(String userId, String? avatarUrl) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(userId);
      final metadataKey = _getMetadataKey(userId);

      // 写入缓存数据
      await box.put(cacheKey, avatarUrl);

      // 写入元数据
      final metadata = CacheHelper.createMetadata(cacheKey, _validity);
      await box.put(metadataKey, metadata);

      AppLogger.info('💾 头像已缓存: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('缓存头像 URL 失败: $userId', e, stackTrace);
    }
  }

  /// 失效单个用户头像缓存
  ///
  /// [userId] 用户 ID
  static Future<void> invalidateAvatar(String userId) async {
    try {
      final box = await _getBox();
      final cacheKey = _getCacheKey(userId);
      final metadataKey = _getMetadataKey(userId);

      await box.delete(cacheKey);
      await box.delete(metadataKey);

      AppLogger.info('🗑️ 头像缓存已失效: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('失效头像缓存失败: $userId', e, stackTrace);
    }
  }

  /// 失效所有头像缓存
  ///
  /// 通常在用户登出时调用
  static Future<void> invalidateAllAvatars() async {
    try {
      await CacheHelper.deleteBox(_boxName);
      AppLogger.info('🗑️ 所有头像缓存已清除');
    } catch (e, stackTrace) {
      AppLogger.error('清除所有头像缓存失败', e, stackTrace);
    }
  }

  /// 强制刷新用户头像
  ///
  /// [userId] 用户 ID
  /// 返回最新的 avatarUrl
  ///
  /// 忽略缓存，直接从 Firestore 获取并更新缓存
  static Future<String?> forceRefreshAvatar(String userId) async {
    try {
      AppLogger.info('🔄 强制刷新头像: $userId');

      // 从 Firestore 获取最新数据
      final avatarUrl = await _fetchAvatarFromFirestore(userId);

      // 更新缓存
      await cacheAvatarUrl(userId, avatarUrl);

      return avatarUrl;
    } catch (e, stackTrace) {
      AppLogger.error('强制刷新头像失败: $userId', e, stackTrace);
      return null;
    }
  }

  /// 从 Firestore 获取用户头像 URL
  static Future<String?> _fetchAvatarFromFirestore(String userId) async {
    try {
      final doc = await FirestoreService.getDocument('users', userId);

      if (!doc.exists) {
        AppLogger.warning('用户不存在: $userId');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      return data?['avatarUrl'] as String?;
    } catch (e, stackTrace) {
      AppLogger.error('从 Firestore 获取头像失败: $userId', e, stackTrace);
      rethrow;
    }
  }

  /// 生成缓存键
  static String _getCacheKey(String userId) => 'avatar_$userId';

  /// 生成元数据键
  static String _getMetadataKey(String userId) => 'avatar_${userId}_metadata';
}
