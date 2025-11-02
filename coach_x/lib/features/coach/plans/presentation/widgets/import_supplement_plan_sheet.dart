import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_import_result.dart';

/// 导入补剂计划页面（全屏 Sheet）
///
/// 支持上传图片，导入补剂计划
class ImportSupplementPlanSheet extends ConsumerStatefulWidget {
  final Function(SupplementImportResult) onImportSuccess;

  const ImportSupplementPlanSheet({super.key, required this.onImportSuccess});

  @override
  ConsumerState<ImportSupplementPlanSheet> createState() =>
      _ImportSupplementPlanSheetState();
}

class _ImportSupplementPlanSheetState
    extends ConsumerState<ImportSupplementPlanSheet> {
  File? _selectedImage;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  SupplementImportResult? _result;

  final ImagePicker _picker = ImagePicker();

  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
          _result = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择图片失败: $e';
      });
    }
  }

  /// 上传并识别图片
  Future<void> _uploadAndRecognize() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = '请先选择图片';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // 1. 上传图片到 Firebase Storage
      final imageUrl = await StorageService.uploadSupplementPlanFile(
        file: _selectedImage!,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _isUploading = false;
        _isAnalyzing = true;
      });

      // 2. 调用 AI 识别
      final result = await AIService.importSupplementPlanFromImage(
        imageUrl: imageUrl,
      );

      setState(() {
        _isAnalyzing = false;
        _result = result;
      });

      if (result.isSuccess && result.plan != null) {
        // 识别成功
        widget.onImportSuccess(result);
      } else {
        // 识别失败
        setState(() {
          _errorMessage = result.errorMessage ?? '识别失败';
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isAnalyzing = false;
        _errorMessage = '导入失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 图片预览区域
                    _buildImagePreview(context),

                    const SizedBox(height: 24),

                    // 选择图片按钮
                    if (_selectedImage == null) ...[
                      _buildImageSourceButtons(context),
                    ],

                    // 上传进度
                    if (_isUploading) _buildUploadProgress(context),

                    // 识别进度
                    if (_isAnalyzing) _buildAnalyzingProgress(context),

                    // 错误信息
                    if (_errorMessage != null) _buildErrorMessage(context),

                    // 识别结果
                    if (_result != null && _result!.isSuccess)
                      _buildResultSummary(context),

                    const SizedBox(height: 24),

                    // 上传识别按钮
                    if (_selectedImage != null &&
                        !_isUploading &&
                        !_isAnalyzing)
                      _buildUploadButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '导入补剂计划',
              style: AppTextStyles.title3.copyWith(
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (_selectedImage == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.photo_on_rectangle,
                size: 64,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(height: 16),
              Text(
                '选择补剂计划图片',
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(_selectedImage!, height: 300, fit: BoxFit.cover),
    );
  }

  Widget _buildImageSourceButtons(BuildContext context) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _pickImage(ImageSource.gallery),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.photo_fill,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  '从相册选择',
                  style: AppTextStyles.body.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _pickImage(ImageSource.camera),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera_fill,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                const SizedBox(width: 8),
                Text(
                  '拍摄照片',
                  style: AppTextStyles.body.copyWith(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(width: 12),
              Text(
                '上传中... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _uploadProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 12),
          Text(
            'AI 正在识别图片内容...',
            style: AppTextStyles.callout.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.footnote.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.systemGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '识别成功',
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.systemGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '计划名称: ${_result!.plan?.name ?? "未知"}',
            style: AppTextStyles.footnote.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          Text(
            '天数: ${_result!.plan?.totalDays ?? 0}',
            style: AppTextStyles.footnote.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          Text(
            '置信度: ${(_result!.confidence * 100).toInt()}%',
            style: AppTextStyles.footnote.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          if (_result!.hasWarnings) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ ${_result!.warnings.join(", ")}',
              style: AppTextStyles.caption1.copyWith(
                color: CupertinoColors.systemOrange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _uploadAndRecognize,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.cloud_upload_fill,
              color: CupertinoColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              '上传并识别',
              style: AppTextStyles.body.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
