import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/cost_config_provider.dart';
import '../providers/interpolation_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/interpolation/models.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Settings screen with theme toggle, meter settings, and app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// The meter type keys used for interpolation settings.
  /// These match the string keys used by InterpolationSettingsProvider.
  static const _meterTypes = ['electricity', 'gas', 'water', 'heating'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildGlassAppBar(context: context, title: l10n.settings),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildThemeSection(context, l10n),
          const SizedBox(height: 8),
          _buildMeterSettingsSection(context, l10n),
          const SizedBox(height: 8),
          _buildCostConfigSection(context, l10n),
          const SizedBox(height: 8),
          _buildAboutSection(context, l10n),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ultraViolet,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, AppLocalizations l10n) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.appearance),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.themeMode,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                        icon: const Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                        icon: const Icon(Icons.dark_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                        icon: const Icon(Icons.brightness_auto),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (selected) {
                      themeProvider.setThemeMode(selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterSettingsSection(BuildContext context, AppLocalizations l10n) {
    final settingsProvider = context.watch<InterpolationSettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.meterSettings),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGasConversionField(context, l10n, settingsProvider),
                const Divider(height: 24),
                Text(
                  l10n.interpolationMethodLabel,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                ..._meterTypes.map(
                  (type) => _buildInterpolationRow(
                    context,
                    l10n,
                    settingsProvider,
                    type,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGasConversionField(
    BuildContext context,
    AppLocalizations l10n,
    InterpolationSettingsProvider settingsProvider,
  ) {
    return _GasConversionField(
      initialValue: settingsProvider.gasKwhFactor,
      label: l10n.gasKwhConversionFactor,
      hint: l10n.gasKwhConversionHint,
      invalidNumberText: l10n.invalidNumber,
      onChanged: settingsProvider.setGasKwhFactor,
    );
  }

  Widget _buildInterpolationRow(
    BuildContext context,
    AppLocalizations l10n,
    InterpolationSettingsProvider settingsProvider,
    String meterType,
  ) {
    final method = settingsProvider.getMethodForMeterType(meterType);
    final displayName = _meterTypeDisplayName(l10n, meterType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(displayName)),
          DropdownButton<InterpolationMethod>(
            value: method,
            onChanged: (newMethod) {
              if (newMethod != null) {
                settingsProvider.setMethodForMeterType(meterType, newMethod);
              }
            },
            items: [
              DropdownMenuItem(
                value: InterpolationMethod.linear,
                child: Text(l10n.linear),
              ),
              DropdownMenuItem(
                value: InterpolationMethod.step,
                child: Text(l10n.step),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _meterTypeDisplayName(AppLocalizations l10n, String meterType) {
    switch (meterType) {
      case 'electricity':
        return l10n.electricity;
      case 'gas':
        return l10n.gas;
      case 'water':
        return l10n.water;
      case 'heating':
        return l10n.heating;
      default:
        return meterType;
    }
  }

  Widget _buildCostConfigSection(BuildContext context, AppLocalizations l10n) {
    final costProvider = context.watch<CostConfigProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.costConfiguration),
        ...CostMeterType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _CostConfigCard(
              meterType: type,
              config: costProvider.getActiveConfig(type, DateTime.now()),
              l10n: l10n,
              costProvider: costProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.aboutSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  final buildNumber = snapshot.data?.buildNumber ?? '';
                  final versionString = buildNumber.isNotEmpty
                      ? '$version+$buildNumber'
                      : version;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.info_outline,
                      color: AppColors.ultraViolet,
                    ),
                    title: Text(l10n.appVersion),
                    subtitle: Text(versionString),
                  );
                },
              ),
          ),
        ),
      ],
    );
  }
}

/// Stateful widget for the gas conversion factor text field.
/// Uses a TextEditingController to avoid losing cursor position on rebuild.
class _GasConversionField extends StatefulWidget {
  const _GasConversionField({
    required this.initialValue,
    required this.label,
    required this.hint,
    required this.invalidNumberText,
    required this.onChanged,
  });

  final double initialValue;
  final String label;
  final String hint;
  final String invalidNumberText;
  final Future<void> Function(double) onChanged;

  @override
  State<_GasConversionField> createState() => _GasConversionFieldState();
}

class _GasConversionFieldState extends State<_GasConversionField> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _errorText = null);
      widget.onChanged(parsed);
    } else {
      setState(() => _errorText = widget.invalidNumberText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: _errorText,
            suffixText: 'kWh/m³',
          ),
          onSubmitted: _onSubmitted,
          onEditingComplete: () => _onSubmitted(_controller.text),
        ),
      ],
    );
  }
}

