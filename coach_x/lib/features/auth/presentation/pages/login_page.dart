import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_button.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/features/auth/presentation/controllers/login_controller.dart';
import 'package:coach_x/routes/route_names.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(loginControllerProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    // 监听登录状态
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.status == LoginStatus.success) {
        // 登录成功，导航到主页（临时跳转到学生首页）
        context.go(RouteNames.studentHome);
      } else if (next.status == LoginStatus.error) {
        // 显示错误提示
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('登录失败'),
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
                const SizedBox(height: 60),
                
                // Logo和标题
                Image.asset(
                  'assets/fonts/images/icon.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: AppDimensions.spacingL),
                Text(
                  'CoachX',
                  style: AppTextStyles.largeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'AI教练学生管理平台',
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
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
                  enabled: loginState.status != LoginStatus.loading,
                ),
                
                const SizedBox(height: AppDimensions.spacingL),
                
                // 密码输入
                CustomTextField(
                  controller: _passwordController,
                  placeholder: '密码',
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
                      return '请输入密码';
                    }
                    return null;
                  },
                  enabled: loginState.status != LoginStatus.loading,
                  onEditingComplete: _handleLogin,
                ),
                
                const SizedBox(height: AppDimensions.spacingM),
                
                // 忘记密码
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: loginState.status == LoginStatus.loading
                        ? null
                        : () {
                            // TODO: 实现忘记密码功能
                            showCupertinoDialog(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: const Text('提示'),
                                content: const Text('忘记密码功能开发中'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('确定'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: Text(
                      '忘记密码？',
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppDimensions.spacingXL),
                
                // 登录按钮
                CustomButton(
                  text: '登录',
                  onPressed: _handleLogin,
                  isLoading: loginState.status == LoginStatus.loading,
                  fullWidth: true,
                ),
                
                const SizedBox(height: AppDimensions.spacingL),
                
                // 注册提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: AppTextStyles.body,
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: loginState.status == LoginStatus.loading
                          ? null
                          : () {
                              context.push('/register');
                            },
                      child: Text(
                        '立即注册',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
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
