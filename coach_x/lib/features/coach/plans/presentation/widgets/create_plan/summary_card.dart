import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/ai_streaming_stats.dart';

class SummaryCard extends StatefulWidget {
  final AIStreamingStats stats;
  final VoidCallback onViewPlan;

  const SummaryCard({
    super.key,
    required this.stats,
    required this.onViewPlan,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
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
                CupertinoColors.systemGreen.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 20),
              _buildStats(l10n),
              const SizedBox(height: 20),
              _buildButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(CupertinoIcons.checkmark_circle_fill, size: 24, color: CupertinoColors.white),
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
        // 第一行：训练天数 + 训练动作
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                widget.stats.totalDays.toString(),
                l10n.statTotalDays,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatItem(
                widget.stats.totalExercises.toString(),
                l10n.statTotalExercises,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // 第二行：复用动作 + 新建动作
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                widget.stats.reusedExercises.toString(),
                l10n.statReusedExercises,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatItem(
                widget.stats.newExercises.toString(),
                l10n.statNewExercises,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.2),
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
              color: CupertinoColors.white.withOpacity(0.9),
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
      onPressed: widget.onViewPlan,
      child: Text(
        l10n.viewFullPlan,
        style: AppTextStyles.buttonSmall.copyWith(
          color: AppColors.primaryAction,
        ),
      ),
    );
  }
}

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
