import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/plan_base_model.dart';

/// 计划操作菜单
class PlanActionSheet {
  /// 显示操作菜单
  static Future<PlanAction?> show({
    required BuildContext context,
    required PlanBaseModel plan,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return showCupertinoModalPopup<PlanAction>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(plan.name),
        message: Text(plan.planTypeDisplayName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, PlanAction.assign);
            },
            child: Text(l10n.assignToStudent),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, PlanAction.copy);
            },
            child: Text(l10n.copyPlan),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context, PlanAction.delete);
            },
            child: Text(l10n.deletePlan),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
}

/// 计划操作枚举
enum PlanAction {
  assign, // 分配
  copy, // 复制
  delete, // 删除
}

