import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/services/user_cache_service.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// Splash页面
///
/// 在应用启动时显示品牌元素，同时异步加载用户数据
/// 加载成功后跳转到对应首页，失败则清除认证并返回登录页
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // 初始化Logo淡入动画
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // 开始加载用户数据
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 加载用户数据
  ///
  /// 从Firestore查询用户信息并缓存，然后导航到对应首页
  /// 如果失败则清除认证状态并返回登录页
  Future<void> _loadUserData() async {
    try {
      AppLogger.info('Splash: 开始加载用户数据');

      // 获取当前用户
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.warning('Splash: 用户未登录');
        _navigateToLogin();
        return;
      }

      // 从Firestore查询用户信息（设置10秒超时）
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
        AppLogger.error('Splash: 用户文档不存在');
        throw Exception('用户信息不存在');
      }

      final userData = userDoc.data();
      if (userData == null) {
        AppLogger.error('Splash: 用户数据为空');
        throw Exception('用户数据为空');
      }

      final role = userData['role'] as String?;
      if (role == null || (role != 'coach' && role != 'student')) {
        AppLogger.error('Splash: 用户角色无效: $role');
        throw Exception('用户角色无效');
      }

      AppLogger.info('Splash: 用户数据加载成功，角色: $role');

      // 保存到缓存
      await UserCacheService.saveUserCache(userId: currentUser.uid, role: role);

      // 确保最小显示时长（1.5秒），展示品牌元素
      await Future.delayed(const Duration(milliseconds: 1500));

      // 根据角色导航到对应首页
      if (!mounted) return;

      if (role == 'coach') {
        context.go(RouteNames.coachHome);
      } else {
        context.go(RouteNames.studentHome);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Splash: 加载用户数据失败', e, stackTrace);

      // 显示错误状态
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }

      // 等待2秒让用户看到错误信息
      await Future.delayed(const Duration(seconds: 2));

      // 清除认证状态
      await AuthService.signOut();
      await UserCacheService.clearCache();

      // 返回登录页
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  /// 导航到登录页
  void _navigateToLogin() {
    if (!mounted) return;
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo动画
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Logo图标
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App名称
                    Text(
                      'CoachX',
                      style: AppTextStyles.largeTitle.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Slogan
                    Text(
                      'AI-Powered Coaching Platform',
                      style: AppTextStyles.callout.copyWith(
                        color: CupertinoColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Loading或错误状态
              if (_hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: CupertinoColors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.splashLoadError,
                        style: AppTextStyles.callout.copyWith(
                          color: CupertinoColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.footnote.copyWith(
                            color: CupertinoColors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                      radius: 16,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.splashLoading,
                      style: AppTextStyles.callout.copyWith(
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
