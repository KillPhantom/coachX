import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/keyboard_adaptive_padding.dart';
import 'package:coach_x/core/services/auth_service.dart';
import '../../data/models/exercise_template_model.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/providers/exercise_library_providers.dart';
import 'package:coach_x/features/coach/exercise_library/data/models/exercise_tag_model.dart';
import 'package:coach_x/features/coach/exercise_library/presentation/widgets/tag_selector.dart';
import 'unified_media_upload_section.dart';

/// Create Exercise Sheet - 创建/编辑动作底部弹窗
///
/// 支持创建和编辑两种模式
class CreateExerciseSheet extends ConsumerStatefulWidget {
  final ExerciseTemplateModel? template; // null = 创建模式，非null = 编辑模式

  const CreateExerciseSheet({super.key, this.template});

  /// 显示弹窗
  static Future<void> show(
    BuildContext context, {
    ExerciseTemplateModel? template,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CreateExerciseSheet(template: template),
    );
  }

  @override
  ConsumerState<CreateExerciseSheet> createState() =>
      _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends ConsumerState<CreateExerciseSheet> {
  late TextEditingController _nameController;
  late TextEditingController _textGuidanceController;
  List<String> _selectedTags = [];
  List<String> _videoUrls = [];
  List<String> _thumbnailUrls = [];
  List<String> _imageUrls = [];
  bool _isSaving = false;

  bool get _isEditMode => widget.template != null;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _textGuidanceController = TextEditingController(
      text: widget.template?.textGuidance ?? '',
    );

    // 预填充数据（编辑模式）
    if (_isEditMode) {
      _selectedTags = List.from(widget.template!.tags);
      _videoUrls = List.from(widget.template!.videoUrls);
      _thumbnailUrls = List.from(widget.template!.thumbnailUrls);
      _imageUrls = List.from(widget.template!.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textGuidanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = ref.watch(exerciseTagsProvider);

    return KeyboardAdaptivePadding(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 顶部拖拽条
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 0) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  color: Colors.transparent, // Expand hit test area
                  width: double.infinity,
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
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                  vertical: AppDimensions.spacingS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 动作名称（Title Style）
                    Expanded(
                      child: CupertinoTextField(
                        controller: _nameController,
                        placeholder: 'Exercise Name',
                        placeholderStyle: AppTextStyles.title3.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        style: AppTextStyles.title3,
                        padding: EdgeInsets.zero,
                        decoration: null, // No border
                        cursorColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const CupertinoActivityIndicator()
                          : Text(
                              l10n.save,
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: AppColors.primaryAction,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Body (可滚动)
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标签选择（Dynamic + Allow Add）
                      TagSelector(
                        selectedTags: _selectedTags,
                        availableTags: [
                          ...tags,
                          // Ensure selected tags are visible even if not in availableTags
                          ..._selectedTags
                              .where((tag) => !tags.any((t) => t.name == tag))
                              .map((name) => ExerciseTagModel(
                                    id: name, // Use name as ID for temp tags
                                    name: name,
                                    createdAt: DateTime.now(),
                                  )),
                        ],
                        allowAdd: true,
                        showTitle: false,
                        onTagsChanged: (newTags) {
                          setState(() {
                            _selectedTags = newTags;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingM),

                      // Unified Media Section
                      UnifiedMediaUploadSection(
                        initialVideoUrls: _videoUrls,
                        initialThumbnailUrls: _thumbnailUrls,
                        initialImageUrls: _imageUrls,
                        onVideoUrlsChanged: (urls) => _videoUrls = urls,
                        onThumbnailUrlsChanged: (urls) => _thumbnailUrls = urls,
                        onImageUrlsChanged: (urls) => _imageUrls = urls,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),

                      // 文字说明 (Highlighted)
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingS),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoTextField(
                          controller: _textGuidanceController,
                          placeholder: 'Add detailed guidance...',
                          placeholderStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          style: AppTextStyles.body.copyWith(fontSize: 14),
                          maxLines: 5,
                          minLines: 3,
                          padding: EdgeInsets.zero,
                          decoration: null,
                          cursorColor: AppColors.primaryColor,
                        ),
                      ),
                      
                      // Bottom Padding
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    // 验证必填项
    if (_nameController.text.trim().isEmpty) {
      _showError(l10n.pleaseEnterName);
      return;
    }

    // Tags are optional now? User said "change the tag to only keep Strength / Cardio". 
    // Usually tags are required, but let's keep it required for now.
    if (_selectedTags.isEmpty) {
      _showError(l10n.atLeastOneTag);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final now = DateTime.now();

      if (_isEditMode) {
        // 编辑模式：更新模板
        final data = {
          'name': _nameController.text.trim(),
          'tags': _selectedTags,
          'videoUrls': _videoUrls,
          'thumbnailUrls': _thumbnailUrls,
          'textGuidance': _textGuidanceController.text.trim(),
          'imageUrls': _imageUrls,
          'updatedAt': now,
        };

        await ref
            .read(exerciseLibraryNotifierProvider.notifier)
            .updateTemplate(widget.template!.id, data);

        if (mounted) {
          Navigator.pop(context);
          _showSuccess(l10n.updateSuccess);
        }
      } else {
        // 创建模式：新建模板
        final template = ExerciseTemplateModel(
          id: '', // Repository 会生成
          ownerId: userId,
          name: _nameController.text.trim(),
          tags: _selectedTags,
          textGuidance: _textGuidanceController.text.trim(),
          imageUrls: _imageUrls,
          videoUrls: _videoUrls,
          thumbnailUrls: _thumbnailUrls,
          createdAt: now,
          updatedAt: now,
        );

        await ref
            .read(exerciseLibraryNotifierProvider.notifier)
            .createTemplate(template);

        if (mounted) {
          Navigator.pop(context);
          _showSuccess(l10n.createSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.errorOccurred),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
