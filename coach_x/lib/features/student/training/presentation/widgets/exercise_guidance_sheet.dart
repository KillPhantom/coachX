import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/exercise_library/data/models/exercise_template_model.dart';
import 'package:coach_x/features/student/training/presentation/providers/exercise_template_providers.dart';
import 'package:coach_x/core/widgets/video_player_dialog.dart';

/// 动作指导内容底部弹窗
///
/// 显示 ExerciseTemplate 的指导视频和文字说明
class ExerciseGuidanceSheet extends ConsumerWidget {
  final String templateId;

  const ExerciseGuidanceSheet({super.key, required this.templateId});

  /// 显示动作指导底部弹窗
  static void show(BuildContext context, String templateId) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ExerciseGuidanceSheet(templateId: templateId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templateAsync = ref.watch(exerciseTemplateProvider(templateId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 标题栏
            _buildHeader(context, l10n),

            // 内容区域
            Expanded(
              child: templateAsync.when(
                data: (template) => template == null
                    ? _buildEmptyState(l10n)
                    : _buildContent(context, l10n, template),
                loading: () => _buildLoadingState(l10n),
                error: (error, stack) => _buildErrorState(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.exerciseGuidance, style: AppTextStyles.title3),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载中状态
  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.loading,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.noGuidanceAvailable,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.loadFailed,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ExerciseTemplateModel template,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 动作名称
          Text(template.name, style: AppTextStyles.title2),

          // 标签
          if (template.tags.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Wrap(
              spacing: AppDimensions.spacingXS,
              runSpacing: AppDimensions.spacingXS,
              children: template.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppDimensions.spacingL),

          // 指导视频
          if (template.videoUrls.isNotEmpty) ...[
            Text(l10n.guidanceVideo, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.spacingS),
            _buildVideoSection(context, template),
            const SizedBox(height: AppDimensions.spacingL),
          ],

          // 文字说明
          if (template.textGuidance != null &&
              template.textGuidance!.isNotEmpty) ...[
            Text(l10n.textGuidance, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.spacingS),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(template.textGuidance!, style: AppTextStyles.body),
            ),
          ],

          // 辅助图片
          if (template.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingL),
            Text(l10n.referenceImages, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppDimensions.spacingS),
            _buildImagesSection(template),
          ],
        ],
      ),
    );
  }

  /// 构建视频区域
  Widget _buildVideoSection(
    BuildContext context,
    ExerciseTemplateModel template,
  ) {
    return GestureDetector(
      onTap: () {
        VideoPlayerDialog.show(context, videoUrls: template.videoUrls);
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 缩略图或占位符
            if (template.thumbnailUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  template.thumbnailUrls.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(
                CupertinoIcons.play_rectangle,
                size: 64,
                color: AppColors.textTertiary,
              ),

            // 播放按钮
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                color: CupertinoColors.white,
                size: 32,
              ),
            ),

            // 视频数量标签（多视频时）
            if (template.videoUrls.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${template.videoUrls.length} videos',
                    style: AppTextStyles.caption1.copyWith(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImagesSection(ExerciseTemplateModel template) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: template.imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            height: 100,
            margin: EdgeInsets.only(
              right: index < template.imageUrls.length - 1
                  ? AppDimensions.spacingS
                  : 0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.backgroundSecondary,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                template.imageUrls[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
