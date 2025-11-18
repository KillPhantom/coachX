import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/widgets/dismiss_keyboard.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../providers/students_providers.dart';
import 'invitation_code_item.dart';

/// 邀请码管理Dialog
class InvitationCodeDialog extends ConsumerStatefulWidget {
  const InvitationCodeDialog({super.key});

  @override
  ConsumerState<InvitationCodeDialog> createState() =>
      _InvitationCodeDialogState();

  /// 显示Dialog
  static void show(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const InvitationCodeDialog(),
    );
  }
}

class _InvitationCodeDialogState extends ConsumerState<InvitationCodeDialog> {
  final _totalDaysController = TextEditingController(text: '180');
  final _noteController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _totalDaysController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final codesAsync = ref.watch(invitationCodesProvider);

    return CupertinoPopupSurface(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: SafeArea(
          child: DismissKeyboard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和关闭按钮
                _buildHeader(l10n),

                const SizedBox(height: AppDimensions.spacingL),

                // 说明
                Text(
                  l10n.invitationCodeDescription,
                  style: AppTextStyles.subhead,
                ),

                const SizedBox(height: AppDimensions.spacingL),

                // 输入区域
                _buildInputSection(l10n),

                const SizedBox(height: AppDimensions.spacingL),

                // 分割线
                Container(height: 1, color: AppColors.dividerLight),

                const SizedBox(height: AppDimensions.spacingL),

                // 现有邀请码列表
                Text(
                  l10n.existingInvitationCodes,
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppDimensions.spacingM),

                Expanded(
                  child: codesAsync.when(
                    data: (codes) {
                      if (codes.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.noInvitationCodes,
                            style: AppTextStyles.subhead,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: codes.length,
                        itemBuilder: (context, index) {
                          return InvitationCodeItem(code: codes[index]);
                        },
                      );
                    },
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        '${l10n.loadFailed}: $error',
                        style: AppTextStyles.subhead.copyWith(
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.invitationCodeManagement, style: AppTextStyles.title3),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.xmark_circle,
            size: 28,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建输入区域
  Widget _buildInputSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 签约时长输入
          Text(l10n.contractDurationDays, style: AppTextStyles.footnote),
          const SizedBox(height: AppDimensions.spacingS),
          CupertinoTextField(
            controller: _totalDaysController,
            placeholder: l10n.exampleDays,
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // 备注输入
          Text(l10n.remarkOptional, style: AppTextStyles.footnote),
          const SizedBox(height: AppDimensions.spacingS),
          CupertinoTextField(
            controller: _noteController,
            placeholder: l10n.remarkExample,
            maxLines: 2,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // 生成按钮
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.primaryAction,
              onPressed: _isGenerating ? null : _generateCode,
              child: _isGenerating
                  ? const CupertinoActivityIndicator(color: AppColors.textWhite)
                  : Text(
                      l10n.generateInvitationCode,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生成邀请码
  Future<void> _generateCode() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // 验证输入
    final totalDaysStr = _totalDaysController.text.trim();
    if (totalDaysStr.isEmpty) {
      _showError(l10n.pleaseEnterContractDuration);
      return;
    }

    final totalDays = int.tryParse(totalDaysStr);
    if (totalDays == null || totalDays < 1 || totalDays > 365) {
      _showError(l10n.contractDurationRangeError);
      return;
    }

    final note = _noteController.text.trim();

    setState(() => _isGenerating = true);

    try {
      final repository = ref.read(invitationCodeRepositoryProvider);
      await repository.generateInvitationCode(totalDays: totalDays, note: note);

      // 清空输入
      _noteController.clear();

      // 刷新列表
      ref.invalidate(invitationCodesProvider);

      // 显示简短的成功提示（不阻塞界面）
      if (mounted) {
        // 使用Snackbar风格的提示，不干扰用户查看新生成的邀请码
        _showSuccessToast();
      }
    } catch (e) {
      _showError('${l10n.generateFailed}: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.confirm),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 显示成功提示（Toast风格）
  void _showSuccessToast() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // 使用OverlayEntry显示临时提示
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: AppDimensions.spacingL,
        right: AppDimensions.spacingL,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.successGreen,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: AppColors.textWhite,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Text(
                l10n.invitationCodeGenerated,
                style: AppTextStyles.body.copyWith(color: AppColors.textWhite),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 2秒后自动移除
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
