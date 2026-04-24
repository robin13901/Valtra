import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/backup_restore_provider.dart';
import '../providers/database_provider.dart';
import '../providers/interpolation_settings_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'household_cost_settings_screen.dart';

/// Settings screen with theme toggle, meter settings, and app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(0, liquidGlassAppBarHeight(context) + 8, 0, 8),
            children: [
              _buildThemeSection(context, l10n),
              const SizedBox(height: 8),
              _buildLanguageSection(context, l10n),
              const SizedBox(height: 8),
              _buildMeterSettingsSection(context, l10n),
              const SizedBox(height: 8),
              _buildCostProfilesNavTile(context, l10n),
              const SizedBox(height: 8),
              _buildBackupRestoreSection(context, l10n),
              const SizedBox(height: 8),
              _buildAboutSection(context, l10n),
            ],
          ),
          buildLiquidGlassAppBar(context, title: l10n.settings),
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

  Widget _buildLanguageSection(BuildContext context, AppLocalizations l10n) {
    final localeProvider = context.watch<LocaleProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.language),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'de',
                    label: Text(l10n.languageDE),
                    icon: const Icon(Icons.language),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(l10n.languageEN),
                  ),
                ],
                selected: {localeProvider.localeString},
                onSelectionChanged: (selected) {
                  context
                      .read<LocaleProvider>()
                      .setLocale(Locale(selected.first));
                },
              ),
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

  Widget _buildCostProfilesNavTile(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.euro),
          title: Text(l10n.costProfiles),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HouseholdCostSettingsScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupRestoreSection(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final provider = context.watch<BackupRestoreProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l10n.backupRestore),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file),
                  title: Text(l10n.exportDatabase),
                  subtitle: provider.state == BackupRestoreState.exporting
                      ? Text(l10n.exportInProgress)
                      : null,
                  trailing: provider.state == BackupRestoreState.exporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: provider.isLoading
                      ? null
                      : () => _handleExport(context, provider),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_rounded),
                  title: Text(l10n.importDatabase),
                  subtitle: provider.state == BackupRestoreState.importing
                      ? Text(l10n.importInProgress)
                      : provider.state == BackupRestoreState.validating
                          ? Text(l10n.validatingFile)
                          : null,
                  trailing: (provider.state ==
                              BackupRestoreState.importing ||
                          provider.state == BackupRestoreState.validating)
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: provider.isLoading
                      ? null
                      : () => _handleImport(context, provider, l10n),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    BackupRestoreProvider provider,
  ) async {
    await provider.exportDatabase();
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      final msg = provider.state == BackupRestoreState.success
          ? l10n.backupExportSuccess
          : provider.errorMessage ?? l10n.importFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      provider.resetState();
    }
  }

  Future<void> _handleImport(
    BuildContext context,
    BackupRestoreProvider provider,
    AppLocalizations l10n,
  ) async {
    // Confirmation dialog first (like XFin)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.importDatabase),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    if (!context.mounted) return;

    final currentDb = DatabaseProvider.instance.db;
    final success =
        await provider.importDatabase(File(result.files.single.path!), currentDb);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.importSuccess)));
    } else {
      final msg = provider.errorMessage?.contains('Invalid') == true
          ? l10n.invalidBackupFile
          : l10n.importFailed;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    provider.resetState();
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