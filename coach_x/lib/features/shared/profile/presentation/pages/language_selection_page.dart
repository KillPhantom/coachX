import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/providers/locale_providers.dart';
import 'package:coach_x/core/services/locale_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 语言选择页面
///
/// 用户可以从列表中选择应用语言（English / 中文）
class LanguageSelectionPage extends ConsumerWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(languageCodeProvider) ?? 'en';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundLight,
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.selectLanguage),
        backgroundColor: AppColors.backgroundLight,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
          child: CupertinoListSection.insetGrouped(
            backgroundColor: AppColors.backgroundLight,
            children: [
              // English
              CupertinoListTile(
                title: Text(
                  l10n.languageEnglish,
                  style: AppTextStyles.body,
                ),
                trailing: currentLanguage.startsWith('en')
                    ? Icon(
                        CupertinoIcons.checkmark_alt,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () => _handleLanguageChange(context, ref, 'en'),
              ),

              // 中文
              CupertinoListTile(
                title: Text(
                  l10n.languageChinese,
                  style: AppTextStyles.body,
                ),
                trailing: currentLanguage.startsWith('zh')
                    ? Icon(
                        CupertinoIcons.checkmark_alt,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () => _handleLanguageChange(context, ref, 'zh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理语言切换
  Future<void> _handleLanguageChange(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
  ) async {
    // 如果选择的是当前语言，直接返回
    final currentLanguage = ref.read(languageCodeProvider) ?? 'en';
    if (currentLanguage.startsWith(languageCode)) {
      if (context.mounted) {
        context.pop();
      }
      return;
    }

    try {
      // 调用服务更新语言
      await LocaleService.updateUserLanguage(languageCode);

      // 更新成功，刷新用户数据（Provider 会自动更新 UI）
      if (context.mounted) {
        // 稍微延迟一下让数据同步
        await Future.delayed(const Duration(milliseconds: 300));
        context.pop();
      }
    } catch (e) {
      AppLogger.error('切换语言失败', e);

      if (context.mounted) {
        // 显示错误提示
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(AppLocalizations.of(context)!.errorOccurred),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: Text(AppLocalizations.of(context)!.confirm),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }
}
