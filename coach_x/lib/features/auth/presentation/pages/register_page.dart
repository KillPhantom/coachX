import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_button.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
            title: Text(l10n.registerFailed),
            content: Text(next.errorMessage ?? l10n.errorOccurred),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm, style: AppTextStyles.body),
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
        child: DismissKeyboard(
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
                    l10n.createAccount,
                    style: AppTextStyles.title1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    l10n.startYourJourney,
                    style: AppTextStyles.subhead.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // 姓名输入
                  CustomTextField(
                    controller: _nameController,
                    placeholder: l10n.namePlaceholder,
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
                        return l10n.nameRequired;
                      }
                      return null;
                    },
                    enabled: registerState.status != RegisterStatus.loading,
                  ),

                  const SizedBox(height: AppDimensions.spacingL),

                  // 邮箱输入
                  CustomTextField(
                    controller: _emailController,
                    placeholder: l10n.emailPlaceholder,
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
                    placeholder: l10n.passwordMinLength,
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
                    placeholder: l10n.confirmPasswordPlaceholder,
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
                        return l10n.confirmPasswordRequired;
                      }
                      if (value != _passwordController.text) {
                        return l10n.passwordMismatch;
                      }
                      return null;
                    },
                    enabled: registerState.status != RegisterStatus.loading,
                    onEditingComplete: _handleRegister,
                  ),

                  const SizedBox(height: AppDimensions.spacingXL),

                  // 用户协议提示
                  Text(
                    l10n.termsAgreement,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppDimensions.spacingL),

                  // 注册按钮
                  CustomButton(
                    text: l10n.register,
                    onPressed: _handleRegister,
                    isLoading: registerState.status == RegisterStatus.loading,
                    fullWidth: true,
                  ),

                  const SizedBox(height: AppDimensions.spacingL),

                  // 登录提示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.hasAccount, style: AppTextStyles.body),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed:
                            registerState.status == RegisterStatus.loading
                            ? null
                            : () => context.pop(),
                        child: Text(
                          l10n.loginNow,
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
      ),
    );
  }
}
