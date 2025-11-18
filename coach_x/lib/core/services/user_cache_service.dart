import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 用户缓存服务
///
/// 负责管理用户信息的本地缓存，包括角色、ID等
/// 使用SharedPreferences实现持久化存储
class UserCacheService {
  UserCacheService._();

  static SharedPreferences? _prefs;

  // 缓存键名
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyCacheTimestamp = 'cache_timestamp';

  // 缓存有效期：7天（毫秒）
  static const int _cacheValidityDays = 7;
  static const int _cacheValidityMillis =
      _cacheValidityDays * 24 * 60 * 60 * 1000;

  /// 初始化服务
  ///
  /// 必须在使用服务前调用，通常在main()中调用
  static Future<void> initialize() async {
    try {
      AppLogger.info('初始化 UserCacheService...');
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('UserCacheService 初始化成功');
    } catch (e, stackTrace) {
      AppLogger.error('UserCacheService 初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 检查缓存是否有效
  ///
  /// 有效条件：
  /// 1. 缓存的用户ID与当前登录用户ID一致
  /// 2. 缓存时间在7天有效期内
  ///
  /// 返回true表示缓存有效，可以直接使用
  static bool isValid() {
    if (_prefs == null) {
      AppLogger.warning('UserCacheService 未初始化');
      return false;
    }

    try {
      // 检查当前用户
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.info('缓存无效：用户未登录');
        return false;
      }

      // 检查缓存的用户ID
      final cachedUserId = _prefs!.getString(_keyUserId);
      if (cachedUserId == null || cachedUserId != currentUser.uid) {
        AppLogger.info('缓存无效：用户ID不匹配');
        return false;
      }

      // 检查缓存时间戳
      final cacheTimestamp = _prefs!.getInt(_keyCacheTimestamp);
      if (cacheTimestamp == null) {
        AppLogger.info('缓存无效：时间戳不存在');
        return false;
      }

      // 计算缓存年龄
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - cacheTimestamp;

      if (cacheAge > _cacheValidityMillis) {
        AppLogger.info('缓存无效：已过期（${cacheAge ~/ (24 * 60 * 60 * 1000)}天）');
        return false;
      }

      AppLogger.info('缓存有效');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('检查缓存有效性失败', e, stackTrace);
      return false;
    }
  }

  /// 获取缓存的用户角色
  ///
  /// 返回 "coach" 或 "student"，如果不存在返回null
  static String? getCachedRole() {
    if (_prefs == null) {
      AppLogger.warning('UserCacheService 未初始化');
      return null;
    }

    return _prefs!.getString(_keyUserRole);
  }

  /// 获取缓存的用户ID
  ///
  /// 返回用户ID，如果不存在返回null
  static String? getCachedUserId() {
    if (_prefs == null) {
      AppLogger.warning('UserCacheService 未初始化');
      return null;
    }

    return _prefs!.getString(_keyUserId);
  }

  /// 保存用户缓存
  ///
  /// [userId] 用户ID
  /// [role] 用户角色 (coach/student)
  static Future<void> saveUserCache({
    required String userId,
    required String role,
  }) async {
    if (_prefs == null) {
      throw Exception('UserCacheService 未初始化');
    }

    try {
      AppLogger.info('保存用户缓存: userId=$userId, role=$role');

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _prefs!.setString(_keyUserId, userId);
      await _prefs!.setString(_keyUserRole, role);
      await _prefs!.setInt(_keyCacheTimestamp, timestamp);

      AppLogger.info('用户缓存保存成功');
    } catch (e, stackTrace) {
      AppLogger.error('保存用户缓存失败', e, stackTrace);
      rethrow;
    }
  }

  /// 清除所有缓存
  ///
  /// 通常在用户登出时调用
  static Future<void> clearCache() async {
    if (_prefs == null) {
      AppLogger.warning('UserCacheService 未初始化');
      return;
    }

    try {
      AppLogger.info('清除用户缓存');

      await _prefs!.remove(_keyUserId);
      await _prefs!.remove(_keyUserRole);
      await _prefs!.remove(_keyCacheTimestamp);

      AppLogger.info('用户缓存清除成功');
    } catch (e, stackTrace) {
      AppLogger.error('清除用户缓存失败', e, stackTrace);
      rethrow;
    }
  }

  /// 判断是否需要显示Splash页面
  ///
  /// 需要显示Splash的情况：
  /// 1. 缓存无效或不存在
  /// 2. 用户已登录
  ///
  /// 返回true表示需要显示Splash
  static bool needsSplash() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cacheValid = isValid();

    // 已登录且缓存无效 → 需要Splash
    return currentUser != null && !cacheValid;
  }
}
