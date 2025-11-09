import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'macro_progress_bar.dart';
import 'dart:math' as math;

/// 总营养卡片
///
/// 显示环形进度条（总卡路里）和3个宏营养素进度条
class TotalNutritionCard extends StatelessWidget {
  final Macros macros;
  final Map<String, double> progress;

  const TotalNutritionCard({
    super.key,
    required this.macros,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：环形进度条
          Expanded(flex: 2, child: Center(child: _buildCircularProgress(l10n))),

          const SizedBox(width: AppDimensions.spacingM),

          // 右侧：标题 + 3个宏营养素进度条
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.totalNutrition,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Protein
                MacroProgressBar(
                  label: l10n.protein,
                  value: macros.protein.toInt(),
                  progress: progress['protein'] ?? 0.0,
                  color: const Color(0xFFFF6B6B),
                ),
                const SizedBox(height: 8),

                // Carbs
                MacroProgressBar(
                  label: l10n.carbs,
                  value: macros.carbs.toInt(),
                  progress: progress['carbs'] ?? 0.0,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 8),

                // Fat
                MacroProgressBar(
                  label: l10n.fat,
                  value: macros.fat.toInt(),
                  progress: progress['fat'] ?? 0.0,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(AppLocalizations l10n) {
    final calorieProgress = progress['calories'] ?? 0.0;

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // 环形进度条
          CustomPaint(
            size: const Size(100, 100),
            painter: _CircularProgressPainter(
              progress: calorieProgress,
              progressColor: AppColors.primaryColor,
              backgroundColor: AppColors.dividerLight,
            ),
          ),

          // 中心文字
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${macros.calories.toInt()}',
                  style: AppTextStyles.title3.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.kcal,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 自定义环形进度条绘制器
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // 绘制背景环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // 绘制进度环
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
