import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';
import '../../database/tables.dart';

/// Data returned from [CostProfileFormDialog] when saved.
class CostProfileFormData {
  final DateTime validFrom;
  final double annualBasePrice;
  final double energyPrice;

  const CostProfileFormData({
    required this.validFrom,
    required this.annualBasePrice,
    required this.energyPrice,
  });
}

/// Dialog for creating or editing a cost profile.
///
/// When [config] is null, the dialog operates in create mode.
/// When [config] is provided, the dialog operates in edit mode.
class CostProfileFormDialog extends StatefulWidget {
  final CostConfig? config;
  final CostMeterType meterType;
  final int householdId;

  const CostProfileFormDialog({
    super.key,
    this.config,
    required this.meterType,
    required this.householdId,
  });

  /// Shows the dialog and returns the form data if saved, or null if cancelled.
  static Future<CostProfileFormData?> show(
    BuildContext context, {
    CostConfig? config,
    required CostMeterType meterType,
    required int householdId,
  }) {
    return showDialog<CostProfileFormData>(
      context: context,
      builder: (context) => CostProfileFormDialog(
        config: config,
        meterType: meterType,
        householdId: householdId,
      ),
    );
  }

  @override
  State<CostProfileFormDialog> createState() => _CostProfileFormDialogState();
}

class _CostProfileFormDialogState extends State<CostProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _annualBasePriceController;
  late final TextEditingController _energyPriceController;
  late DateTime _validFrom;

  bool get isEditing => widget.config != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final config = widget.config!;
      _annualBasePriceController =
          TextEditingController(text: config.standingCharge.toString());
      _energyPriceController =
          TextEditingController(text: config.unitPrice.toString());
      _validFrom = config.validFrom;
    } else {
      _annualBasePriceController = TextEditingController();
      _energyPriceController = TextEditingController();
      _validFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  @override
  void dispose() {
    _annualBasePriceController.dispose();
    _energyPriceController.dispose();
    super.dispose();
  }

  String _unitSuffix(AppLocalizations l10n) {
    switch (widget.meterType) {
      case CostMeterType.electricity:
      case CostMeterType.gas:
      case CostMeterType.heating:
        return l10n.pricePerKwh;
      case CostMeterType.water:
        return l10n.pricePerCubicMeter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(isEditing ? l10n.editCostProfile : l10n.addCostProfile),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Valid From date picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _validFrom,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _validFrom = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.validFrom,
                ),
                child: Text(
                  '${_validFrom.day}.${_validFrom.month}.${_validFrom.year}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 2. Annual Base Price
            TextFormField(
              controller: _annualBasePriceController,
              decoration: InputDecoration(
                labelText: l10n.annualBasePrice,
                suffixText: l10n.perYear,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.invalidNumber;
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return l10n.invalidNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            // 3. Energy Price
            TextFormField(
              controller: _energyPriceController,
              decoration: InputDecoration(
                labelText: l10n.unitPrice,
                suffixText: _unitSuffix(l10n),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.invalidNumber;
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return l10n.invalidNumber;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final annualBasePrice = double.parse(_annualBasePriceController.text);
      final energyPrice = double.parse(_energyPriceController.text);
      Navigator.of(context).pop(CostProfileFormData(
        validFrom: _validFrom,
        annualBasePrice: annualBasePrice,
        energyPrice: energyPrice,
      ));
    }
  }
}
