import 'package:cloud_functions/cloud_functions.dart';
import 'package:coach_x/core/utils/logger.dart';

/// Cloud Functions服务
///
/// 封装对Firebase Cloud Functions的调用
class CloudFunctionsService {
  CloudFunctionsService._();

  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 调用Cloud Function
  ///
  /// [functionName] 函数名称
  /// [parameters] 参数
  /// 返回函数执行结果
  static Future<Map<String, dynamic>> call(
    String functionName, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      AppLogger.info('调用Cloud Function: $functionName');

      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(parameters);

      AppLogger.info('Cloud Function调用成功: $functionName');
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('Cloud Function调用失败: $functionName', e);
      throw _handleFunctionsException(e);
    } catch (e, stackTrace) {
      AppLogger.error('Cloud Function调用失败: $functionName', e, stackTrace);
      rethrow;
    }
  }

  // ==================== 用户管理 ====================

  /// 获取用户信息
  ///
  /// [userId] 用户ID（可选，默认当前用户）
  static Future<Map<String, dynamic>> fetchUserInfo([String? userId]) async {
    final params = userId != null ? {'user_id': userId} : null;
    return await call('fetch_user_info', params);
  }

  /// 更新用户信息
  ///
  /// [name] 用户名
  /// [avatarUrl] 头像URL
  /// [role] 角色
  /// [gender] 性别
  /// [bornDate] 出生日期（格式: "yyyy-MM-dd"）
  /// [height] 身高（cm）
  /// [initialWeight] 体重（kg）
  /// [coachId] 教练ID
  static Future<Map<String, dynamic>> updateUserInfo({
    String? name,
    String? avatarUrl,
    String? role,
    String? gender,
    String? bornDate,
    double? height,
    double? initialWeight,
    String? coachId,
  }) async {
    final params = <String, dynamic>{};
    if (name != null) params['name'] = name;
    if (avatarUrl != null) params['avatarUrl'] = avatarUrl;
    if (role != null) params['role'] = role;
    if (gender != null) params['gender'] = gender;
    if (bornDate != null) params['bornDate'] = bornDate;
    if (height != null) params['height'] = height;
    if (initialWeight != null) params['initialWeight'] = initialWeight;
    if (coachId != null) params['coachId'] = coachId;

    return await call('update_user_info', params);
  }

  // ==================== 邀请码管理 ====================

  /// 验证邀请码
  ///
  /// [code] 邀请码
  /// 返回验证结果
  static Future<Map<String, dynamic>> verifyInvitationCode(String code) async {
    return await call('verify_invitation_code', {'code': code});
  }

  /// 生成邀请码（教练专用）
  ///
  /// [count] 生成数量
  /// 返回生成的邀请码列表
  static Future<Map<String, dynamic>> generateInvitationCodes({
    int count = 1,
  }) async {
    return await call('generate_invitation_codes', {'count': count});
  }

  // ==================== 异常处理 ====================

  /// 处理Firebase Functions异常
  static Exception _handleFunctionsException(FirebaseFunctionsException e) {
    String message;

    switch (e.code) {
      case 'unauthenticated':
        message = '用户未登录';
        break;
      case 'permission-denied':
        message = '权限不足';
        break;
      case 'not-found':
        message = '资源不存在';
        break;
      case 'invalid-argument':
        message = '参数无效';
        break;
      case 'deadline-exceeded':
        message = '请求超时';
        break;
      case 'unavailable':
        message = '服务暂时不可用';
        break;
      case 'internal':
        message = '服务器内部错误';
        break;
      default:
        message = e.message ?? '未知错误';
    }

    return Exception(message);
  }
}
