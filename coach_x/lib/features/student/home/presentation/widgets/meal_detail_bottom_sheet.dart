import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/image_compressor.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';

/// 餐次详情 Bottom Sheet
///
/// 显示和编辑已记录的餐次信息
class MealDetailBottomSheet extends ConsumerStatefulWidget {
  final Meal recordedMeal;
  final Future<void> Function(Meal updatedMeal) onUpdate;

  const MealDetailBottomSheet({
    super.key,
    required this.recordedMeal,
    required this.onUpdate,
  });

  @override
  ConsumerState<MealDetailBottomSheet> createState() =>
      _MealDetailBottomSheetState();
}

class _MealDetailBottomSheetState extends ConsumerState<MealDetailBottomSheet> {
  late Meal _editedMeal;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _editedMeal = widget.recordedMeal;
    _noteController.text = _editedMeal.note;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// 添加图片
  Future<void> _addImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 上传图片到 Storage
      final imageUrl = await _uploadImageToStorage(pickedFile.path);

      if (imageUrl != null) {
        // 上传成功，保存 URL
        setState(() {
          _editedMeal = _editedMeal.copyWith(
            images: [..._editedMeal.images, imageUrl],
          );
        });
      } else if (_uploadError != null && mounted) {
        // 上传失败，显示错误对话框
        await _showUploadError(pickedFile.path);
      }
    }
  }

  /// 删除图片
  void _deleteImage(int index) {
    setState(() {
      final newImages = List<String>.from(_editedMeal.images);
      newImages.removeAt(index);
      _editedMeal = _editedMeal.copyWith(images: newImages);
    });
  }

  /// 上传图片到 Firebase Storage
  Future<String?> _uploadImageToStorage(String imagePath) async {
    String? compressedPath;
    try {
      setState(() {
        _isUploadingImage = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      AppLogger.info('📤 开始压缩和上传餐次图片: $imagePath');

      // 压缩图片（使用用户查看配置）
      compressedPath = await ImageCompressor.compressImageForUser(imagePath);

      // 上传到 Storage
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageFile = File(compressedPath);
      final imageUrl = await StorageService.uploadFileWithRetry(
        imageFile,
        'diet_images/$userId/$timestamp.jpg',
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      AppLogger.info('✅ 餐次图片上传成功: $imageUrl');

      // 清理临时压缩文件
      if (compressedPath != imagePath) {
        try {
          await File(compressedPath).delete();
          AppLogger.info('🗑️ 清理临时压缩文件');
        } catch (e) {
          AppLogger.warning('清理临时文件失败: $e');
        }
      }

      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 1.0;
      });

      return imageUrl;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 餐次图片上传失败', e, stackTrace);

      // 清理临时文件
      if (compressedPath != null && compressedPath != imagePath) {
        try {
          await File(compressedPath).delete();
          AppLogger.info('🗑️ 错误后清理临时压缩文件');
        } catch (e) {
          AppLogger.warning('清理临时文件失败: $e');
        }
      }

      setState(() {
        _isUploadingImage = false;
        _uploadError = e.toString();
      });

      return null;
    }
  }

  /// 显示上传错误对话框
  Future<void> _showUploadError(String imagePath) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.imageUploadFailed),
        content: Text(_uploadError ?? l10n.unknownError),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel, style: AppTextStyles.body),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.retry, style: AppTextStyles.body),
          ),
        ],
      ),
    );

    // 用户选择重试
    if (result == true && mounted) {
      final imageUrl = await _uploadImageToStorage(imagePath);

      if (imageUrl != null) {
        // 重试成功，保存 URL
        setState(() {
          _editedMeal = _editedMeal.copyWith(
            images: [..._editedMeal.images, imageUrl],
          );
        });
      } else if (_uploadError != null && mounted) {
        // 重试仍然失败，再次显示错误
        await _showUploadError(imagePath);
      }
    }
  }

  /// 显示营养数据编辑器
  void _showNutritionEditor() {
    final l10n = AppLocalizations.of(context)!;
    final currentMacros = _editedMeal.macros;

    final caloriesController = TextEditingController(
      text: currentMacros.calories.toStringAsFixed(0),
    );
    final proteinController = TextEditingController(
      text: currentMacros.protein.toStringAsFixed(0),
    );
    final carbsController = TextEditingController(
      text: currentMacros.carbs.toStringAsFixed(0),
    );
    final fatController = TextEditingController(
      text: currentMacros.fat.toStringAsFixed(0),
    );

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.totalNutrition),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: caloriesController,
              placeholder: '${l10n.calories} (kcal)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: proteinController,
              placeholder: '${l10n.protein} (g)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: carbsController,
              placeholder: '${l10n.carbs} (g)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: fatController,
              placeholder: '${l10n.fat} (g)',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel, style: AppTextStyles.body),
          ),
          CupertinoDialogAction(
            onPressed: () {
              // 创建汇总食物项
              final summaryItem = FoodItem(
                food: l10n.nutritionSummary,
                amount: '',
                calories: double.tryParse(caloriesController.text) ?? 0,
                protein: double.tryParse(proteinController.text) ?? 0,
                carbs: double.tryParse(carbsController.text) ?? 0,
                fat: double.tryParse(fatController.text) ?? 0,
                isCustomInput: true,
              );

              setState(() {
                // 替换食物列表为汇总项
                _editedMeal = _editedMeal.copyWith(items: [summaryItem]);
              });

              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.ok, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  /// 保存修改
  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 更新备注
      final finalMeal = _editedMeal.copyWith(note: _noteController.text.trim());

      // 调用更新回调
      await widget.onUpdate(finalMeal);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('保存餐次失败', e);

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text(AppLocalizations.of(context)!.recordSaveFailed),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.ok, style: AppTextStyles.body),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AbsorbPointer(
      absorbing: _isUploadingImage,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Column(
          children: [
            _buildNavigationBar(l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                children: [
                  _buildPhotoPreview(l10n),
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildFoodsList(l10n),
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildTotalMacros(l10n),
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildNoteSection(l10n),
                  const SizedBox(height: AppDimensions.spacingXXL),
                ],
              ),
            ),
            _buildSaveButton(l10n),
          ],
        ),
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildNavigationBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(_editedMeal.name, style: AppTextStyles.navTitle),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.xmark,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建照片预览区
  Widget _buildPhotoPreview(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.photos,
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        if (_isUploadingImage) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '${l10n.uploadingImage} ${(_uploadProgress * 100).toInt()}%',
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppDimensions.spacingS),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _editedMeal.images.length + 1,
            itemBuilder: (context, index) {
              if (index < _editedMeal.images.length) {
                final imagePath = _editedMeal.images[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: AppDimensions.spacingS),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        child: imagePath.startsWith('http')
                            ? Image.network(
                                imagePath,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(imagePath),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _deleteImage(index),
                          minimumSize: const Size(0, 0),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.errorRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: AppColors.textWhite,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return _buildImagePlaceholder();
              }
            },
          ),
        ),
      ],
    );
  }

  /// 构建图片上传占位符
  Widget _buildImagePlaceholder() {
    final isDisabled = _isUploadingImage;

    return GestureDetector(
      onTap: isDisabled ? null : _addImage,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: AppDimensions.spacingS),
        child: DottedBorder(
          color: isDisabled
              ? AppColors.dividerLight
              : AppColors.textSecondary.withValues(alpha: 0.5),
          strokeWidth: 2,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(AppDimensions.radiusL),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.add,
                size: 40,
                color: isDisabled
                    ? AppColors.dividerLight
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建食物列表区
  Widget _buildFoodsList(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.foodList,
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        if (_editedMeal.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Center(
              child: Text(
                l10n.noFood,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...(_editedMeal.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                border: Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.food} ${item.amount}',
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.macros.calories.toInt()} kcal | '
                    'P:${item.macros.protein.toInt()}g | '
                    'C:${item.macros.carbs.toInt()}g | '
                    'F:${item.macros.fat.toInt()}g',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }

  /// 构建总营养数据区
  Widget _buildTotalMacros(AppLocalizations l10n) {
    final macros = _editedMeal.macros;

    return GestureDetector(
      onTap: _showNutritionEditor,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalNutrition,
                  style: AppTextStyles.callout.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const Icon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem(
                  l10n.calories,
                  '${macros.calories.toInt()}',
                  'kcal',
                ),
                _buildMacroItem(l10n.protein, '${macros.protein.toInt()}', 'g'),
                _buildMacroItem(l10n.carbs, '${macros.carbs.toInt()}', 'g'),
                _buildMacroItem(l10n.fat, '${macros.fat.toInt()}', 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个营养指标
  Widget _buildMacroItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          value,
          style: AppTextStyles.title3.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: AppTextStyles.caption1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建备注区域
  Widget _buildNoteSection(AppLocalizations l10n) {
    return CupertinoTextField(
      controller: _noteController,
      placeholder: l10n.addNotePlaceholder,
      maxLines: 2,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(AppLocalizations l10n) {
    final isDisabled = _isSaving || _isUploadingImage;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: isDisabled ? AppColors.dividerLight : AppColors.primaryColor,
          onPressed: isDisabled ? null : _handleSave,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: _isSaving
              ? const CupertinoActivityIndicator(color: AppColors.textWhite)
              : Text(
                  l10n.saveChanges,
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
        ),
      ),
    );
  }
}
