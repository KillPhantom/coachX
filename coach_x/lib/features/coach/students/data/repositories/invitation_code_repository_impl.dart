import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/invitation_code_model.dart';
import 'invitation_code_repository.dart';

/// 邀请码Repository实现
class InvitationCodeRepositoryImpl implements InvitationCodeRepository {
  @override
  Future<List<InvitationCodeModel>> fetchInvitationCodes() async {
    try {
      AppLogger.info('调用fetch_invitation_codes');

      final response = await CloudFunctionsService.call(
        'fetch_invitation_codes',
      );
      final data = response['data'] as Map<String, dynamic>;

      // 解析邀请码列表
      final codesList = data['codes'] as List<dynamic>;
      final codes = codesList
          .map(
            (json) =>
                InvitationCodeModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      AppLogger.info('fetch_invitation_codes成功: ${codes.length}个邀请码');

      return codes;
    } catch (e, stackTrace) {
      AppLogger.error('获取邀请码列表失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> generateInvitationCode({
    required int totalDays,
    String note = '',
  }) async {
    try {
      AppLogger.info('调用generate_invitation_codes: $totalDays天');

      await CloudFunctionsService.call('generate_invitation_codes', {
        'count': 1,
        'total_days': totalDays,
        if (note.isNotEmpty) 'note': note,
      });

      AppLogger.info('generate_invitation_codes成功');
    } catch (e, stackTrace) {
      AppLogger.error('生成邀请码失败', e, stackTrace);
      rethrow;
    }
  }
}
