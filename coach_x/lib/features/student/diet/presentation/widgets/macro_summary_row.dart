import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// 营养汇总行组件
class MacroSummaryRow extends StatelessWidget {
  final Macros macros;

  const MacroSummaryRow({super.key, required this.macros});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildMacroCard(
            label: l10n.protein,
            value: '${macros.protein.toInt()}g',
            backgroundColor: const Color(0xFFFFE5E5),
            textColor: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMacroCard(
            label: l10n.carbs,
            value: '${macros.carbs.toInt()}g',
            backgroundColor: const Color(0xFFFFF3CD),
            textColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMacroCard(
            label: l10n.fat,
            value: '${macros.fat.toInt()}g',
            backgroundColor: const Color(0xFFE0F2FE),
            textColor: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingM,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption1.copyWith(color: textColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
