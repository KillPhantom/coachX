import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_button.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/features/auth/presentation/controllers/login_controller.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';
import 'package:coach_x/core/enums/user_role.dart';

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
      ref
          .read(loginControllerProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  /// 根据用户角色导航到对应的首页
  Future<void> _navigateToHomePage() async {
    // 等待用户数据加载完成（最多等待3秒）
    int attempts = 0;
    const maxAttempts = 30; // 30 * 100ms = 3秒

    while (attempts < maxAttempts) {
      final userData = ref.read(currentUserDataProvider);

      // 检查数据是否已加载
      if (userData is AsyncData) {
        final user = userData.value;

        if (user == null) {
          // 用户数据不存在，跳转到Profile Setup
          if (mounted) context.go(RouteNames.profileSetup);
          return;
        }

        // 根据用户角色跳转到对应的首页
        if (mounted) {
          if (user.role == UserRole.coach) {
            context.go(RouteNames.coachHome);
          } else if (user.role == UserRole.student) {
            context.go(RouteNames.studentHome);
          } else {
            // 未知角色，跳转到Profile Setup
            context.go(RouteNames.profileSetup);
          }
        }
        return;
      }

      // 如果是错误状态，显示错误并返回登录页
      if (userData is AsyncError) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(l10n.error),
              content: Text('${l10n.getUserInfoFailed}: ${userData.error}'),
              actions: [
                CupertinoDialogAction(
                  child: Text(l10n.confirm),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(RouteNames.login);
                  },
                ),
              ],
            ),
          );
        }
        return;
      }

      // 等待100ms后重试
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // 超时，显示错误提示
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.error),
          content: Text(l10n.getUserInfoTimeout),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.confirm),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(RouteNames.login);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginControllerProvider);

    // 监听登录状态
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.status == LoginStatus.success) {
        // 登录成功，根据用户角色导航到对应的首页
        _navigateToHomePage();
      } else if (next.status == LoginStatus.error) {
        // 显示错误提示
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.loginFailed),
            content: Text(next.errorMessage ?? l10n.errorOccurred),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm),
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
                Image.asset('assets/images/icon.png', width: 100, height: 100),
                const SizedBox(height: AppDimensions.spacingL),
                Text(
                  l10n.appName,
                  style: AppTextStyles.largeTitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  l10n.appTagline,
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

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
                  enabled: loginState.status != LoginStatus.loading,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 密码输入
                CustomTextField(
                  controller: _passwordController,
                  placeholder: l10n.passwordPlaceholder,
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
                      return l10n.passwordRequired;
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
                                title: Text(l10n.alert),
                                content: Text(l10n.forgotPasswordInDevelopment),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text(l10n.confirm),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: Text(
                      l10n.forgotPassword,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.spacingXL),

                // 登录按钮
                CustomButton(
                  text: l10n.login,
                  onPressed: _handleLogin,
                  isLoading: loginState.status == LoginStatus.loading,
                  fullWidth: true,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 注册提示
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.noAccount, style: AppTextStyles.body),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: loginState.status == LoginStatus.loading
                          ? null
                          : () {
                              context.push('/register');
                            },
                      child: Text(
                        l10n.signUpNow,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryText,
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
