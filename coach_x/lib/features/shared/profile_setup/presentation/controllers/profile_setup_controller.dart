import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/core/enums/gender.dart';
import 'package:coach_x/core/utils/logger.dart';

/// Profile Setup状态
enum ProfileSetupStatus { initial, loading, success, error }

/// Profile Setup状态类
class ProfileSetupState {
  final ProfileSetupStatus status;
  final String? errorMessage;
  final UserRole? selectedRole;
  final Gender? selectedGender;
  final DateTime? selectedBornDate;
  final String? avatarUrl;
  final String? invitationCode;
  final String? coachId;
  final bool isValidatingCode;

  const ProfileSetupState({
    this.status = ProfileSetupStatus.initial,
    this.errorMessage,
    this.selectedRole,
    this.selectedGender,
    this.selectedBornDate,
    this.avatarUrl,
    this.invitationCode,
    this.coachId,
    this.isValidatingCode = false,
  });

  ProfileSetupState copyWith({
    ProfileSetupStatus? status,
    String? errorMessage,
    UserRole? selectedRole,
    Gender? selectedGender,
    DateTime? selectedBornDate,
    String? avatarUrl,
    String? invitationCode,
    String? coachId,
    bool? isValidatingCode,
  }) {
    return ProfileSetupState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedRole: selectedRole ?? this.selectedRole,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedBornDate: selectedBornDate ?? this.selectedBornDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      invitationCode: invitationCode ?? this.invitationCode,
      coachId: coachId ?? this.coachId,
      isValidatingCode: isValidatingCode ?? this.isValidatingCode,
    );
  }
}

/// Profile Setup控制器
class ProfileSetupController extends StateNotifier<ProfileSetupState> {
  ProfileSetupController() : super(const ProfileSetupState());

  /// 设置角色
  void setRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  /// 设置性别
  void setGender(Gender gender) {
    state = state.copyWith(selectedGender: gender);
  }

  /// 设置出生日期
  void setBornDate(DateTime date) {
    state = state.copyWith(selectedBornDate: date);
  }

  /// 设置邀请码
  void setInvitationCode(String code) {
    state = state.copyWith(invitationCode: code);
  }

  /// 上传头像
  ///
  /// 注意：此方法需要在实际使用时实现图片选择逻辑
  /// 当前仅为占位实现
  Future<void> uploadAvatar() async {
    try {
      state = state.copyWith(status: ProfileSetupStatus.loading);

      // TODO: 实现图片选择和上传逻辑
      // 需要使用image_picker package选择图片
      // 然后调用StorageService.uploadAvatar(source: ImageSource.gallery)

      state = state.copyWith(status: ProfileSetupStatus.initial);

      AppLogger.info('头像上传功能待实现');
    } catch (e) {
      AppLogger.error('头像上传失败', e);
      state = state.copyWith(
        status: ProfileSetupStatus.error,
        errorMessage: '头像上传失败: ${e.toString()}',
      );
    }
  }

  /// 验证邀请码
  ///
  /// [code] 邀请码
  /// [confirm] 是否确认使用 (默认false)
  Future<void> verifyInvitationCode(String code, {bool confirm = false}) async {
    try {
      state = state.copyWith(isValidatingCode: true);

      final result = await CloudFunctionsService.verifyInvitationCode(
        code,
        confirm: confirm,
      );

      if (result['valid'] == true) {
        state = state.copyWith(
          isValidatingCode: false,
          coachId: result['coachId'] as String?,
        );
        AppLogger.info('邀请码验证成功 (confirm=$confirm)');
      } else {
        state = state.copyWith(
          isValidatingCode: false,
          errorMessage: result['message'] as String? ?? '邀请码无效',
        );
      }
    } catch (e) {
      AppLogger.error('邀请码验证失败', e);
      state = state.copyWith(
        isValidatingCode: false,
        errorMessage: '邀请码验证失败: ${e.toString()}',
      );
    }
  }

  /// 提交Profile Setup
  Future<void> submit({
    required String name,
    required UserRole role,
    required Gender gender,
    required DateTime bornDate,
    double? height,
    double? initialWeight,
    String? invitationCode,
  }) async {
    try {
      state = state.copyWith(status: ProfileSetupStatus.loading);

      // 如果是学生且有邀请码，先验证并使用邀请码
      String? coachId;
      if (role == UserRole.student &&
          invitationCode != null &&
          invitationCode.isNotEmpty) {
        // 使用 confirm: true 直接兑换邀请码
        await verifyInvitationCode(invitationCode, confirm: true);
        if (state.errorMessage != null) {
          // 验证失败
          state = state.copyWith(status: ProfileSetupStatus.error);
          return;
        }
        coachId = state.coachId;
      }

      // 准备更新数据
      final updateData = <String, dynamic>{
        'name': name,
        'role': role.value,
        'gender': gender.value,
        'bornDate': _formatDate(bornDate),
      };

      if (state.avatarUrl != null) {
        updateData['avatarUrl'] = state.avatarUrl;
      }

      if (height != null) {
        updateData['height'] = height;
      }

      if (initialWeight != null) {
        updateData['initialWeight'] = initialWeight;
      }

      if (coachId != null) {
        updateData['coachId'] = coachId;
      }

      // 调用Cloud Function更新用户信息
      await CloudFunctionsService.updateUserInfo(
        name: name,
        avatarUrl: state.avatarUrl,
        role: role.value,
        gender: gender.value,
        bornDate: _formatDate(bornDate),
        height: height,
        initialWeight: initialWeight,
        coachId: coachId,
      );

      AppLogger.info('Profile Setup完成');
      state = state.copyWith(status: ProfileSetupStatus.success);
    } catch (e) {
      AppLogger.error('Profile Setup失败', e);
      state = state.copyWith(
        status: ProfileSetupStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 格式化日期为字符串 "yyyy-MM-dd"
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 重置状态
  void reset() {
    state = const ProfileSetupState();
  }
}

/// Profile Setup控制器Provider
final profileSetupControllerProvider =
    StateNotifierProvider<ProfileSetupController, ProfileSetupState>((ref) {
      return ProfileSetupController();
    });
