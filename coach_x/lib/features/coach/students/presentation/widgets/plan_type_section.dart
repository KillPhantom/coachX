import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/plan_summary.dart';

/// 计划类型Section组件
///
/// 可展开/折叠的卡片式section，用于在AssignPlansToStudentDialog中
/// 显示和选择特定类型的计划
class PlanTypeSection extends StatelessWidget {
  /// 计划类型: 'exercise', 'diet', 'supplement'
  final String planType;

  /// 是否展开
  final bool isExpanded;

  /// 学生当前分配的计划ID
  final String? currentPlanId;

  /// 用户选择的计划ID（可能与currentPlanId不同）
  final String? selectedPlanId;

  /// 可用计划列表
  final List<PlanSummary> plans;

  /// 是否正在加载
  final bool isLoading;

  /// 切换展开/折叠的回调
  final VoidCallback onToggle;

  /// 选择计划的回调 (planId为null表示选择"无计划")
  final Function(String? planId) onSelectPlan;

  const PlanTypeSection({
    super.key,
    required this.planType,
    required this.isExpanded,
    this.currentPlanId,
    this.selectedPlanId,
    required this.plans,
    this.isLoading = false,
    required this.onToggle,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          // 头部：折叠态显示
          _buildHeader(context, l10n),

          // 展开内容
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context, l10n),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onToggle,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Row(
          children: [
            // 图标
            Icon(
              _getPlanTypeIcon(),
              size: AppDimensions.iconM,
              color: AppColors.textPrimary,
            ),

            const SizedBox(width: AppDimensions.spacingM),

            // 标题和当前计划
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPlanTypeDisplayName(l10n),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    _getCurrentPlanDisplayName(l10n),
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 展开箭头
            Icon(
              isExpanded
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_right,
              size: AppDimensions.iconS,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展开内容
  Widget _buildExpandedContent(BuildContext context, AppLocalizations l10n) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (plans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Center(
          child: Text(
            l10n.noPlansAvailable,
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // 计划列表 + "无计划"选项
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusM),
          bottomRight: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        shrinkWrap: true,
        itemCount: plans.length + 1, // +1 for "无计划" option
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: AppColors.divider,
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
          ),
        ),
        itemBuilder: (context, index) {
          // 最后一项是"无计划"选项
          if (index == plans.length) {
            return _buildNoPlanOption(context, l10n);
          }

          final plan = plans[index];
          final isSelected = selectedPlanId == plan.id;
          final isCurrent = currentPlanId == plan.id;

          return _buildPlanItem(
            context,
            l10n,
            plan: plan,
            isSelected: isSelected,
            isCurrent: isCurrent,
          );
        },
      ),
    );
  }

  /// 构建计划选项
  Widget _buildPlanItem(
    BuildContext context,
    AppLocalizations l10n, {
    required PlanSummary plan,
    required bool isSelected,
    required bool isCurrent,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => onSelectPlan(plan.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingM,
        ),
        child: Row(
          children: [
            // 单选圆圈
            Icon(
              isSelected
                  ? CupertinoIcons.circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textTertiary,
            ),

            const SizedBox(width: AppDimensions.spacingM),

            // 计划信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: AppTextStyles.callout.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // "当前"标签
                      if (isCurrent) ...[
                        const SizedBox(width: AppDimensions.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            l10n.currentPlan,
                            style: AppTextStyles.caption2.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.briefInfo.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      plan.briefInfo,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建"无计划"选项
  Widget _buildNoPlanOption(BuildContext context, AppLocalizations l10n) {
    final isSelected = selectedPlanId == null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => onSelectPlan(null),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingM,
        ),
        child: Row(
          children: [
            // 单选圆圈
            Icon(
              isSelected
                  ? CupertinoIcons.circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textTertiary,
            ),

            const SizedBox(width: AppDimensions.spacingM),

            // "无计划"文本
            Text(
              l10n.noPlanOption,
              style: AppTextStyles.callout.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取计划类型的图标
  IconData _getPlanTypeIcon() {
    switch (planType) {
      case 'exercise':
        return CupertinoIcons.sportscourt;
      case 'diet':
        return CupertinoIcons.square_list;
      case 'supplement':
        return CupertinoIcons.capsule;
      default:
        return CupertinoIcons.question;
    }
  }

  /// 获取计划类型的显示名称
  String _getPlanTypeDisplayName(AppLocalizations l10n) {
    switch (planType) {
      case 'exercise':
        return l10n.exercisePlanSection;
      case 'diet':
        return l10n.dietPlanSection;
      case 'supplement':
        return l10n.supplementPlanSection;
      default:
        return '';
    }
  }

  /// 获取当前计划的显示名称
  String _getCurrentPlanDisplayName(AppLocalizations l10n) {
    if (selectedPlanId == null) {
      return l10n.notAssigned;
    }

    // 从plans列表中找到对应的计划
    final plan = plans.where((p) => p.id == selectedPlanId).firstOrNull;
    if (plan != null) {
      return plan.name;
    }

    // 如果在列表中找不到（比如已被删除），显示当前选择的ID
    if (currentPlanId == selectedPlanId) {
      return '${l10n.currentPlan} (ID: ${selectedPlanId?.substring(0, 8)})';
    }

    return l10n.notAssigned;
  }
}
