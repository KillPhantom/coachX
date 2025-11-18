import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/student_detail_model.dart';

/// AI Progress Summary Dialog
///
/// 自定义弹窗组件，显示学生的AI进度总结
class AISummaryDialog extends StatelessWidget {
  final AISummary aiSummary;
  final String studentName;

  const AISummaryDialog({
    super.key,
    required this.aiSummary,
    required this.studentName,
  });

  /// 显示Dialog的静态方法
  static void show(
    BuildContext context,
    AISummary aiSummary,
    String studentName,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: CupertinoColors.black.withValues(alpha: 0.3),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: AISummaryDialog(
              aiSummary: aiSummary,
              studentName: studentName,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 背景模糊层
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Dialog 内容
          Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击穿透到背景
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(context, l10n),

                    // Divider
                    Container(height: 1, color: AppColors.dividerLight),

                    // Content (可滚动)
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(l10n),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Header（标题 + 关闭按钮）
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 标题
          Expanded(
            child: Text(
              l10n.aiProgressSummary,
              style: AppTextStyles.title3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // 关闭按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(), minimumSize: Size(28, 28),
            child: const Icon(
              CupertinoIcons.xmark_circle,
              size: 28,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Summary 文本
        Text(
          aiSummary.content,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // 高亮数据网格（2x2）
        _buildHighlightsGrid(l10n),
      ],
    );
  }

  /// 构建高亮数据网格
  Widget _buildHighlightsGrid(AppLocalizations l10n) {
    return Column(
      children: [
        // 第一行
        Row(
          children: [
            Expanded(
              child: _buildHighlightItem(
                value: aiSummary.highlights.trainingVolumeChange,
                label: l10n.trainingVolume,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHighlightItem(
                value: aiSummary.highlights.weightLoss,
                label: l10n.weightLoss,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 第二行
        Row(
          children: [
            Expanded(
              child: _buildHighlightItem(
                value: aiSummary.highlights.avgStrength,
                label: l10n.avgStrength,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHighlightItem(
                value: aiSummary.highlights.adherence,
                label: l10n.adherence,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建单个高亮项
  Widget _buildHighlightItem({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption2.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
