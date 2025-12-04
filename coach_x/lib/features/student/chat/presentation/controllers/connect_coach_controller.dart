import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/app/providers.dart';

/// Connect Coach状态
enum ConnectCoachStatus { initial, loading, success, error }

/// Connect Coach状态类
class ConnectCoachState {
  final ConnectCoachStatus status;
  final String? errorMessage;
  final String? coachId;
  final String? codeId;

  const ConnectCoachState({
    this.status = ConnectCoachStatus.initial,
    this.errorMessage,
    this.coachId,
    this.codeId,
  });

  ConnectCoachState copyWith({
    ConnectCoachStatus? status,
    String? errorMessage,
    String? coachId,
    String? codeId,
  }) {
    return ConnectCoachState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      coachId: coachId ?? this.coachId,
      codeId: codeId ?? this.codeId,
    );
  }
}

/// Connect Coach控制器
class ConnectCoachController extends StateNotifier<ConnectCoachState> {
  ConnectCoachController(this.ref) : super(const ConnectCoachState());

  final Ref ref;

  /// 连接教练
  Future<void> connectCoach(String code) async {
    try {
      state = state.copyWith(status: ConnectCoachStatus.loading);

      // 1. 验证邀请码
      final verifyResult = await CloudFunctionsService.verifyInvitationCode(code);

      if (verifyResult['valid'] != true) {
        // 邀请码无效
        final message = verifyResult['message'] as String? ?? '邀请码无效';
        state = state.copyWith(
          status: ConnectCoachStatus.error,
          errorMessage: message,
        );
        AppLogger.warning('邀请码验证失败: $message');
        return;
      }

      // 提取数据
      final coachId = verifyResult['coachId'] as String?;
      final codeId = verifyResult['codeId'] as String?;

      if (coachId == null || codeId == null) {
        state = state.copyWith(
          status: ConnectCoachStatus.error,
          errorMessage: '邀请码数据异常',
        );
        AppLogger.error('邀请码验证返回数据异常: coachId=$coachId, codeId=$codeId');
        return;
      }

      AppLogger.info('邀请码验证成功: coachId=$coachId, codeId=$codeId');

      // 2. 更新用户信息（设置 coachId）
      await CloudFunctionsService.updateUserInfo(coachId: coachId);
      AppLogger.info('用户信息更新成功: coachId=$coachId');

      // 3. 标记邀请码已使用
      await CloudFunctionsService.call('mark_invitation_code_used', {
        'codeId': codeId,
      });
      AppLogger.info('邀请码已标记为使用: codeId=$codeId');

      // 4. 刷新当前用户数据
      ref.invalidate(currentUserProvider);
      AppLogger.info('用户数据已刷新');

      // 5. 设置成功状态
      state = state.copyWith(
        status: ConnectCoachStatus.success,
        coachId: coachId,
        codeId: codeId,
      );

      AppLogger.info('成功连接到教练: coachId=$coachId');
    } catch (e, stackTrace) {
      AppLogger.error('连接教练失败', e, stackTrace);
      state = state.copyWith(
        status: ConnectCoachStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const ConnectCoachState();
  }
}

/// Connect Coach控制器Provider
final connectCoachControllerProvider =
    StateNotifierProvider.autoDispose<ConnectCoachController, ConnectCoachState>(
  (ref) => ConnectCoachController(ref),
);
