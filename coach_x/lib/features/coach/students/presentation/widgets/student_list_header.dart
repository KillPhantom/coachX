import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 学生列表头部（搜索和筛选栏）
class StudentListHeader extends StatelessWidget {
  final int totalCount;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;
  final VoidCallback onAddTap;
  final bool hasFilter;
  final bool isSearching;

  const StudentListHeader({
    super.key,
    required this.totalCount,
    required this.onSearchTap,
    required this.onFilterTap,
    required this.onAddTap,
    this.hasFilter = false,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingM,
      ),
      color: AppColors.backgroundLight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 学生数量统计
          Text(
            l10n.studentCount(totalCount),
            style: AppTextStyles.subhead,
          ),

          // 搜索、筛选和添加按钮
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onSearchTap,
                child: Icon(
                  CupertinoIcons.search,
                  size: AppDimensions.iconM,
                  color: isSearching 
                      ? AppColors.primaryText 
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onFilterTap,
                child: Stack(
                  children: [
                    Icon(
                      CupertinoIcons.line_horizontal_3_decrease,
                      size: AppDimensions.iconM,
                      color: hasFilter
                          ? AppColors.primaryText
                          : AppColors.textSecondary,
                    ),
                    if (hasFilter)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onAddTap,
                child: const Icon(
                  CupertinoIcons.add_circled,
                  size: 28,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

