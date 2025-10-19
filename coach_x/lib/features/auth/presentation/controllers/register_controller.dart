import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 注册状态
enum RegisterStatus {
  initial,
  loading,
  success,
  error,
}

/// 注册状态类
class RegisterState {
  final RegisterStatus status;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// 注册控制器
class RegisterController extends StateNotifier<RegisterState> {
  RegisterController() : super(const RegisterState());

  /// 邮箱密码注册
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(status: RegisterStatus.loading);

      final credential = await AuthService.signUpWithEmail(
        email: email,
        password: password,
      );

      // 如果提供了显示名称，更新用户资料
      if (displayName != null && displayName.isNotEmpty) {
        await AuthService.updateProfile(displayName: displayName);
      }

      AppLogger.info('注册成功: ${credential.user?.uid}');
      state = state.copyWith(status: RegisterStatus.success);
    } catch (e) {
      AppLogger.error('注册失败', e);
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const RegisterState();
  }
}

/// 注册控制器Provider
final registerControllerProvider =
    StateNotifierProvider<RegisterController, RegisterState>((ref) {
  return RegisterController();
});

