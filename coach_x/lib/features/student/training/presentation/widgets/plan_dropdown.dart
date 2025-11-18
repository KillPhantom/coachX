import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_base_model.dart';
import 'package:coach_x/l10n/app_localizations.dart';

/// 计划选择下拉组件
///
/// 通用的计划下拉选择器，支持所有类型的计划（训练/饮食/补剂）
/// 显示计划列表 + "创建新计划" 按钮
class PlanDropdown<T extends PlanBaseModel> extends StatefulWidget {
  /// 计划列表
  final List<T> plans;

  /// 当前选中的计划ID
  final String? activePlanId;

  /// 计划选择回调
  final Function(String planId) onPlanSelected;

  /// 创建新计划回调
  final VoidCallback onCreateNew;

  const PlanDropdown({
    super.key,
    required this.plans,
    required this.activePlanId,
    required this.onPlanSelected,
    required this.onCreateNew,
  });

  @override
  State<PlanDropdown<T>> createState() => _PlanDropdownState<T>();
}

class _PlanDropdownState<T extends PlanBaseModel>
    extends State<PlanDropdown<T>> {
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _widgetKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  /// 获取当前选中的计划
  T? get _activePlan {
    if (widget.activePlanId == null) return null;
    try {
      return widget.plans.firstWhere((p) => p.id == widget.activePlanId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  /// 显示 Overlay 下拉菜单
  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = _createOverlayEntry();
    overlay.insert(_overlayEntry!);
  }

  /// 隐藏 Overlay 下拉菜单
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 创建 OverlayEntry
  OverlayEntry _createOverlayEntry() {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 1. 透明遮罩（全屏）
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                  _hideOverlay();
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

          // 2. 下拉菜单（跟随 Header 定位）
          Positioned(
            width: _getHeaderWidth(),
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              child: ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  heightFactor: _isExpanded ? 1.0 : 0.0,
                  child: Material(
                    elevation: 8,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    color: AppColors.cardBackground,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.4,
                      ),
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              // 计划列表
                              ...widget.plans.map((plan) {
                                final isActive = plan.id == widget.activePlanId;
                                return _buildPlanItem(
                                  plan: plan,
                                  isActive: isActive,
                                  onTap: () {
                                    widget.onPlanSelected(plan.id);
                                    setState(() {
                                      _isExpanded = false;
                                      _hideOverlay();
                                    });
                                  },
                                );
                              }),

                              // 分隔线
                              if (widget.plans.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),

                              // "创建新计划" 按钮
                              _buildCreateNewButton(l10n),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取 Header 的实际宽度
  double _getHeaderWidth() {
    final renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activePlan = _activePlan;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _widgetKey,
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
            if (_isExpanded) {
              _showOverlay();
            } else {
              _hideOverlay();
            }
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: _isExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  )
                : BorderRadius.circular(12),
            border: _isExpanded
                ? null
                : Border.all(color: AppColors.cardBackground, width: 1.5),
            boxShadow: _isExpanded
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectPlan,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activePlan?.name ?? l10n.selectPlan,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建计划项
  Widget _buildPlanItem({
    required T plan,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.cardBackground,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isActive
                          ? AppColors.primaryText
                          : AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 20,
                color: AppColors.primaryText,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建"创建新计划"按钮
  Widget _buildCreateNewButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        widget.onCreateNew();
        setState(() {
          _isExpanded = false;
          _hideOverlay();
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.add_circled,
              size: 20,
              color: AppColors.primaryText,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.createNewPlan,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
