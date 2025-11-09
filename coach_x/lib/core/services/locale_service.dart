import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 语言设置服务
///
/// 负责更新用户的语言偏好到 Firestore
class LocaleService {
  LocaleService._();

  /// 更新用户语言偏好
  ///
  /// [languageCode] 语言代码: 'en' | 'zh'
  ///
  /// 调用后端 updateUserInfo Cloud Function 更新 Firestore
  static Future<void> updateUserLanguage(String languageCode) async {
    try {
      AppLogger.info('更新用户语言偏好: $languageCode');

      await CloudFunctionsService.call('update_user_info', {
        'languageCode': languageCode,
      });

      AppLogger.info('语言偏好更新成功');
    } catch (e, stackTrace) {
      AppLogger.error('更新语言偏好失败', e, stackTrace);
      rethrow;
    }
  }
}
