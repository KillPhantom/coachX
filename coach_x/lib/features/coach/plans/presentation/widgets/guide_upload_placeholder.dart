import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';

/// 上传指导图片/视频占位组件
/// 预留功能，暂不实现实际上传逻辑
class GuideUploadPlaceholder extends StatelessWidget {
  final VoidCallback? onTap;

  const GuideUploadPlaceholder({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap ?? _showPlaceholderDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.cloud_upload,
              size: 40,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 8),
            Text(
              '上传指导图片或视频',
              style: AppTextStyles.footnote.copyWith(
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '功能预留，暂未实现',
              style: AppTextStyles.caption1.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示占位对话框
  void _showPlaceholderDialog() {
    // 在实际组件使用时，通过上下文传递来显示对话框
    // 此处仅为占位方法
  }

  /// 显示占位对话框（静态方法，供外部调用）
  static void showPlaceholderDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('功能预留'),
        content: const Text('图片和视频上传功能已预留接口，将在后续版本中实现。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('知道了'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}




