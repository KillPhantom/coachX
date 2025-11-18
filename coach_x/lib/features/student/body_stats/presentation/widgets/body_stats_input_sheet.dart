import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/image_compressor.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/keyboard_adaptive_padding.dart';
import 'package:coach_x/features/student/body_stats/presentation/widgets/photo_thumbnail.dart';
import 'package:coach_x/features/student/body_stats/presentation/providers/body_stats_providers.dart';

/// 身体数据输入底部弹窗
///
/// 用于输入体重、体脂率等信息
class BodyStatsInputSheet extends ConsumerStatefulWidget {
  /// 完成回调
  final VoidCallback onComplete;

  const BodyStatsInputSheet({super.key, required this.onComplete});

  @override
  ConsumerState<BodyStatsInputSheet> createState() =>
      _BodyStatsInputSheetState();
}

class _BodyStatsInputSheetState extends ConsumerState<BodyStatsInputSheet> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  /// 选择照片
  Future<void> _pickImage(ImageSource source) async {
    try {
      // 步骤1: 使用 ImagePicker 获取原始图片
      final XFile? image = await _imagePicker.pickImage(source: source);

      if (image != null) {
        String? compressedPath;
        try {
          // 步骤2: 使用 ImageCompressor 压缩图片
          compressedPath = await ImageCompressor.compressImage(
            image.path,
            quality: 85,
            maxWidth: 1920,
            maxHeight: 1920,
          );

          // 步骤3: 添加压缩后的图片路径
          ref.read(bodyStatsRecordProvider.notifier).addPhoto(compressedPath);

          AppLogger.info('✅ 身体照片压缩并添加成功');
        } catch (e, stackTrace) {
          AppLogger.error('❌ 身体照片压缩失败', e, stackTrace);
          // 压缩失败时，使用原始图片（fallback）
          ref.read(bodyStatsRecordProvider.notifier).addPhoto(image.path);
          AppLogger.warning('⚠️ 使用原始图片（未压缩）');
        }
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        _showError(context, e.toString());
      }
    }
  }

  /// 保存记录
  Future<void> _saveRecord() async {
    final l10n = AppLocalizations.of(context)!;

    // 验证并设置体重
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _showError(context, l10n.enterWeight);
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      _showError(context, l10n.enterWeight);
      return;
    }

    ref.read(bodyStatsRecordProvider.notifier).setWeight(weight);

    // 设置体脂率（可选）
    final bodyFatText = _bodyFatController.text.trim();
    if (bodyFatText.isNotEmpty) {
      final bodyFat = double.tryParse(bodyFatText);
      if (bodyFat != null && bodyFat >= 0 && bodyFat <= 100) {
        ref.read(bodyStatsRecordProvider.notifier).setBodyFat(bodyFat);
      }
    }

    // 生成今天的日期
    final recordDate = DateTime.now().toIso8601String().split('T')[0];

    // 检查今天是否已有记录
    final existingId = await ref
        .read(bodyStatsRecordProvider.notifier)
        .checkExistingRecord(recordDate);

    bool success = false;

    if (existingId != null && mounted) {
      // 已有记录，显示确认对话框
      final confirmed = await _showOverrideConfirmation(context, recordDate);
      if (!confirmed) return;

      // 用户确认，更新记录
      success = await ref
          .read(bodyStatsRecordProvider.notifier)
          .updateRecord(existingId);
    } else {
      // 没有记录，正常保存
      success = await ref.read(bodyStatsRecordProvider.notifier).saveRecord();
    }

    if (success && mounted) {
      // 关闭弹窗
      Navigator.pop(context);
      // 调用完成回调
      widget.onComplete();
    } else {
      // 显示错误
      final state = ref.read(bodyStatsRecordProvider);
      if (state.errorMessage != null && mounted) {
        _showError(context, state.errorMessage!);
      }
    }
  }

  /// 显示错误对话框
  void _showError(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 显示覆盖确认对话框
  Future<bool> _showOverrideConfirmation(
    BuildContext context,
    String recordDate,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.recordExistsTitle),
        content: Text(l10n.recordExistsMessage(recordDate)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.replace),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(bodyStatsRecordProvider);

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

                // 标题
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingL,
                    vertical: AppDimensions.spacingS,
                  ),
                  child: Text(
                    l10n.recordBodyStats,
                    style: AppTextStyles.title3,
                  ),
                ),

                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 照片区域
                      if (state.photos.isNotEmpty) ...[
                        Text(
                          '${l10n.photos} (${state.photos.length}/3)',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.photos.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppDimensions.spacingS),
                            itemBuilder: (context, index) {
                              if (index < state.photos.length) {
                                // 已有照片
                                return PhotoThumbnail(
                                  localPath: state.photos[index],
                                  onDelete: () {
                                    ref
                                        .read(bodyStatsRecordProvider.notifier)
                                        .removePhoto(index);
                                  },
                                );
                              } else if (!state.isPhotosLimitReached) {
                                // 添加照片按钮
                                return GestureDetector(
                                  onTap: () => _showPhotoOptions(context),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.dividerLight,
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusM,
                                      ),
                                      border: Border.all(
                                        color: AppColors.primaryColor,
                                        width: 1.5,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.plus,
                                      color: AppColors.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                      ],

                      // 体重输入
                      Text('${l10n.weight} *', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _weightController,
                              placeholder: l10n.enterWeight,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              padding: const EdgeInsets.all(
                                AppDimensions.spacingM,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                                border: Border.all(
                                  color: AppColors.dividerLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text(
                            state.weightUnit == 'kg' ? l10n.kg : l10n.lbs,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 体脂率输入（可选）
                      Text(
                        l10n.bodyFatOptional,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      CupertinoTextField(
                        controller: _bodyFatController,
                        placeholder: l10n.enterBodyFat,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),

                      // 保存按钮
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingM,
                          ),
                          onPressed: state.isLoading ? null : _saveRecord,
                          child: state.isLoading
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : Text(
                                  l10n.save,
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: AppColors.primaryText,
                                  ),
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

  /// 显示照片选择选项
  void _showPhotoOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: Text(l10n.takePhoto),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Text(l10n.uploadPhoto),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }
}
