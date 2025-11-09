import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 图片上传区域组件
class ImageUploadSection extends StatelessWidget {
  final List<String> images;
  final Function(ImageSource) onUpload;

  const ImageUploadSection({
    super.key,
    required this.images,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.dividerLight,
                onPressed: () => onUpload(ImageSource.camera),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.camera,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.takePicture, style: AppTextStyles.footnote),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.dividerLight,
                onPressed: () => onUpload(ImageSource.gallery),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.photo,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.uploadImage, style: AppTextStyles.footnote),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '${images.length} images uploaded',
            style: AppTextStyles.caption1,
          ),
        ],
      ],
    );
  }
}
