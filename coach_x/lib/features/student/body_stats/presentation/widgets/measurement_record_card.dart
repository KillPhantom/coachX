import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';
import 'package:coach_x/features/student/body_stats/presentation/providers/body_stats_providers.dart';
import 'package:intl/intl.dart';

/// 测量记录卡片
///
/// 可展开显示详细信息
class MeasurementRecordCard extends ConsumerStatefulWidget {
  /// 测量记录
  final BodyMeasurementModel measurement;

  /// 显示单位
  final String displayUnit;

  const MeasurementRecordCard({
    super.key,
    required this.measurement,
    required this.displayUnit,
  });

  @override
  ConsumerState<MeasurementRecordCard> createState() =>
      _MeasurementRecordCardState();
}

class _MeasurementRecordCardState extends ConsumerState<MeasurementRecordCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(widget.measurement.recordDate);
    final dateStr = DateFormat('MMMM d, yyyy').format(date);
    final weight = widget.measurement.getWeightInUnit(widget.displayUnit);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 折叠状态
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  // 日历图标
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),

                  // 日期和体重
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: AppTextStyles.callout.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${weight.toStringAsFixed(1)} ${widget.displayUnit == 'kg' ? l10n.kg : l10n.lbs}',
                          style: AppTextStyles.subhead.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 展开箭头
                  Icon(
                    _isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // 展开内容
          if (_isExpanded) ...[
            Container(height: 1, color: AppColors.dividerLight),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 体脂率（如有）
                  if (widget.measurement.bodyFat != null) ...[
                    Row(
                      children: [
                        Text(
                          l10n.bodyFat,
                          style: AppTextStyles.subhead.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(
                          '${widget.measurement.bodyFat!.toStringAsFixed(1)}%',
                          style: AppTextStyles.callout.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                  ],

                  // 照片网格
                  if (widget.measurement.photos.isNotEmpty) ...[
                    Text(
                      '${l10n.photos} (${widget.measurement.photos.length})',
                      style: AppTextStyles.subhead.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.measurement.photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppDimensions.spacingS),
                        itemBuilder: (context, index) {
                          final photoUrl = widget.measurement.photos[index];
                          return GestureDetector(
                            onTap: () => _showPhotoGallery(context, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: photoUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.dividerLight,
                                  child: const Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.dividerLight,
                                  child: const Icon(
                                    CupertinoIcons.photo,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                  ],

                  // 操作按钮
                  Row(
                    children: [
                      // 删除按钮
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingS,
                          ),
                          color: AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          onPressed: () => _confirmDelete(context),
                          child: Text(
                            l10n.deleteRecord,
                            style: AppTextStyles.callout.copyWith(
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 显示照片画廊
  void _showPhotoGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => _PhotoGalleryPage(
          photos: widget.measurement.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// 确认删除
  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.confirmDelete),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel, style: AppTextStyles.body),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRecord();
            },
            child: Text(l10n.delete, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  /// 删除记录
  Future<void> _deleteRecord() async {
    final l10n = AppLocalizations.of(context)!;

    final success = await ref
        .read(bodyStatsHistoryProvider.notifier)
        .deleteRecord(widget.measurement.id);

    if (success && mounted) {
      // 显示成功提示
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(l10n.recordDeleted),
          actions: [
            CupertinoDialogAction(
              child: Text(l10n.ok, style: AppTextStyles.body),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }
}

/// 照片画廊页面
class _PhotoGalleryPage extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoGalleryPage({required this.photos, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          // 照片查看器
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(photos[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: photos.length,
            loadingBuilder: (context, event) => const Center(
              child: CupertinoActivityIndicator(color: CupertinoColors.white),
            ),
            pageController: PageController(initialPage: initialIndex),
          ),

          // 关闭按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Align(
                alignment: Alignment.topRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingS),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
