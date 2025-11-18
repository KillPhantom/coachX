import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class CompletionFeedItem extends StatelessWidget {
  final VoidCallback onClose;

  const CompletionFeedItem({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 完成图标
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.2),
            ),
            child: const Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // 标题
          Text(
            '批阅完成',
            style: AppTextStyles.largeTitle.copyWith(
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: 12),

          // 描述
          Text(
            '所有训练内容已批阅完成',
            style: AppTextStyles.body.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 48),

          // 关闭按钮
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            onPressed: onClose,
            child: Text(
              '返回',
              style: AppTextStyles.buttonLarge.copyWith(
                color: CupertinoColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
