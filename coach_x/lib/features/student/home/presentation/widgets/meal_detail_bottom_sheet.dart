import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
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
      setState(() {
        _editedMeal = _editedMeal.copyWith(
          images: [..._editedMeal.images, pickedFile.path],
        );
      });
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
            child: Text(l10n.cancel),
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
            child: Text(l10n.ok),
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
                child: Text(AppLocalizations.of(context)!.ok),
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

    return Container(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.photos,
              style: AppTextStyles.callout.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addImage,
              child: const Icon(
                CupertinoIcons.add_circled,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        if (_editedMeal.images.isEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Center(
              child: Text(
                l10n.noPhotos,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _editedMeal.images.length,
              itemBuilder: (context, index) {
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
                          onPressed: () => _deleteImage(index), minimumSize: Size(0, 0),
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
              },
            ),
          ),
      ],
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
          color: _isSaving ? AppColors.dividerLight : AppColors.primaryColor,
          onPressed: _isSaving ? null : _handleSave,
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
