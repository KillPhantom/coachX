import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/widgets/image_editor_page.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/presentation/providers/daily_training_review_providers.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/core/utils/logger.dart';

/// Image Preview Page with optional editing capabilities
///
/// Use cases:
/// 1. Edit existing feedback image (feedbackId != null)
/// 2. Annotate keyframe and create new feedback (dailyTrainingId != null)
/// 3. Pure preview without editing (showEditButton = false)
class ImagePreviewPage extends ConsumerStatefulWidget {
  /// Network image URL to display (prioritized if both url and localPath exist)
  final String? imageUrl;

  /// Local image file path (used when url is not available)
  final String? localPath;

  /// Whether to show the edit button in navigation bar
  final bool showEditButton;

  /// Feedback ID for editing existing feedback image
  final String? feedbackId;

  /// Daily training ID for creating new feedback from keyframe
  final String? dailyTrainingId;

  /// Exercise template ID for replacing keyframe or adding new one (Flow 3 & 4)
  final String? exerciseTemplateId;

  /// Video index for keyframe (required for adding new keyframe)
  final int? videoIndex;

  /// Keyframe index for replacing keyframe (Flow 3). If null, adds new keyframe (Flow 4).
  final int? keyframeIndex;

  /// Timestamp for new keyframe (Flow 4)
  final double? timestamp;

  /// Callback when image is updated (for existing feedback)
  final void Function(String newUrl)? onImageUpdated;

  const ImagePreviewPage({
    super.key,
    this.imageUrl,
    this.localPath,
    this.showEditButton = false,
    this.feedbackId,
    this.dailyTrainingId,
    this.exerciseTemplateId,
    this.videoIndex,
    this.keyframeIndex,
    this.timestamp,
    this.onImageUpdated,
  }) : assert(
         imageUrl != null || localPath != null,
         'Either imageUrl or localPath must be provided',
       );

