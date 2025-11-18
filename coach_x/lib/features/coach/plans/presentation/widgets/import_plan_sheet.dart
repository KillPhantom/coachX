import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/features/coach/plans/data/models/import_result.dart';

/// 导入计划页面（全屏 Sheet）
///
/// 支持上传图片，导入训练计划
class ImportPlanSheet extends ConsumerStatefulWidget {
  final Function(ImportResult) onImportSuccess;

  const ImportPlanSheet({super.key, required this.onImportSuccess});

  @override
  ConsumerState<ImportPlanSheet> createState() => _ImportPlanSheetState();
}

class _ImportPlanSheetState extends ConsumerState<ImportPlanSheet> {
  File? _selectedImage;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  ImportResult? _result;

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
      final imageUrl = await StorageService.uploadTrainingPlanFile(
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
      final result = await AIService.importPlanFromImage(imageUrl: imageUrl);

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
        _errorMessage = '上传失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('导入训练计划'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 说明
                    _buildInstructions(),
                    const SizedBox(height: 24),

                    // 图片预览或选择区域
                    if (_selectedImage == null)
                      _buildImageSelector()
                    else
                      _buildImagePreview(),

                    const SizedBox(height: 24),

                    // 上传进度
                    if (_isUploading) _buildUploadProgress(),

                    // 识别进度
                    if (_isAnalyzing) _buildAnalyzingProgress(),

                    // 错误提示
                    if (_errorMessage != null) _buildErrorMessage(),

                    // 识别结果
                    if (_result != null && _result!.isSuccess)
                      _buildSuccessResult(),
                  ],
                ),
              ),
            ),

            // 底部按钮
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  /// 说明
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '使用说明',
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. 拍摄或选择包含训练计划的图片\n'
            '2. 确保图片清晰，文字可辨认\n'
            '3. AI 将自动识别训练动作、组数、次数\n'
            '4. 识别后可预览并调整计划',
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 图片选择器
  Widget _buildImageSelector() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '选择或拍摄图片',
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.camera, size: 32),
                    const SizedBox(height: 4),
                    Text('拍照', style: AppTextStyles.caption1),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              CupertinoButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.photo, size: 32),
                    const SizedBox(height: 4),
                    Text('相册', style: AppTextStyles.caption1),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 图片预览
  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_selectedImage!),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          onPressed: () => _pickImage(ImageSource.gallery),
          child: Text('重新选择'),
        ),
      ],
    );
  }

  /// 上传进度
  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CupertinoActivityIndicator(),
              const SizedBox(width: 12),
              Text(
                '上传中... ${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _uploadProgress,
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

  /// 识别进度
  Widget _buildAnalyzingProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CupertinoActivityIndicator(),
          const SizedBox(width: 12),
          Text('AI 正在识别...', style: TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  /// 错误提示
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 成功结果
  Widget _buildSuccessResult() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.check_mark_circled, color: AppColors.success),
              const SizedBox(width: 12),
              Text(
                '识别成功',
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '计划名称: ${result.plan?.name ?? "未知"}',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          Text(
            '训练天数: ${result.plan?.totalDays ?? 0} 天',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          Text(
            '置信度: ${(result.confidence * 100).toInt()}%',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          if (result.hasWarnings) ...[
            const SizedBox(height: 12),
            Text(
              '注意事项:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...result.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '• $warning',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 底部按钮
  Widget _buildBottomButtons() {
    final canUpload = _selectedImage != null && !_isUploading && !_isAnalyzing;
    final canConfirm = _result != null && _result!.isSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          if (!canConfirm) ...[
            Expanded(
              child: CupertinoButton(
                color: canUpload ? AppColors.primary : AppColors.divider,
                onPressed: canUpload ? _uploadAndRecognize : null,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  '开始识别',
                  style: TextStyle(
                    color: canUpload
                        ? CupertinoColors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: CupertinoButton(
                color: AppColors.primary,
                onPressed: () {
                  Navigator.of(context).pop();
                  // onImportSuccess 已在识别成功时调用
                },
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                child: const Text(
                  '确认导入',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
