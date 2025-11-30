import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/unit_converter.dart';

/// 身高编辑对话框
class EditHeightDialog extends StatefulWidget {
  final double? currentHeight; // cm
  final bool isMetric;
  final Future<void> Function(double newHeight) onSave;

  const EditHeightDialog({
    super.key,
    this.currentHeight,
    required this.isMetric,
    required this.onSave,
  });

  @override
  State<EditHeightDialog> createState() => _EditHeightDialogState();
}

class _EditHeightDialogState extends State<EditHeightDialog> {
  late final TextEditingController _cmController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;
  late bool _isMetric;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;

    if (widget.currentHeight != null) {
      _cmController = TextEditingController(
        text: widget.currentHeight!.toStringAsFixed(0),
      );

      final totalInches = UnitConverter.cmToInches(widget.currentHeight!);
      final feet = totalInches ~/ 12;
      final inches = (totalInches % 12).round();

      _feetController = TextEditingController(text: feet.toString());
      _inchesController = TextEditingController(text: inches.toString());
    } else {
      _cmController = TextEditingController();
      _feetController = TextEditingController();
      _inchesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    double? heightInCm;

    if (_isMetric) {
      heightInCm = double.tryParse(_cmController.text.trim());
    } else {
      final feet = int.tryParse(_feetController.text.trim()) ?? 0;
      final inches = int.tryParse(_inchesController.text.trim()) ?? 0;
      if (feet > 0 || inches > 0) {
        heightInCm = UnitConverter.feetAndInchesToCm(feet, inches);
      }
    }

    if (heightInCm == null || heightInCm <= 0 || heightInCm > 300) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(heightInCm);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoAlertDialog(
      title: Text(l10n.editHeight),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 单位切换器
            CupertinoSlidingSegmentedControl<bool>(
              groupValue: _isMetric,
              children: {
                true: Text(l10n.heightInCm, style: AppTextStyles.callout),
                false: Text(l10n.heightInFeet, style: AppTextStyles.callout),
              },
              onValueChanged: (value) {
                if (value != null && !_isSaving) {
                  setState(() => _isMetric = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // 输入框
            if (_isMetric)
              CupertinoTextField(
                controller: _cmController,
                placeholder: l10n.heightPlaceholder,
                keyboardType: TextInputType.number,
                autofocus: true,
                enabled: !_isSaving,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _feetController,
                      placeholder: l10n.feet,
                      keyboardType: TextInputType.number,
                      enabled: !_isSaving,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _inchesController,
                      placeholder: l10n.inches,
                      keyboardType: TextInputType.number,
                      enabled: !_isSaving,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: AppTextStyles.body),
        ),
        CupertinoDialogAction(
          onPressed: _isSaving ? null : _handleSave,
          isDefaultAction: true,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(l10n.save, style: AppTextStyles.body),
        ),
      ],
    );
  }
}
