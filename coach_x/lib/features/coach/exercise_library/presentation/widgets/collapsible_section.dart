import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// Collapsible Section - 可折叠区域组件
///
/// 通用的折叠区域，包含标题、展开/收起图标和内容
class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏（可点击）
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Text(widget.title, style: AppTextStyles.bodyMedium),
              const SizedBox(width: 8),
              Icon(
                _isExpanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),

        // 内容区域（根据展开状态显示/隐藏）
        if (_isExpanded) ...[
          const SizedBox(height: AppDimensions.spacingS),
          widget.child,
        ],
      ],
    );
  }
}
