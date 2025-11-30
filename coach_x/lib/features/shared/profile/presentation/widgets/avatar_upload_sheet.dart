import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/image_compressor.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';

/// Avatar Upload Sheet
///
/// Bottom sheet for uploading and updating user avatar
class AvatarUploadSheet extends ConsumerStatefulWidget {
  /// User ID
  final String userId;

  const AvatarUploadSheet({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<AvatarUploadSheet> createState() => _AvatarUploadSheetState();
}

class _AvatarUploadSheetState extends ConsumerState<AvatarUploadSheet> {
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              l10n.selectAvatarSource,
              style: AppTextStyles.title3,
            ),

            const SizedBox(height: AppDimensions.spacingL),

            // Action Buttons
            _buildActionButtons(l10n),

            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      children: [
        // Camera Option
        _buildActionButton(
          icon: CupertinoIcons.camera,
          title: l10n.takePicture,
          onTap: () => _handleImageSource(ImageSource.camera),
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Gallery Option
        _buildActionButton(
          icon: CupertinoIcons.photo,
          title: l10n.chooseFromGallery,
          onTap: () => _handleImageSource(ImageSource.gallery),
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Cancel Button
        CupertinoButton(
          onPressed: () => context.pop(),
          child: Text(
            l10n.cancel,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build single action button
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.primaryText),
            const SizedBox(width: AppDimensions.spacingM),
            Text(title, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  /// Handle image source selection
  Future<void> _handleImageSource(ImageSource source) async {
    try {
      // Get references BEFORE closing sheet
      final userRepo = ref.read(userRepositoryProvider);
      final l10n = AppLocalizations.of(context)!;
      final navigator = Navigator.of(context);

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        AppLogger.info('User cancelled image selection');
        return;
      }

      if (!mounted) return;

      // Close bottom sheet immediately
      navigator.pop();

      // Show full-screen loading and upload
      await _showUploadingDialogWithCallback(
        pickedFile.path,
        navigator.context,
        userRepo,
        l10n,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to pick image', e, stackTrace);
    }
  }

  /// Show full-screen uploading dialog with proper cleanup
  Future<void> _showUploadingDialogWithCallback(
    String imagePath,
    BuildContext parentContext,
    dynamic userRepo,
    AppLocalizations l10n,
  ) async {
    final completer = Completer<void>();

    // Show loading dialog
    showCupertinoDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Execute upload and auto-close when done
        _executeUpload(
          imagePath,
          userRepo,
          dialogContext,
          l10n,
          completer,
        );

        return CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 20),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.uploadingAvatar,
                style: AppTextStyles.body,
              ),
            ],
          ),
        );
      },
    );

    // Wait for upload to complete
    await completer.future;
  }

  /// Execute upload and close dialog when done
  Future<void> _executeUpload(
    String imagePath,
    dynamic userRepo,
    BuildContext dialogContext,
    AppLocalizations l10n,
    Completer<void> completer,
  ) async {
    try {
      // Upload avatar
      await _uploadAvatar(imagePath, userRepo);

      AppLogger.info('Avatar upload completed, closing dialog');

      // Close loading dialog using dialog's own context
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
        AppLogger.info('Loading dialog closed successfully');
      }

      completer.complete();
    } catch (e, stackTrace) {
      AppLogger.error('Avatar upload error', e, stackTrace);

      // Close loading dialog
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // Show error dialog
      if (dialogContext.mounted) {
        await _showErrorDialog(e.toString(), dialogContext, l10n);
      }

      completer.completeError(e);
    }
  }

  /// Upload avatar to Storage
  Future<void> _uploadAvatar(String imagePath, dynamic userRepo) async {
    // Step 1: Compress image
    AppLogger.info('Compressing avatar image: $imagePath');

    final compressedPath = await ImageCompressor.compressImageForUser(
      imagePath,
    );

    AppLogger.info('Compressed image: $compressedPath');

    // Step 2: Upload to Storage
    final compressedFile = File(compressedPath);
    final storagePath =
        'avatars/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final downloadUrl = await StorageService.uploadFileWithRetry(
      compressedFile,
      storagePath,
    );

    AppLogger.info('Avatar uploaded successfully: $downloadUrl');

    // Step 3: Update user avatarUrl
    await _updateUserAvatar(downloadUrl, userRepo);

    // Step 4: Clean up temporary files
    try {
      if (compressedPath != imagePath) {
        await File(compressedPath).delete();
      }
      AppLogger.info('Cleaned up temporary files');
    } catch (e) {
      AppLogger.warning('Failed to clean up temporary files: $e');
    }
  }

  /// Update user avatarUrl in Firestore
  Future<void> _updateUserAvatar(String avatarUrl, dynamic userRepo) async {
    try {
      await userRepo.updateUser(widget.userId, <String, dynamic>{
        'avatarUrl': avatarUrl,
      });

      AppLogger.info('Updated user avatarUrl in Firestore');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user avatarUrl', e, stackTrace);
      rethrow;
    }
  }

  /// Show error dialog
  Future<void> _showErrorDialog(
    String errorMessage,
    BuildContext dialogContext,
    AppLocalizations l10n,
  ) async {
    await showCupertinoDialog(
      context: dialogContext,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.uploadFailed),
        content: Text(errorMessage),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.confirm, style: AppTextStyles.body),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
