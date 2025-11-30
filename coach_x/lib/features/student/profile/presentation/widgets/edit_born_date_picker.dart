import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 出生日期选择器
class EditBornDatePicker extends StatefulWidget {
  final DateTime? currentBornDate;
  final Future<void> Function(DateTime newDate) onSave;

  const EditBornDatePicker({
    super.key,
    this.currentBornDate,
    required this.onSave,
  });

  @override
  State<EditBornDatePicker> createState() => _EditBornDatePickerState();
}

class _EditBornDatePickerState extends State<EditBornDatePicker> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentBornDate ?? DateTime(2000, 1, 1);
  }

  Future<void> _handleConfirm() async {
    Navigator.of(context).pop();
    await widget.onSave(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 250,
      color: AppColors.backgroundWhite,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: Text(l10n.cancel, style: AppTextStyles.body),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoButton(
                child: Text(l10n.confirm, style: AppTextStyles.body),
                onPressed: _handleConfirm,
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedDate,
              maximumDate: DateTime.now(),
              minimumDate: DateTime(1900, 1, 1),
              onDateTimeChanged: (date) {
                setState(() => _selectedDate = date);
              },
            ),
          ),
        ],
      ),
    );
  }
}
