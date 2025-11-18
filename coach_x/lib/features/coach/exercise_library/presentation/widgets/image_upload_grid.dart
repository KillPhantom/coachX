import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'collapsible_section.dart';
import '../providers/exercise_library_providers.dart';

/// Image Upload Grid - 图片上传网格组件
///
/// 3-2 网格布局（5个槽位），可折叠，串行上传
class ImageUploadGrid extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final ValueChanged<List<String>> onImagesChanged;

  const ImageUploadGrid({
    super.key,
    required this.imageUrls,
    required this.onImagesChanged,
  });

  @override
  ConsumerState<ImageUploadGrid> createState() => _ImageUploadGridState();
}

class _ImageUploadGridState extends ConsumerState<ImageUploadGrid> {
  final List<String> _uploadedUrls = [];
  final Map<int, double> _uploadProgress = {}; // 按槽位索引
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _uploadedUrls.addAll(widget.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CollapsibleSection(
      title: '${l10n.auxiliaryImages} (${l10n.optional})',
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _uploadedUrls.length + (_uploadedUrls.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            // 显示已上传图片
            if (index < _uploadedUrls.length) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildImageSlot(index, _uploadedUrls[index]),
              );
            }

            // 显示上传中状态
            if (_uploadProgress.containsKey(index)) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildUploadingSlot(index),
              );
            }

            // 显示 + placeholder（最后一个）
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildEmptySlot(index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.dividerLight, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.add,
            size: 32,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingSlot(int index) {
    final progress = _uploadProgress[index] ?? 0.0;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.dividerLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CupertinoActivityIndicator.partiallyRevealed(
                progress: progress,
                radius: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).toInt()}%', style: AppTextStyles.caption1),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot(int index, String imageUrl) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _viewImage(imageUrl),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => _deleteImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 14,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    if (_uploadedUrls.length >= 5) return; // 最多5张

    final result = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text(AppLocalizations.of(context)!.takePicture),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text(AppLocalizations.of(context)!.uploadImage),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ),
    );

    if (result != null) {
      final image = await _picker.pickImage(
        source: result,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadImage(index, File(image.path));
      }
    }
  }

  Future<void> _uploadImage(int slotIndex, File imageFile) async {
    setState(() {
      _uploadProgress[slotIndex] = 0.0;
    });

    try {
      final notifier = ref.read(exerciseLibraryNotifierProvider.notifier);
      final imageUrl = await notifier.uploadImage(imageFile);

      setState(() {
        _uploadProgress.remove(slotIndex);
        _uploadedUrls.add(imageUrl);
      });

      widget.onImagesChanged(List.from(_uploadedUrls));
    } catch (e) {
      setState(() {
        _uploadProgress.remove(slotIndex);
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(AppLocalizations.of(context)!.errorOccurred),
            content: Text(e.toString()),
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
  }

  void _deleteImage(int index) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteImageMessage),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              setState(() {
                _uploadedUrls.removeAt(index);
              });
              widget.onImagesChanged(List.from(_uploadedUrls));
              Navigator.pop(context);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => Container(
          color: CupertinoColors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(child: Image.network(imageUrl)),
                ),
                Positioned(
                  top: 8,
                  right: 16,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
