import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import '../providers/students_providers.dart';

/// 筛选BottomSheet
class FilterBottomSheet {
  /// 显示筛选菜单
  static void show(
    BuildContext context, {
    required WidgetRef ref,
    required Function(String?) onFilter,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final plansAsync = ref.read(availablePlansProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return plansAsync.when(
          data: (plans) {
            final exercisePlans = plans['exercise_plans'] ?? [];

            if (exercisePlans.isEmpty) {
              return CupertinoActionSheet(
                title: Text(l10n.filterOptions),
                message: Text(l10n.noTrainingPlans),
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              );
            }

            return CupertinoActionSheet(
              title: Text(l10n.filterOptions),
              message: Text(l10n.filterByTrainingPlan),
              actions: [
                // "全部"选项
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    onFilter(null);
                  },
                  child: Text(l10n.all),
                ),
                // 训练计划列表
                ...exercisePlans.map((plan) {
                  return CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);
                      onFilter(plan['id']);
                    },
                    child: Text(plan['name'] ?? ''),
                  );
                }).toList(),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            );
          },
          loading: () => Container(
            height: 200,
            color: AppColors.backgroundCard,
            child: const Center(child: LoadingIndicator()),
          ),
          error: (error, stack) => CupertinoActionSheet(
            title: Text(l10n.error),
            message: Text('${l10n.loadFailed}: $error'),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ),
        );
      },
    );
  }
}
