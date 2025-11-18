import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/widgets/keyboard_adaptive_padding.dart';
import 'package:coach_x/core/widgets/video_upload_section.dart';
import 'package:coach_x/core/enums/video_source.dart';
import 'package:coach_x/core/models/video_upload_state.dart';
import 'package:coach_x/core/services/auth_service.dart';
import '../../data/models/exercise_template_model.dart';
import '../providers/exercise_library_providers.dart';
import 'tag_selector.dart';
import 'image_upload_grid.dart';

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
  List<VideoUploadState> _initialVideos = [];
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

      // 构建初始视频状态列表（包含缩略图信息）
      _initialVideos = [];
      for (int i = 0; i < _videoUrls.length; i++) {
        _initialVideos.add(
          VideoUploadState.completed(
            _videoUrls[i],
            thumbnailUrl: i < _thumbnailUrls.length ? _thumbnailUrls[i] : null,
          ),
        );
      }
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
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                  vertical: AppDimensions.spacingS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditMode ? l10n.editExercise : l10n.createExercise,
                      style: AppTextStyles.callout.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const CupertinoActivityIndicator()
                          : Text(
                              l10n.save,
                              style: AppTextStyles.buttonMedium.copyWith(
                                color: AppColors.primaryAction,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1),

              // Body (可滚动)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 动作名称（必填）
                      Text(l10n.exerciseName, style: AppTextStyles.callout),
                      const SizedBox(height: AppDimensions.spacingS),
                      CupertinoTextField(
                        controller: _nameController,
                        placeholder: l10n.exerciseNameHint,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.dividerLight,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 标签选择（必填）
                      TagSelector(
                        selectedTags: _selectedTags,
                        availableTags: tags,
                        onTagsChanged: (newTags) {
                          setState(() {
                            _selectedTags = newTags;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 指导视频（支持多视频）
                      VideoUploadSection(
                        storagePathPrefix:
                            'exercise_videos/${AuthService.currentUserId}/',
                        maxVideos: 5,
                        maxSeconds: 300,
                        videoSource: VideoSource.galleryOnly,
                        cardWidth: 160,
                        cardHeight: 120,
                        initialVideos: _initialVideos,
                        onUploadCompleted: (index, videoUrl, thumbnailUrl) {
                          setState(() {
                            if (index >= _videoUrls.length) {
                              _videoUrls.add(videoUrl);
                              _thumbnailUrls.add(thumbnailUrl ?? '');
                            } else {
                              _videoUrls[index] = videoUrl;
                              _thumbnailUrls[index] = thumbnailUrl ?? '';
                            }
                          });
                        },
                        onVideoDeleted: (index) {
                          setState(() {
                            if (index < _videoUrls.length) {
                              _videoUrls.removeAt(index);
                              _thumbnailUrls.removeAt(index);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 文字说明
                      Text(l10n.textGuidance, style: AppTextStyles.callout),
                      const SizedBox(height: AppDimensions.spacingS),
                      CupertinoTextField(
                        controller: _textGuidanceController,
                        placeholder: l10n.textGuidanceHint,
                        maxLines: 5,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.dividerLight,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 辅助图片（可折叠）
                      ImageUploadGrid(
                        imageUrls: _imageUrls,
                        onImagesChanged: (urls) {
                          setState(() {
                            _imageUrls = urls;
                          });
                        },
                      ),
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
