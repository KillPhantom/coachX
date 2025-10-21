import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_button.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/features/auth/presentation/controllers/register_controller.dart';
import 'package:coach_x/routes/route_names.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(registerControllerProvider.notifier)
          .signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);

    // 监听注册状态
    ref.listen<RegisterState>(registerControllerProvider, (previous, next) {
      if (next.status == RegisterStatus.success) {
        // 注册成功，导航到Profile Setup页面
        context.go(RouteNames.profileSetup);
      } else if (next.status == RegisterStatus.error) {
        // 显示错误提示
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('注册失败'),
            content: Text(next.errorMessage ?? '未知错误'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 返回按钮
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: registerState.status == RegisterStatus.loading
                        ? null
                        : () => context.pop(),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: AppColors.primaryColor,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 标题
                Text(
                  '创建您的账号',
                  style: AppTextStyles.title1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '开始您的健身之旅',
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 姓名输入
                CustomTextField(
                  controller: _nameController,
                  placeholder: '姓名',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      CupertinoIcons.person,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入姓名';
                    }
                    return null;
                  },
                  enabled: registerState.status != RegisterStatus.loading,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 邮箱输入
                CustomTextField(
                  controller: _emailController,
                  placeholder: '邮箱地址',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      CupertinoIcons.mail,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  validator: ValidationUtils.validateEmail,
                  enabled: registerState.status != RegisterStatus.loading,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 密码输入
                CustomTextField(
                  controller: _passwordController,
                  placeholder: '密码（至少6位）',
                  isPassword: true,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      CupertinoIcons.lock,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  validator: ValidationUtils.validatePassword,
                  enabled: registerState.status != RegisterStatus.loading,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 确认密码输入
                CustomTextField(
                  controller: _confirmPasswordController,
                  placeholder: '确认密码',
                  isPassword: true,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      CupertinoIcons.lock,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请确认密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                  enabled: registerState.status != RegisterStatus.loading,
                  onEditingComplete: _handleRegister,
                ),

                const SizedBox(height: AppDimensions.spacingXL),

                // 用户协议提示
                Text(
                  '注册即表示您同意我们的服务条款和隐私政策',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 注册按钮
                CustomButton(
                  text: '注册',
                  onPressed: _handleRegister,
                  isLoading: registerState.status == RegisterStatus.loading,
                  fullWidth: true,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 登录提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('已有账号？', style: AppTextStyles.body),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: registerState.status == RegisterStatus.loading
                          ? null
                          : () => context.pop(),
                      child: Text(
                        '立即登录',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
