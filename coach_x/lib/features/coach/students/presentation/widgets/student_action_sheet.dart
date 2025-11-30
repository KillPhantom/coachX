import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/student_list_item_model.dart';
import 'assign_plans_to_student_dialog.dart';

/// 学生操作ActionSheet
class StudentActionSheet {
  /// 显示操作菜单
  static void show(
    BuildContext context, {
    required StudentListItemModel student,
    required VoidCallback onDelete,
    VoidCallback? onRefresh,
  }) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // 跳转到学生详情页
              context.push('/student-detail/${student.id}');
            },
            child: Text(
              l10n.viewDetails,
              style: AppTextStyles.body.copyWith(color: AppColors.primaryText),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAssignPlansDialog(context, student, onRefresh);
            },
            child: Text(
              l10n.assignPlan,
              style: AppTextStyles.body.copyWith(color: AppColors.primaryText),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, student, onDelete);
            },
            child: Text(
              l10n.deleteStudent,
              style: AppTextStyles.body.copyWith(color: AppColors.secondaryRed),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: AppTextStyles.body.copyWith(color: AppColors.primaryText),
          ),
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  static void _showDeleteConfirmation(
    BuildContext context,
    StudentListItemModel student,
    VoidCallback onConfirm,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteStudent(student.name)),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel, style: AppTextStyles.body),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(l10n.delete, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  /// 显示分配计划对话框
  static void _showAssignPlansDialog(
    BuildContext context,
    StudentListItemModel student,
    VoidCallback? onRefresh,
  ) {
    Navigator.of(context)
        .push<bool>(
          CupertinoPageRoute(
            builder: (context) => AssignPlansToStudentDialog(student: student),
            fullscreenDialog: true,
          ),
        )
        .then((success) {
          if (success == true && onRefresh != null) {
            // 刷新学生列表
            onRefresh();
          }
        });
  }
}
