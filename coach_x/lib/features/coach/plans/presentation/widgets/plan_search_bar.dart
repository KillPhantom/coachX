import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';

/// 计划搜索栏
class PlanSearchBar extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClear;

  const PlanSearchBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onClear,
  });

  @override
  State<PlanSearchBar> createState() => _PlanSearchBarState();
}

class _PlanSearchBarState extends State<PlanSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(PlanSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _controller.text) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingM,
      ),
      child: CupertinoSearchTextField(
        controller: _controller,
        placeholder: 'Search plans',
        style: AppTextStyles.callout.copyWith(
          color: AppColors.textPrimary,
        ),
        placeholderStyle: AppTextStyles.callout.copyWith(
          color: AppColors.textTertiary,
        ),
        backgroundColor: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingM,
        ),
        onChanged: widget.onSearchChanged,
        onSuffixTap: () {
          _controller.clear();
          widget.onClear?.call();
          widget.onSearchChanged('');
        },
      ),
    );
  }
}

