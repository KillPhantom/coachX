import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/unit_converter.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/features/shared/profile/presentation/widgets/profile_header.dart';
import 'package:coach_x/features/shared/profile/presentation/widgets/info_card.dart';
import 'package:coach_x/features/shared/profile/presentation/widgets/info_row.dart';
import 'package:coach_x/features/shared/profile/presentation/widgets/settings_row.dart';
import 'package:coach_x/features/student/profile/presentation/widgets/coach_info_card.dart';
import 'package:coach_x/features/student/profile/presentation/providers/student_profile_providers.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';

/// 学生Profile页面
class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentStudentProvider);
    final coachAsync = ref.watch(coachInfoProvider);
    final isMetric = ref.watch(isMetricProvider);

    if (currentUser == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部导航栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Center(
                  child: Text(l10n.profile, style: AppTextStyles.title2),
                ),
              ),
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: ProfileHeader(
                avatarUrl: currentUser.avatarUrl,
                name: currentUser.name,
                roleText: l10n.student,
                onEditTap: () {
                  // TODO: 实现头像编辑功能
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text(l10n.alert),
                      content: Text(l10n.avatarEditInDevelopment),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(l10n.confirm),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 内容区域
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.spacingL),

                  // Personal Information
                  InfoCard(
                    title: l10n.personalInformation,
                    child: Column(
                      children: [
                        InfoRow(
                          label: l10n.age,
                          value: UnitConverter.formatAge(currentUser.bornDate),
                          showDivider: true,
                        ),
                        InfoRow(
                          label: l10n.height,
                          value: UnitConverter.formatHeight(
                            currentUser.height,
                            useMetric: isMetric,
                          ),
                          showDivider: true,
                        ),
                        InfoRow(
                          label: l10n.weight,
                          value: UnitConverter.formatWeight(
                            currentUser.initialWeight,
                            useMetric: isMetric,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacingL),

                  // Coach Info
                  if (currentUser.coachId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.coachInfo, style: AppTextStyles.title3),
                        const SizedBox(height: AppDimensions.spacingM),
                        coachAsync.when(
                          data: (coach) {
                            if (coach == null) {
                              return _buildNoCoachCard();
                            }
                            return CoachInfoCard(
                              coach: coach,
                              contractExpiresAt: currentUser.contractExpiresAt,
                            );
                          },
                          loading: () =>
                              const Center(child: CupertinoActivityIndicator()),
                          error: (error, _) =>
                              _buildErrorCard(error.toString()),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                      ],
                    ),

                  // Settings
                  InfoCard(
                    title: l10n.settings,
                    child: Column(
                      children: [
                        // Notifications Toggle
                        _buildNotificationsRow(
                          currentUser.notificationsEnabled,
                        ),

                        // Unit Preference
                        SettingsRow(
                          title: l10n.unitPreference,
                          onTap: _showUnitPreferenceSheet,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isMetric ? l10n.metric : l10n.imperial,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacingS),
                              const Icon(
                                CupertinoIcons.forward,
                                size: 20,
                                color: AppColors.textTertiary,
                              ),
                            ],
                          ),
                        ),

                        // Privacy Settings
                        SettingsRow(
                          title: l10n.privacySettings,
                          onTap: () {
                            // TODO: 跳转到Privacy Settings页面
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: Text(l10n.alert),
                                content: Text(l10n.featureInDevelopment),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text(l10n.confirm),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Log Out
                        SettingsRow(
                          title: l10n.logOut,
                          isDangerous: true,
                          showDivider: false,
                          onTap: _handleLogOut,
                        ),
                      ],
                    ),
                  ),

                  // 底部间距（避免被TabBar遮挡）
                  const SizedBox(height: AppDimensions.spacingXXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Notifications 行
  Widget _buildNotificationsRow(bool enabled) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.notifications, style: AppTextStyles.body),
          CupertinoSwitch(
            value: enabled,
            onChanged: (value) {
              _updateNotificationsEnabled(value);
            },
          ),
        ],
      ),
    );
  }

  /// 更新通知开关
  Future<void> _updateNotificationsEnabled(bool enabled) async {
    final currentUser = ref.read(currentStudentProvider);
    if (currentUser == null) return;

    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateUser(currentUser.id, {
        'notificationsEnabled': enabled,
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text('${l10n.updateFailed}: $e'),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 显示单位偏好选择Sheet
  void _showUnitPreferenceSheet() {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(l10n.unitPreference),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _updateUnitPreference('imperial');
              Navigator.of(context).pop();
            },
            child: Text(l10n.imperialUnit),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _updateUnitPreference('metric');
              Navigator.of(context).pop();
            },
            child: Text(l10n.metricUnit),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  /// 更新单位偏好
  Future<void> _updateUnitPreference(String preference) async {
    final currentUser = ref.read(currentStudentProvider);
    if (currentUser == null) return;

    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateUser(currentUser.id, {'unitPreference': preference});
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.error),
            content: Text('${l10n.updateFailed}: $e'),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.confirm),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 处理登出
  void _handleLogOut() {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.confirmLogOut),
        content: Text(l10n.confirmLogOutMessage),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService.signOut();
              if (mounted) {
                context.go(RouteNames.login);
              }
            },
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }

  /// 构建无教练卡片
  Widget _buildNoCoachCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Text(
        l10n.noCoachInfo,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建错误卡片
  Widget _buildErrorCard(String error) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Text(
        '${l10n.loadCoachInfoFailed}: $error',
        style: AppTextStyles.body.copyWith(color: AppColors.errorRed),
        textAlign: TextAlign.center,
      ),
    );
  }
}
