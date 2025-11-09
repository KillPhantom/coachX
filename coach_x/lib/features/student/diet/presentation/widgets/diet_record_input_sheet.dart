import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/keyboard_adaptive_padding.dart';
import 'image_upload_section.dart';
import 'comments_input_field.dart';

/// 饮食记录输入底部弹窗
///
/// 用于输入饮食记录的图片、评论等信息
class DietRecordInputSheet extends StatelessWidget {
  final List<String> images;
  final String studentFeedback;
  final bool isLoading;
  final Function(ImageSource) onUpload;
  final ValueChanged<String> onFeedbackChanged;
  final VoidCallback onSave;

  const DietRecordInputSheet({
    super.key,
    required this.images,
    required this.studentFeedback,
    required this.isLoading,
    required this.onUpload,
    required this.onFeedbackChanged,
    required this.onSave,
  });

  /// 显示底部弹窗
  static Future<void> show({
    required BuildContext context,
    required List<String> images,
    required String studentFeedback,
    required bool isLoading,
    required Function(ImageSource) onUpload,
    required ValueChanged<String> onFeedbackChanged,
    required VoidCallback onSave,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => DietRecordInputSheet(
        images: images,
        studentFeedback: studentFeedback,
        isLoading: isLoading,
        onUpload: onUpload,
        onFeedbackChanged: onFeedbackChanged,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KeyboardAdaptivePadding(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部拖拽条
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: AppColors.dividerLight,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                ),

                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片上传区域
                      ImageUploadSection(images: images, onUpload: onUpload),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 评论输入区域
                      Text(
                        l10n.commentsOrQuestions,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      CommentsInputField(
                        value: studentFeedback,
                        onChanged: onFeedbackChanged,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 保存按钮
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: AppColors.primaryColor,
                          onPressed: isLoading ? null : onSave,
                          child: isLoading
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  l10n.saveMealRecord,
                                  style: AppTextStyles.buttonMedium,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
