import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/theme/app_dimensions.dart';
import 'package:coach_x/core/widgets/custom_text_field.dart';
import 'package:coach_x/core/utils/validation_utils.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/student/chat/presentation/controllers/connect_coach_controller.dart';

/// 连接教练弹窗
class ConnectCoachModal extends ConsumerStatefulWidget {
  const ConnectCoachModal({super.key});

  @override
  ConsumerState<ConnectCoachModal> createState() => _ConnectCoachModalState();
}

class _ConnectCoachModalState extends ConsumerState<ConnectCoachModal> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 重置状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectCoachControllerProvider.notifier).reset();
    });
  }

  void _handleConnect() {
    if (_formKey.currentState?.validate() ?? false) {
      final code = _codeController.text.trim();
      ref.read(connectCoachControllerProvider.notifier).connectCoach(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(connectCoachControllerProvider);

    // 监听状态变化
    ref.listen<ConnectCoachState>(connectCoachControllerProvider, (previous, next) {
      if (next.status == ConnectCoachStatus.success) {
        // 成功后关闭弹窗
        Navigator.of(context).pop();
        // 显示成功提示
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.connectSuccess),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  l10n.connectCoachModalTitle,
                  style: AppTextStyles.title2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingS),

                // 说明文本
                Text(
                  l10n.connectCoachModalDescription,
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXL),

                // 邀请码输入框
                CustomTextField(
                  controller: _codeController,
                  placeholder: l10n.invitationCodePlaceholder,
                  validator: ValidationUtils.validateInvitationCode,
                  enabled: state.status != ConnectCoachStatus.loading,
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // 错误提示
                if (state.status == ConnectCoachStatus.error &&
                    state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: AppTextStyles.footnote.copyWith(
                        color: CupertinoColors.systemRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                ],

                // 按钮组
                Row(
                  children: [
                    // 取消按钮
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingM,
                        ),
                        color: AppColors.backgroundSecondary,
                        onPressed: state.status == ConnectCoachStatus.loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.cancel,
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),

                    // 连接按钮
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingM,
                        ),
                        color: AppColors.primaryColor,
                        onPressed: state.status == ConnectCoachStatus.loading
                            ? null
                            : _handleConnect,
                        child: state.status == ConnectCoachStatus.loading
                            ? const CupertinoActivityIndicator()
                            : Text(
                                l10n.connect,
                                style: AppTextStyles.buttonMedium,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
