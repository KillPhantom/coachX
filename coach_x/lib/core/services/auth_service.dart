import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/user_cache_service.dart';
import 'package:coach_x/core/services/cache/user_avatar_cache_service.dart';

/// Firebase Authentication服务
///
/// 封装Firebase Authentication的所有操作
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取当前用户
  static User? get currentUser => _auth.currentUser;

  /// 获取当前用户ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// 监听认证状态变化
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// 邮箱密码注册
  ///
  /// [email] 邮箱地址
  /// [password] 密码
  /// 返回 [UserCredential] 用户凭证
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('开始注册用户: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info('用户注册成功: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('注册失败', e);
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      AppLogger.error('注册失败', e);
      throw Exception(e.message ?? '注册失败');
    } catch (e, stackTrace) {
      AppLogger.error('注册失败', e, stackTrace);
      throw Exception('注册失败: ${e.toString()}');
    }
  }

  /// 邮箱密码登录
  ///
  /// [email] 邮箱地址
  /// [password] 密码
  /// 返回 [UserCredential] 用户凭证
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('开始登录: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.info('登录成功: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('登录失败', e);
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      AppLogger.error('登录失败', e);
      throw Exception(e.message ?? '登录失败');
    } catch (e, stackTrace) {
      AppLogger.error('登录失败', e, stackTrace);
      throw Exception('登录失败: ${e.toString()}');
    }
  }

  /// 退出登录
  static Future<void> signOut() async {
    try {
      AppLogger.info('用户退出登录: ${currentUser?.uid}');

      // 清除用户缓存
      await UserCacheService.clearCache();

      // 清除头像缓存
      await UserAvatarCacheService.invalidateAllAvatars();

      // 退出Firebase认证
      await _auth.signOut();

      AppLogger.info('退出登录成功');
    } catch (e, stackTrace) {
      AppLogger.error('退出登录失败', e, stackTrace);
      rethrow;
    }
  }

  /// 发送邮箱验证
  static Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      if (user.emailVerified) {
        AppLogger.info('邮箱已验证，无需重复发送');
        return;
      }

      await user.sendEmailVerification();
      AppLogger.info('邮箱验证邮件已发送');
    } catch (e, stackTrace) {
      AppLogger.error('发送邮箱验证失败', e, stackTrace);
      rethrow;
    }
  }

  /// 发送密码重置邮件
  ///
  /// [email] 邮箱地址
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      AppLogger.info('发送密码重置邮件: $email');
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('密码重置邮件已发送');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('发送密码重置邮件失败', e);
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      AppLogger.error('发送密码重置邮件失败', e);
      throw Exception(e.message ?? '发送密码重置邮件失败');
    } catch (e, stackTrace) {
      AppLogger.error('发送密码重置邮件失败', e, stackTrace);
      throw Exception('发送密码重置邮件失败: ${e.toString()}');
    }
  }

  /// 更新用户资料
  ///
  /// [displayName] 显示名称
  /// [photoURL] 头像URL
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      AppLogger.info('更新用户资料: $displayName');
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      AppLogger.info('用户资料更新成功');
    } catch (e, stackTrace) {
      AppLogger.error('更新用户资料失败', e, stackTrace);
      rethrow;
    }
  }

  /// 重新加载当前用户信息
  static Future<void> reloadUser() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      await user.reload();
    } catch (e, stackTrace) {
      AppLogger.error('重新加载用户信息失败', e, stackTrace);
      rethrow;
    }
  }

  /// 删除当前用户账号
  static Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('用户未登录');
      }

      AppLogger.warning('删除用户账号: ${user.uid}');
      await user.delete();
      AppLogger.info('用户账号已删除');
    } catch (e, stackTrace) {
      AppLogger.error('删除用户账号失败', e, stackTrace);
      rethrow;
    }
  }

  /// 处理Firebase Auth异常
  static Exception _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'email-already-in-use':
        message = '该邮箱已被注册';
        break;
      case 'invalid-email':
        message = '邮箱格式不正确';
        break;
      case 'operation-not-allowed':
        message = '操作不被允许';
        break;
      case 'weak-password':
        message = '密码强度太弱';
        break;
      case 'user-disabled':
        message = '该账号已被禁用';
        break;
      case 'user-not-found':
        message = '用户不存在';
        break;
      case 'wrong-password':
        message = '密码错误';
        break;
      case 'too-many-requests':
        message = '请求过于频繁，请稍后再试';
        break;
      case 'network-request-failed':
        message = '网络连接失败';
        break;
      default:
        message = '认证失败: ${e.message ?? e.code}';
    }

    return Exception(message);
  }
}
