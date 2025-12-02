import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_import_stats.dart';

/// 饮食计划统计摘要卡片
///
/// 显示生成完成后的饮食计划统计数据，采用 2x2 + 1 布局：
/// ┌──────────────┬──────────────┐
/// │ 饮食天数: 7   │ 总餐次: 28    │
/// ├──────────────┼──────────────┤
/// │ BMR: 1650    │ TDEE: 2200   │
/// ├──────────────┴──────────────┤
/// │ 目标热量: 2000 (居中)       │
/// └─────────────────────────────┘
class DietSummaryCard extends StatefulWidget {
  final DietPlanImportStats stats;
  final VoidCallback? onViewPlan;

  const DietSummaryCard({
    super.key,
    required this.stats,
    this.onViewPlan,
  });

  @override
  State<DietSummaryCard> createState() => _DietSummaryCardState();
}

class _DietSummaryCardState extends State<DietSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoColors.systemGreen,
                CupertinoColors.systemGreen.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 20),
              _buildStats(l10n),
              // 只在提供了 onViewPlan 回调时才显示按钮
              if (widget.onViewPlan != null) ...[
                const SizedBox(height: 20),
                _buildButton(l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(
          CupertinoIcons.checkmark_circle_fill,
          size: 24,
          color: CupertinoColors.white,
        ),
        const SizedBox(width: 12),
        Text(
          l10n.summaryTitle,
          style: AppTextStyles.body.copyWith(
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(AppLocalizations l10n) {
    return Column(
      children: [
        // 第一行：饮食天数 + 总餐次
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                widget.stats.totalDays.toString(),
                l10n.statDietTotalDays,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatItem(
                widget.stats.totalMeals.toString(),
                l10n.statDietTotalMeals,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 第二行：BMR + TDEE
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                widget.stats.bmr.toInt().toString(),
                l10n.statBMR,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatItem(
                widget.stats.tdee.toInt().toString(),
                l10n.statTDEE,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 第三行：目标热量（居中）
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _AnimatedNumber(
                number: widget.stats.targetCalories.toInt(),
                style: AppTextStyles.title1.copyWith(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.statTargetCalories,
                style: AppTextStyles.caption1.copyWith(
                  color: CupertinoColors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _AnimatedNumber(
            number: int.tryParse(number) ?? 0,
            style: AppTextStyles.title1.copyWith(
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(
              color: CupertinoColors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(AppLocalizations l10n) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(14),
      onPressed: widget.onViewPlan!,
      child: Text(
        l10n.viewFullPlan,
        style: AppTextStyles.buttonSmall.copyWith(
          color: AppColors.primaryAction,
        ),
      ),
    );
  }
}

/// 数字动画组件
class _AnimatedNumber extends StatefulWidget {
  final int number;
  final TextStyle style;

  const _AnimatedNumber({
    required this.number,
    required this.style,
  });

  @override
  State<_AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<_AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = IntTween(begin: 0, end: widget.number).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}
