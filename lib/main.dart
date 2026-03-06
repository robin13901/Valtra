import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'database/app_database.dart';
import 'database/connection/shared.dart';
import 'database/daos/household_dao.dart';
import 'l10n/app_localizations.dart';
import 'providers/household_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/household_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Initialize database
  final database = AppDatabase(openConnection());

  // Initialize household provider
  final householdProvider = HouseholdProvider(HouseholdDao(database));
  await householdProvider.init();

  runApp(ValtraApp(
    database: database,
    themeProvider: themeProvider,
    householdProvider: householdProvider,
  ));
}

class ValtraApp extends StatelessWidget {
  final AppDatabase database;
  final ThemeProvider themeProvider;
  final HouseholdProvider householdProvider;

  const ValtraApp({
    super.key,
    required this.database,
    required this.themeProvider,
    required this.householdProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<HouseholdProvider>.value(value: householdProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Valtra',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

/// Placeholder home screen - will be replaced with actual navigation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const HouseholdSelector(),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.electric_bolt,
              size: 64,
              color: AppColors.ultraViolet,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.ultraViolet,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildCurrentHousehold(context, l10n),
            const SizedBox(height: 32),
            _buildCategoryChip(context, Icons.electric_bolt, l10n.electricity,
                AppColors.electricityColor),
            const SizedBox(height: 8),
            _buildCategoryChip(
                context, Icons.local_fire_department, l10n.gas, AppColors.gasColor),
            const SizedBox(height: 8),
            _buildCategoryChip(
                context, Icons.water_drop, l10n.water, AppColors.waterColor),
            const SizedBox(height: 8),
            _buildCategoryChip(
                context, Icons.thermostat, l10n.heating, AppColors.heatingColor),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrentHousehold(BuildContext context, AppLocalizations l10n) {
    final householdProvider = context.watch<HouseholdProvider>();
    final selectedHousehold = householdProvider.selectedHousehold;

    if (selectedHousehold == null) {
      return Text(
        l10n.noHouseholds,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Column(
      children: [
        Text(
          selectedHousehold.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        if (selectedHousehold.description != null) ...[
          const SizedBox(height: 4),
          Text(
            selectedHousehold.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Chip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}
