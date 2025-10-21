import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_button.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/core/enums/gender.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/features/shared/profile_setup/presentation/controllers/profile_setup_controller.dart';
import 'package:coach_x/routes/route_names.dart';

/// Profile Setup页面
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 预填充邮箱和姓名
    final user = AuthService.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final controller = ref.read(profileSetupControllerProvider.notifier);
      final state = ref.read(profileSetupControllerProvider);

      if (state.selectedRole == null) {
        _showError('请选择角色');
        return;
      }

      if (state.selectedGender == null) {
        _showError('请选择性别');
        return;
      }

      if (state.selectedBornDate == null) {
        _showError('请选择出生日期');
        return;
      }

      controller.submit(
        name: _nameController.text.trim(),
        role: state.selectedRole!,
        gender: state.selectedGender!,
        bornDate: state.selectedBornDate!,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
        initialWeight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        invitationCode: _invitationCodeController.text.trim(),
      );
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(profileSetupControllerProvider);
    final user = AuthService.currentUser;

    // 监听状态变化
    ref.listen<ProfileSetupState>(profileSetupControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == ProfileSetupStatus.success) {
        // 根据角色跳转到对应首页
        final route = next.selectedRole == UserRole.coach
            ? RouteNames.coachHome
            : RouteNames.studentHome;
        context.go(route);
      } else if (next.status == ProfileSetupStatus.error) {
        _showError(next.errorMessage ?? '设置失败');
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
        border: null,
        middle: Text('完善资料'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // 标题
                Text(
                  '完善您的个人资料',
                  style: AppTextStyles.title1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '请填写必要信息以完成注册',
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 邮箱（只读）
                _buildReadOnlyField('邮箱', user?.email ?? ''),
                const SizedBox(height: AppDimensions.spacingL),

                // 姓名
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '姓名 *',
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    CustomTextField(
                      controller: _nameController,
                      placeholder: '请输入姓名',
                      validator: ValidationUtils.validateName,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingL),

                // 角色选择
                _buildRoleSelector(),
                const SizedBox(height: AppDimensions.spacingL),

                // 性别选择
                _buildGenderSelector(),
                const SizedBox(height: AppDimensions.spacingL),

                // 出生日期
                _buildBornDatePicker(),
                const SizedBox(height: AppDimensions.spacingL),

                // 身高（可选）
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '身高 (cm)',
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    CustomTextField(
                      controller: _heightController,
                      placeholder: '请输入身高（可选）',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingL),

                // 体重（可选）
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '体重 (kg)',
                      style: AppTextStyles.callout.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    CustomTextField(
                      controller: _weightController,
                      placeholder: '请输入体重（可选）',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingL),

                // 教练邀请码（仅学生显示）
                if (setupState.selectedRole == UserRole.student) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '教练邀请码',
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      CustomTextField(
                        controller: _invitationCodeController,
                        placeholder: '请输入教练邀请码（可选）',
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            return ValidationUtils.validateInvitationCode(
                              value,
                            );
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                ],

                // 提交按钮
                CustomButton(
                  text: '完成',
                  onPressed: setupState.status == ProfileSetupStatus.loading
                      ? () {}
                      : _handleSubmit,
                  isLoading: setupState.status == ProfileSetupStatus.loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Text(value, style: AppTextStyles.body),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final controller = ref.read(profileSetupControllerProvider.notifier);
    final selectedRole = ref.watch(profileSetupControllerProvider).selectedRole;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '角色 *',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                UserRole.student,
                selectedRole == UserRole.student,
                () => controller.setRole(UserRole.student),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildRoleOption(
                UserRole.coach,
                selectedRole == UserRole.coach,
                () => controller.setRole(UserRole.coach),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : AppColors.backgroundWhite,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Center(
          child: Text(
            role.displayName,
            style: AppTextStyles.body.copyWith(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final controller = ref.read(profileSetupControllerProvider.notifier);
    final selectedGender = ref
        .watch(profileSetupControllerProvider)
        .selectedGender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性别 *',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                Gender.male,
                selectedGender == Gender.male,
                () => controller.setGender(Gender.male),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildGenderOption(
                Gender.female,
                selectedGender == Gender.female,
                () => controller.setGender(Gender.female),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    Gender gender,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : AppColors.backgroundWhite,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Center(
          child: Text(
            gender.displayName,
            style: AppTextStyles.body.copyWith(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBornDatePicker() {
    final controller = ref.read(profileSetupControllerProvider.notifier);
    final selectedDate = ref
        .watch(profileSetupControllerProvider)
        .selectedBornDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '出生日期 *',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        GestureDetector(
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => Container(
                height: 250,
                color: AppColors.backgroundWhite,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: const Text('取消'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CupertinoButton(
                          child: const Text('确定'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: selectedDate ?? DateTime(2000, 1, 1),
                        maximumDate: DateTime.now(),
                        minimumDate: DateTime(1900, 1, 1),
                        onDateTimeChanged: (date) =>
                            controller.setBornDate(date),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Text(
              selectedDate != null
                  ? '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
                  : '请选择出生日期',
              style: AppTextStyles.body.copyWith(
                color: selectedDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
