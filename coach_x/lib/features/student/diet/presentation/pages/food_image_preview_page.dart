import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/routes/route_names.dart';
import '../widgets/food_analysis_bottom_sheet.dart';
import '../../data/models/food_record_mode.dart';

/// 食物图片预览页面
/// 用户拍照后预览图片，并选择记录模式（AI 分析 / 手动记录）
class FoodImagePreviewPage extends ConsumerWidget {
  final String imagePath;

  const FoodImagePreviewPage({super.key, required this.imagePath});

  /// 显示食物分析 Bottom Sheet
  Future<void> _showAnalysisSheet(
    BuildContext context,
    FoodRecordMode mode,
  ) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => FoodAnalysisBottomSheet(
        imagePath: imagePath,
        recordMode: mode,
        onComplete: () {
          // 保存成功后，导航到主页（会清理整个页面栈）
          context.go(RouteNames.studentHome);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: AppColors.primaryText),
        ),
        middle: Text(l10n.previewPhoto, style: AppTextStyles.navTitle),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 图片预览区域
            Expanded(
              child: Container(
                color: AppColors.backgroundWhite,
                child: Center(
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),

            // 底部按钮区域
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: const BoxDecoration(
                color: AppColors.backgroundWhite,
                border: Border(
                  top: BorderSide(color: AppColors.dividerLight, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // AI 分析按钮
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.primaryColor,
                      onPressed: () =>
                          _showAnalysisSheet(context, FoodRecordMode.aiScanner),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingM,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      child: Text(
                        l10n.aiAnalysis,
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacingM),

                  // 手动记录按钮
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.backgroundWhite,
                      onPressed: () => _showAnalysisSheet(
                        context,
                        FoodRecordMode.simpleRecord,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingM,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      child: Text(
                        l10n.manualRecord,
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
