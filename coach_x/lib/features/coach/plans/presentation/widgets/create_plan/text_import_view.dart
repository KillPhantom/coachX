import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/features/coach/plans/data/models/import_result.dart';
import 'package:coach_x/core/services/ocr_service.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 创建训练计划 - 智能文本导入视图
///
/// 设计理念: Extension of Mind
/// 一个类似备忘录的无限画布，用户可以随意粘贴文本或连续扫描图片，
/// 所有内容都会汇聚在这个编辑器中，最后统一解析。
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
  final FocusNode _focusNode = FocusNode();
  bool _isExtracting = false; // OCR 提取中
  bool _isParsing = false; // AI 解析中
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAndExtractText({required ImageSource source}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      _isExtracting = true;
      _errorMessage = null;
    });

    try {
      final extractedText = await OCRService.extractTextFromImage(
        File(image.path),
      );

      if (extractedText.isNotEmpty) {
        setState(() {
          // 如果已有内容，先换行
          if (_textController.text.isNotEmpty) {
            _textController.text += "\n\n";
          }
          _textController.text += extractedText;
          _isExtracting = false;
        });

        // 移动光标到末尾
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );

        // 震动反馈
        HapticFeedback.mediumImpact();
      } else {
        setState(() {
          _isExtracting = false;
          _errorMessage = 'No text found in image';
        });
      }
    } catch (e) {
      AppLogger.error('OCR 提取失败', e);
      setState(() {
        _isExtracting = false;
        _errorMessage = 'OCR extraction failed: $e';
      });
    }
  }

  void _showScanOptions() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickAndExtractText(source: ImageSource.camera);
            },
            child: Text(l10n.takePhoto, style: AppTextStyles.buttonMedium),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickAndExtractText(source: ImageSource.gallery);
            },
            child: Text(l10n.selectFromGallery, style: AppTextStyles.buttonMedium),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: Text(l10n.cancel, style: AppTextStyles.buttonMedium),
        ),
      ),
    );
  }

  void _showExampleFormat() {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(l10n.exampleFormat),
        message: Text(
          l10n.exampleFormatContent,
          style: AppTextStyles.body.copyWith(fontSize: 14),
          textAlign: TextAlign.left,
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.know, style: AppTextStyles.buttonMedium),
        ),
      ),
    );
  }

  void _clearText() {
    final l10n = AppLocalizations.of(context)!;
    if (_textController.text.isEmpty) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.confirmDelete),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: AppTextStyles.buttonMedium),
          ),
          CupertinoDialogAction(
            onPressed: () {
              setState(() {
                _textController.clear();
                _errorMessage = null;
              });
              Navigator.pop(context);
            },
            isDestructiveAction: true,
            child: Text(l10n.delete, style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _parseText() async {
    final textContent = _textController.text.trim();

    if (textContent.isEmpty) return;

    // 收起键盘
    _focusNode.unfocus();

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
    final hasText = _textController.text.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusNode.unfocus(),
      child: Column(
        children: [
        // 1. Editor Area (Canvas)
        Expanded(
          child: Container(
            color: AppColors.cardBackground,
            child: Stack(
              children: [
                CupertinoTextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  placeholder: l10n.pasteOrTypeHere,
                  placeholderStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.5,
                  ),
                  style: AppTextStyles.body.copyWith(height: 1.5),
                  padding: const EdgeInsets.all(20),
                  decoration: null, // No border
                  maxLines: null, // Infinite lines
                  expands: true, // Fill parent
                  textAlignVertical: TextAlignVertical.top,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.sentences,
                ),

                // Loading Overlay
                if (isLoading)
                  Container(
                    color: AppColors.background.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowColor.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CupertinoActivityIndicator(),
                            const SizedBox(width: 12),
                            Text(
                              _isExtracting
                                  ? l10n.extractingText
                                  : l10n.parsingPlan,
                              style: AppTextStyles.callout,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Error Message (if any)
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: CupertinoColors.systemRed.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: CupertinoColors.systemRed,
                  size: 16,
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.systemRed,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _errorMessage = null),
                ),
              ],
            ),
          ),

        // 3. Toolbar & Action Area
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toolbar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Scan Button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isLoading ? null : _showScanOptions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.camera_viewfinder,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.scanImage,
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Example Hint
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: _showExampleFormat,
                        child: const Icon(
                          CupertinoIcons.lightbulb,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),

                      // Clear Button
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: hasText ? _clearText : null,
                        child: Icon(
                          CupertinoIcons.trash,
                          color: hasText
                              ? CupertinoColors.systemRed
                              : AppColors.textTertiary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed:
                          (isLoading || !hasText)
                              ? null
                              : () {
                                // 震动反馈
                                HapticFeedback.mediumImpact();
                                _parseText();
                              },
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      disabledColor: AppColors.primary.withValues(alpha: 0.3),
                      child: Text(
                        l10n.startParsing,
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: (isLoading || !hasText)
                              ? null
                              : CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