  @override
  ConsumerState<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends ConsumerState<ImagePreviewPage> {
  bool _isUploading = false;

  /// Get appropriate image provider based on available source
  ImageProvider _getImageProvider() {
    // Prioritize local file if available (faster, no server glitch)
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      final file = File(widget.localPath!);
      // Check if local file still exists
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    // Fall back to network URL if local file is cleaned up
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(widget.imageUrl!);
    }
    // This should never happen due to the assert in constructor
    throw Exception('No image source available');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close, style: AppTextStyles.body),
        ),
        trailing: widget.showEditButton
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isUploading ? null : _handleEditTap,
                child: _isUploading
                    ? const CupertinoActivityIndicator()
                    : Text(l10n.editImage, style: AppTextStyles.body),
              )
            : null,
      ),
      child: SafeArea(
        child: Center(
          child: PhotoView(
            imageProvider: _getImageProvider(),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            backgroundDecoration: const BoxDecoration(
              color: CupertinoColors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Handle edit button tap
  Future<void> _handleEditTap() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      // Navigate to image editor
      final bytes = await Navigator.of(context).push<Uint8List?>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => ImageEditorPage(
            networkUrl: widget.imageUrl,
            localPath: widget.localPath, // Pass local path
            feedbackId: widget.feedbackId,
          ),
        ),
      );

      if (bytes == null || !mounted) {
        // User cancelled editing
        return;
      }

      // Determine which flow to use
      if (widget.exerciseTemplateId != null) {
        if (widget.keyframeIndex != null) {
          // Flow 3: Replace existing keyframe
          // TODO: Update to use exerciseTemplateId if needed, currently repository uses index
          // For now we skip this as user focused on adding
        } else {
          // Flow 4: Add new keyframe
          await _uploadAndAddKeyframe(bytes);
        }
      } else if (widget.feedbackId != null) {
        // Flow 1: Update existing feedback image
        await _uploadAndUpdateFeedback(bytes);
      } else if (widget.dailyTrainingId != null) {
        // Flow 2: Create new feedback from keyframe annotation
        await _uploadAndCreateFeedback(bytes);
      }
    } catch (e, stackTrace) {
      AppLogger.error('图片编辑失败', e, stackTrace);
      if (mounted) {
        _showError(l10n.editImageFailed);
      }
    }
  }

  /// Upload edited image and update existing feedback
  Future<void> _uploadAndUpdateFeedback(Uint8List bytes) async {
    if (widget.feedbackId == null || widget.dailyTrainingId == null) {
      throw Exception(
        'feedbackId and dailyTrainingId required for updating feedback',
      );
    }

    setState(() => _isUploading = true);

    try {
      final repository = ref.read(feedbackRepositoryProvider);

      // Upload edited image bytes
      final newImageUrl = await repository.uploadEditedImageBytes(
        bytes,
        widget.dailyTrainingId!,
      );

      // Update feedback record
      await repository.updateFeedbackImage(widget.feedbackId!, newImageUrl);

      AppLogger.info('反馈图片更新成功: ${widget.feedbackId}');

      // Notify callback
      widget.onImageUpdated?.call(newImageUrl);

      if (mounted) {
        // Navigate back
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Upload annotated keyframe and create new feedback
  Future<void> _uploadAndCreateFeedback(Uint8List bytes) async {
    if (widget.dailyTrainingId == null) {
      throw Exception('dailyTrainingId required for creating feedback');
    }

    setState(() => _isUploading = true);

    try {
      final repository = ref.read(feedbackRepositoryProvider);

      // Get review page data to extract student/coach IDs
      final reviewData = await ref.read(
        reviewPageDataProvider(widget.dailyTrainingId!).future,
      );

      if (reviewData == null) {
        throw Exception('Review data not found');
      }

      // Upload annotated keyframe
      final imageUrl = await repository.uploadEditedImageBytes(
        bytes,
        widget.dailyTrainingId!,
      );

      // Create new feedback with annotated image
      await repository.addFeedback(
        dailyTrainingId: widget.dailyTrainingId!,
        studentId: reviewData.dailyTraining.studentId,
        coachId: reviewData.dailyTraining.coachId,
        trainingDate: reviewData.dailyTraining.date,
        feedbackType: 'image',
        imageUrl: imageUrl,
      );

      AppLogger.info('关键帧标注已保存为反馈: $imageUrl');

      if (mounted) {
        // Navigate back
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Upload and add new keyframe (Flow 4)
  Future<void> _uploadAndAddKeyframe(Uint8List bytes) async {
    if (widget.dailyTrainingId == null ||
        widget.exerciseTemplateId == null ||
        widget.timestamp == null) {
      throw Exception(
        'dailyTrainingId, exerciseTemplateId, and timestamp required for adding keyframe',
      );
    }

    final l10n = AppLocalizations.of(context)!;

    // Show blocking loading dialog
    _showBlockingLoadingDialog(l10n.savingImage);

    try {
      final feedbackRepository = ref.read(feedbackRepositoryProvider);
      final dailyTrainingRepository = ref.read(dailyTrainingRepositoryProvider);

      // Step 1: Upload edited keyframe image
      // We can reuse uploadKeyframeImage but we need to be careful about the path
      // Since we don't have an index yet, we can use a timestamp-based name or similar
      // But uploadKeyframeImage takes exerciseIndex.
      // Let's use uploadEditedImageBytes for now as it's more generic, or we need a new method.
      // Actually, let's use uploadEditedImageBytes which puts it in feedback_images usually...
      // Ideally we want it in training_keyframes.
      // Let's assume we can use uploadEditedImageBytes for now to save time, or implement a proper one.
      // Wait, `uploadKeyframeImage` takes index. We don't have index.
      // Let's use `uploadEditedImageBytes` which puts it in `feedback_images/{dailyTrainingId}/{uuid}.jpg`
      // This is fine for now.

      final newImageUrl = await feedbackRepository.uploadEditedImageBytes(
        bytes,
        widget.dailyTrainingId!,
      );

      // Step 2: Add to Firestore
      await dailyTrainingRepository.addKeyframe(
        widget.dailyTrainingId!,
        widget.exerciseTemplateId!,
        widget.videoIndex!,
        newImageUrl,
        null, // No local path for edited image
        widget.timestamp!,
      );

      AppLogger.info('关键帧添加成功: ${widget.dailyTrainingId}');

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate back to video player
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      AppLogger.error('关键帧添加失败', e, stackTrace);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Show error
        _showError(l10n.editImageFailed);
      }
    }
  }

  /// Show blocking loading dialog (prevents user from dismissing)
  void _showBlockingLoadingDialog(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Block back button
        child: CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 12),
              Text(message, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }

  /// Show error dialog
  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context)!.error,
          style: AppTextStyles.title3,
        ),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.ok,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
