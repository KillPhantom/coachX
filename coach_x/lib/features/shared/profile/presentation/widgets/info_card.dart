import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 信息卡片组件
///
/// 用于包装 Profile 页面的各个信息区块
class InfoCard extends StatelessWidget {
  /// 卡片标题
  final String title;

  /// 卡片内容
  final Widget child;

  /// 右侧操作按钮（可选）
  final Widget? action;

  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.title3,
            ),
            if (action != null) action!,
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // 内容卡片
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: child,
        ),
      ],
    );
  }
}
