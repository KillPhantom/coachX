import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/import_result.dart';
import 'package:coach_x/core/services/ocr_service.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 创建训练计划 - 文本导入视图
///
/// 支持两种方式：
/// 1. 扫描图片 → OCR 提取文字 → 填充文本框
/// 2. 直接粘贴文本
///
/// 然后调用 AI 解析文本为训练计划
class TextImportView extends ConsumerStatefulWidget {
  final Function(ImportResult) onImportSuccess;

  const TextImportView({
    super.key,
    required this.onImportSuccess,
  });

  @override
  ConsumerState<TextImportView> createState() => _TextImportViewState();
}

class _TextImportViewState extends ConsumerState<TextImportView> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  bool _isExtracting = false; // OCR 提取中
  bool _isParsing = false; // AI 解析中
  String? _errorMessage;
  int _currentTab = 0; // 0: 扫描图片, 1: 粘贴文本

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndExtractText() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
      _isExtracting = true;
      _errorMessage = null;
    });

    try {
      final extractedText = await OCRService.extractTextFromImage(
        File(image.path),
      );

      setState(() {
        _textController.text = extractedText;
        _isExtracting = false;
      });

      _showExtractionSuccessHint();
    } catch (e) {
      AppLogger.error('OCR 提取失败', e);
      setState(() {
        _isExtracting = false;
        _errorMessage = 'OCR extraction failed: $e';
      });
    }
  }

  void _showExtractionSuccessHint() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.success),
        content: Text(l10n.extractionSuccess),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _parseText() async {
    final textContent = _textController.text.trim();

    if (textContent.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or scan text first';
      });
      return;
    }

    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    try {
      final result = await AIService.importPlanFromText(
        textContent: textContent,
      );

      setState(() {
        _isParsing = false;
      });

      if (result.isSuccess && result.plan != null) {
        widget.onImportSuccess(result);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Parsing failed';
        });
      }
    } catch (e) {
      AppLogger.error('文本解析失败', e);
      setState(() {
        _isParsing = false;
        _errorMessage = 'Failed to parse text: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = _isExtracting || _isParsing;

    return Column(
      children: [
        // Content Area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  l10n.textImportTitle,
                  style: AppTextStyles.title2,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.textImportSubtitle,
                  style: AppTextStyles.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Tab Selector
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSegmentedControl<int>(
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.scanImage,
                          style: AppTextStyles.callout,
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.pasteText,
                          style: AppTextStyles.callout,
                        ),
                      ),
                    },
                    groupValue: _currentTab,
                    onValueChanged: (value) {
                      setState(() {
                        _currentTab = value;
                        _errorMessage = null;
                      });
                    },
                    selectedColor: AppColors.primary,
                    unselectedColor: AppColors.cardBackground,
                    borderColor: AppColors.divider,
                  ),
                ),
                const SizedBox(height: 24),

                // Content based on tab
                if (_currentTab == 0) ...[
                  // Scan Image Tab
                  if (_selectedImage != null) ...[
                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pick Image Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed: isLoading ? null : _pickAndExtractText,
                      color: AppColors.secondaryBlue,
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                        _selectedImage == null
                            ? l10n.selectImageToScan
                            : l10n.selectAnotherImage,
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Text Input (always visible)
                Text(
                  l10n.extractedOrPastedText,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: CupertinoTextField(
                    controller: _textController,
                    placeholder: l10n.pasteOrTypeHere,
                    placeholderStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    style: AppTextStyles.body,
                    maxLines: 10,
                    minLines: 8,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(),
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(height: 16),

                // Example Format
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.exampleFormat,
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.exampleFormatContent,
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(width: 8),
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
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading Indicator
                if (isLoading) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(width: 12),
                      Text(
                        _isExtracting
                            ? l10n.extractingText
                            : l10n.parsingPlan,
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Parse Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: isLoading ? null : _parseText,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    disabledColor: AppColors.divider,
                    child: Text(
                      l10n.startParsing,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
