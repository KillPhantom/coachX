import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/features/coach/students/data/models/student_list_item_model.dart';

/// 学生选择列表项
class StudentSelectionItem {
  final StudentListItemModel student;
  final bool isSelected;
  final bool hasCurrentPlan; // 是否已分配当前计划
  final bool hasConflictPlan; // 是否有同类计划冲突

  const StudentSelectionItem({
    required this.student,
    required this.isSelected,
    required this.hasCurrentPlan,
    required this.hasConflictPlan,
  });

  StudentSelectionItem copyWith({
    bool? isSelected,
  }) {
    return StudentSelectionItem(
      student: student,
      isSelected: isSelected ?? this.isSelected,
      hasCurrentPlan: hasCurrentPlan,
      hasConflictPlan: hasConflictPlan,
    );
  }
}

/// 学生选择列表组件
class StudentSelectionList extends StatelessWidget {
  final List<StudentSelectionItem> students;
  final ValueChanged<String> onToggleStudent;
  final String searchQuery;

  const StudentSelectionList({
    super.key,
    required this.students,
    required this.onToggleStudent,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    // 应用搜索过滤
    final filteredStudents = searchQuery.trim().isEmpty
        ? students
        : students.where((item) {
            final query = searchQuery.toLowerCase();
            return item.student.name.toLowerCase().contains(query) ||
                item.student.email.toLowerCase().contains(query);
          }).toList();

    if (filteredStudents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXXL),
          child: Text(
            'No students found',
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final item = filteredStudents[index];
        return _StudentSelectionTile(
          item: item,
          onTap: () => onToggleStudent(item.student.id),
        );
      },
    );
  }
}

/// 学生选择列表项
class _StudentSelectionTile extends StatelessWidget {
  final StudentSelectionItem item;
  final VoidCallback onTap;

  const _StudentSelectionTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingM,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.dividerLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 头像
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                image: item.student.avatarUrl != null &&
                        item.student.avatarUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.student.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.student.avatarUrl == null ||
                      item.student.avatarUrl!.isEmpty
                  ? Center(
                      child: Text(
                        item.student.name.isNotEmpty
                            ? item.student.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            // 学生信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.student.name,
                          style: AppTextStyles.callout.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 状态标签
                      if (item.hasCurrentPlan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Text(
                            'Assigned',
                            style: AppTextStyles.caption2.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (item.hasConflictPlan && !item.hasCurrentPlan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningYellow.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Text(
                            'Has Plan',
                            style: AppTextStyles.caption2.copyWith(
                              color: AppColors.warningYellow,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.student.email,
                    style: AppTextStyles.footnote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            // 选择框
            Icon(
              item.isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: item.isSelected
                  ? AppColors.successGreen
                  : AppColors.textTertiary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

