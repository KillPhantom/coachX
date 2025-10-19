import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 登录状态
enum LoginStatus {
  initial,
  loading,
  success,
  error,
}

/// 登录状态类
class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// 登录控制器
class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(const LoginState());

  /// 邮箱密码登录
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: LoginStatus.loading);

      await AuthService.signInWithEmail(
        email: email,
        password: password,
      );

      state = state.copyWith(status: LoginStatus.success);
    } catch (e) {
      AppLogger.error('登录失败', e);
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const LoginState();
  }
}

/// 登录控制器Provider
final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController();
});

