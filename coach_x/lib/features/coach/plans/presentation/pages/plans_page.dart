import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/enums/app_status.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/empty_state.dart';
import 'package:coach_x/core/widgets/error_view.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../../data/models/plan_base_model.dart';
import '../providers/plans_providers.dart';
import '../widgets/plan_card.dart';
import '../widgets/plan_search_bar.dart';
import '../widgets/plan_action_sheet.dart';
import '../widgets/assign_plan_dialog.dart';
import '../widgets/create_plan_dialog.dart';
import '../widgets/exercise_library_entry.dart';

/// 计划管理页面
class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});

  @override
  ConsumerState<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends ConsumerState<PlansPage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // 加载计划列表
    Future.microtask(() {
      ref.read(plansNotifierProvider.notifier).loadPlans();
    });
  }

  /// 刷新计划列表
  Future<void> _handleRefresh() async {
    try {
      await ref.read(plansNotifierProvider.notifier).refreshPlans();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorToast('${l10n.refreshFailed}: $e');
      }
    }
  }

  /// 处理计划卡片点击
  void _handlePlanTap(PlanBaseModel plan) {
    AppLogger.info(
      '🎯 点击计划卡片 - 类型: ${plan.planType}, ID: ${plan.id}, 名称: ${plan.name}',
    );

    // 根据计划类型跳转到不同页面
    if (plan.planType == 'exercise') {
      // 训练计划跳转到编辑页面
      final route = '/training-plan/${plan.id}';
      AppLogger.info('🚀 导航到: $route');
      context.push(route);
    } else if (plan.planType == 'diet') {
      // 饮食计划跳转到编辑页面
      final route = '/diet-plan/${plan.id}';
      AppLogger.info('🚀 导航到: $route');
      context.push(route);
    } else if (plan.planType == 'supplement') {
      // 补剂计划跳转到编辑页面
      final route = '/supplement-plan/${plan.id}';
      AppLogger.info('🚀 导航到: $route');
      context.push(route);
    } else {
      // 其他类型计划跳转到详情页（占位）
      context.push('/plan-detail/${plan.planType}/${plan.id}');
    }
  }

  /// 处理更多操作点击
  Future<void> _handleMoreTap(PlanBaseModel plan) async {
    final action = await PlanActionSheet.show(context: context, plan: plan);

    if (action == null || !mounted) return;

    switch (action) {
      case PlanAction.assign:
        await _handleAssign(plan);
        break;
      case PlanAction.copy:
        await _handleCopy(plan);
        break;
      case PlanAction.delete:
        await _handleDelete(plan);
        break;
    }
  }

  /// 处理分配计划
  Future<void> _handleAssign(PlanBaseModel plan) async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => AssignPlanDialog(plan: plan),
        fullscreenDialog: true,
      ),
    );

    // 如果分配成功，已在AssignPlanDialog中刷新列表
    if (result == true && mounted) {
      // 可以显示成功提示
    }
  }

  /// 处理复制计划
  Future<void> _handleCopy(PlanBaseModel plan) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await _showConfirmDialog(
      title: l10n.copyPlan,
      message: l10n.confirmCopyPlan(plan.name),
      confirmText: l10n.copy,
    );

    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(plansNotifierProvider.notifier)
          .copyPlan(plan.id, plan.planType);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessToast(l10n.copySuccess);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorToast('${l10n.copyFailed}: $e');
      }
    }
  }

  /// 处理删除计划
  Future<void> _handleDelete(PlanBaseModel plan) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await _showConfirmDialog(
      title: l10n.deletePlan,
      message: l10n.confirmDeletePlan(plan.name),
      confirmText: l10n.delete,
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(plansNotifierProvider.notifier)
          .deletePlan(plan.id, plan.planType);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessToast(l10n.deleteSuccess);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorToast('${l10n.deleteFailed}: $e');
      }
    }
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: AppTextStyles.body),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: AppTextStyles.body),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示成功提示
  void _showSuccessToast(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  /// 显示错误提示
  void _showErrorToast(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  /// 显示创建计划弹窗
  Future<void> _showCreatePlanSheet() async {
    final result = await CreatePlanDialog.show(context);

    if (result != null && mounted) {
      // 根据计划类型跳转
      if (result == 'exercise') {
        // 跳转到创建训练计划页面
        context.push('/training-plan/new');
      } else if (result == 'diet') {
        // 跳转到创建饮食计划页面
        context.push('/diet-plan/new');
      } else if (result == 'supplement') {
        // 跳转到创建补剂计划页面
        context.push('/supplement-plan/new');
      } else {
        // 其他类型计划跳转到占位页面
        context.push('/plan-detail/$result/new');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(plansNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = screenWidth / 3;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        children: [
          // 自定义Navigation Bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border(
                bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        l10n.plansTitle,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _showCreatePlanSheet,
                        child: const Icon(
                          CupertinoIcons.add,
                          size: 28,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab切换栏（带滑动动画的下划线）
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border(
                bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
              ),
            ),
            child: Stack(
              children: [
                // Tab按钮行
                Row(
                  children: [
                    _buildTab(l10n.tabTraining, 0),
                    _buildTab(l10n.tabDiet, 1),
                    _buildTab(l10n.tabSupplements, 2),
                  ],
                ),
                // 滑动的下划线
                Positioned(
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: tabWidth,
                    height: 2,
                    margin: EdgeInsets.only(left: tabWidth * _selectedTabIndex),
                    decoration: const BoxDecoration(color: Color(0xFFEC1313)),
                  ),
                ),
              ],
            ),
          ),
          // 动作库入口（仅在训练计划tab显示）
          if (_selectedTabIndex == 0) const ExerciseLibraryEntry(),
          // 搜索栏
          PlanSearchBar(
            searchQuery: state.searchQuery,
            onSearchChanged: (query) {
              ref.read(plansNotifierProvider.notifier).searchPlans(query);
            },
            onClear: () {
              ref.read(plansNotifierProvider.notifier).clearSearch();
            },
          ),
          // 计划列表
          Expanded(
            child: DismissKeyboardOnScroll(
              child: CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _handleRefresh),
                  _buildContent(state),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(state) {
    if (state.loadingStatus == LoadingStatus.initial ||
        state.loadingStatus == LoadingStatus.loading) {
      return const SliverFillRemaining(
        child: Center(child: LoadingIndicator()),
      );
    } else if (state.loadingStatus == LoadingStatus.error) {
      return SliverFillRemaining(
        child: ErrorView(
          error: state.errorMessage ?? '加载失败',
          onRetry: () {
            ref.read(plansNotifierProvider.notifier).loadPlans();
          },
        ),
      );
    } else {
      return _buildPlansList(context, state);
    }
  }

  Widget _buildPlansList(BuildContext context, state) {
    final l10n = AppLocalizations.of(context)!;
    final plans = state.getFilteredPlans(_selectedTabIndex);

    if (plans.isEmpty) {
      // 显示空状态
      if (state.searchQuery.isNotEmpty) {
        return SliverFillRemaining(
          child: EmptyState(
            icon: CupertinoIcons.search,
            title: l10n.noResults,
            message: l10n.noPlansFoundForQuery(state.searchQuery),
            actionText: l10n.clearSearch,
            onAction: () {
              ref.read(plansNotifierProvider.notifier).clearSearch();
            },
          ),
        );
      } else {
        return SliverFillRemaining(
          child: EmptyState(
            icon: CupertinoIcons.list_bullet,
            title: l10n.noPlansYet,
            message: l10n.createFirstPlan(_getTabName()),
            actionText: l10n.createPlan,
            onAction: _showCreatePlanSheet,
          ),
        );
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final plan = plans[index];
        return PlanCard(
          plan: plan,
          onTap: () => _handlePlanTap(plan),
          onMoreTap: () => _handleMoreTap(plan),
        );
      }, childCount: plans.length),
    );
  }

  String _getTabName() {
    switch (_selectedTabIndex) {
      case 0:
        return 'training';
      case 1:
        return 'diet';
      case 2:
        return 'supplement';
      default:
        return 'plan';
    }
  }

  /// 构建Tab按钮
  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.callout.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
