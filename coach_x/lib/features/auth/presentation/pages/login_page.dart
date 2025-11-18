import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_button.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/user_cache_service.dart';
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
    try {
      AppLogger.info('LoginPage: 登录成功，开始加载用户数据');

      // 获取当前用户
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.error('LoginPage: 登录后用户为空');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(l10n.error),
              content: Text(l10n.getUserInfoFailed),
              actions: [
                CupertinoDialogAction(
                  child: Text(l10n.confirm),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
        return;
      }

      // 从Firestore查询用户信息
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('查询用户信息超时');
            },
          );

      if (!userDoc.exists) {
        AppLogger.warning('LoginPage: 用户文档不存在，跳转到Profile Setup');
        if (mounted) context.go(RouteNames.profileSetup);
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        AppLogger.error('LoginPage: 用户数据为空');
        if (mounted) context.go(RouteNames.profileSetup);
        return;
      }

      final role = userData['role'] as String?;
      if (role == null || (role != 'coach' && role != 'student')) {
        AppLogger.warning('LoginPage: 用户角色无效或不存在，跳转到Profile Setup');
        if (mounted) context.go(RouteNames.profileSetup);
        return;
      }

      AppLogger.info('LoginPage: 用户数据加载成功，角色: $role');

      // 保存到缓存
      await UserCacheService.saveUserCache(userId: currentUser.uid, role: role);

      // 根据角色导航到对应首页
      if (!mounted) return;

      if (role == 'coach') {
        context.go(RouteNames.coachHome);
      } else {
        context.go(RouteNames.studentHome);
      }
    } catch (e, stackTrace) {
      AppLogger.error('LoginPage: 加载用户数据失败', e, stackTrace);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text('${l10n.getUserInfoFailed}: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
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
        child: DismissKeyboard(
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
                    'assets/images/icon.png',
                    width: 100,
                    height: 100,
                  ),
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
                                  content: Text(
                                    l10n.forgotPasswordInDevelopment,
                                  ),
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
      ),
    );
  }
}