/// Card for configuring cost per meter type.
class _CostConfigCard extends StatefulWidget {
  const _CostConfigCard({
    required this.meterType,
    required this.config,
    required this.l10n,
    required this.costProvider,
  });

  final CostMeterType meterType;
  final CostConfig? config;
  final AppLocalizations l10n;
  final CostConfigProvider costProvider;

  @override
  State<_CostConfigCard> createState() => _CostConfigCardState();
}

class _CostConfigCardState extends State<_CostConfigCard> {
  late TextEditingController _unitPriceController;
  late TextEditingController _standingChargeController;
  late DateTime _validFrom;
  String? _unitPriceError;
  String? _standingChargeError;

  @override
  void initState() {
    super.initState();
    _unitPriceController = TextEditingController(
      text: widget.config?.unitPrice.toString() ?? '',
    );
    _standingChargeController = TextEditingController(
      text: widget.config?.standingCharge.toString() ?? '0.0',
    );
    _validFrom = widget.config?.validFrom ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void didUpdateWidget(covariant _CostConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config?.id != oldWidget.config?.id) {
      _unitPriceController.text =
          widget.config?.unitPrice.toString() ?? '';
      _standingChargeController.text =
          widget.config?.standingCharge.toString() ?? '0.0';
      _validFrom = widget.config?.validFrom ??
          DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _standingChargeController.dispose();
    super.dispose();
  }

  String _meterTypeLabel() {
    switch (widget.meterType) {
      case CostMeterType.electricity:
        return widget.l10n.electricity;
      case CostMeterType.gas:
        return widget.l10n.gas;
      case CostMeterType.water:
        return widget.l10n.water;
    }
  }

  IconData _meterTypeIcon() {
    switch (widget.meterType) {
      case CostMeterType.electricity:
        return Icons.electric_bolt;
      case CostMeterType.gas:
        return Icons.local_fire_department;
      case CostMeterType.water:
        return Icons.water_drop;
    }
  }

  String _unitSuffix() {
    switch (widget.meterType) {
      case CostMeterType.electricity:
      case CostMeterType.gas:
        return widget.l10n.pricePerKwh;
      case CostMeterType.water:
        return widget.l10n.pricePerCubicMeter;
    }
  }

  Future<void> _save() async {
    final unitPrice = double.tryParse(_unitPriceController.text);
    final standingCharge = double.tryParse(_standingChargeController.text);

    setState(() {
      _unitPriceError =
          (unitPrice == null || unitPrice <= 0) ? widget.l10n.invalidNumber : null;
      _standingChargeError =
          (standingCharge == null || standingCharge < 0)
              ? widget.l10n.invalidNumber
              : null;
    });

    if (_unitPriceError != null || _standingChargeError != null) return;

    if (widget.config != null) {
      await widget.costProvider.updateConfig(
        widget.config!.copyWith(
          unitPrice: unitPrice!,
          standingCharge: standingCharge!,
          validFrom: _validFrom,
        ),
      );
    } else {
      await widget.costProvider.addConfig(
        CostConfigsCompanion.insert(
          householdId: widget.costProvider.householdId!,
          meterType: widget.meterType,
          unitPrice: unitPrice!,
          standingCharge: Value(standingCharge!),
          validFrom: _validFrom,
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.costConfigSaved)),
      );
    }
  }

  Future<void> _delete() async {
    if (widget.config == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.l10n.deleteCostConfig),
        content: Text(
          widget.l10n.deleteCostConfigConfirm(_meterTypeLabel()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.costProvider.deleteConfig(widget.config!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.costConfigDeleted)),
        );
      }
    }
  }

  Future<void> _pickValidFrom() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _validFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _validFrom = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasConfig = widget.config != null;

    return GlassCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_meterTypeIcon(), color: AppColors.ultraViolet),
                const SizedBox(width: 8),
                Text(
                  _meterTypeLabel(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (hasConfig)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                    tooltip: widget.l10n.deleteCostConfig,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitPriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: widget.l10n.unitPrice,
                suffixText: _unitSuffix(),
                errorText: _unitPriceError,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _standingChargeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: widget.l10n.standingChargePerMonth,
                suffixText: widget.l10n.perMonth,
                errorText: _standingChargeError,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickValidFrom,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: widget.l10n.validFrom,
                  isDense: true,
                ),
                child: Text(
                  '${_validFrom.day}.${_validFrom.month}.${_validFrom.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.l10n.saveCostConfig),
              ),
            ),
          ],
        ),
    );
  }
}