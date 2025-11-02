import '../models/invitation_code_model.dart';

/// 邀请码Repository接口
abstract class InvitationCodeRepository {
  /// 获取邀请码列表
  Future<List<InvitationCodeModel>> fetchInvitationCodes();

  /// 生成邀请码
  Future<void> generateInvitationCode({
    required int totalDays,
    String note = '',
  });
}

