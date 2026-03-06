import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'database/app_database.dart';
import 'database/connection/shared.dart';
import 'database/daos/electricity_dao.dart';
import 'database/daos/gas_dao.dart';
import 'database/daos/household_dao.dart';
import 'database/daos/room_dao.dart';
import 'database/daos/smart_plug_dao.dart';
import 'database/daos/water_dao.dart';
import 'l10n/app_localizations.dart';
import 'providers/electricity_provider.dart';
import 'providers/gas_provider.dart';
import 'providers/household_provider.dart';
import 'providers/room_provider.dart';
import 'providers/smart_plug_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/water_provider.dart';
import 'screens/electricity_screen.dart';
import 'screens/gas_screen.dart';
import 'screens/smart_plugs_screen.dart';
import 'screens/water_screen.dart';
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

  // Initialize electricity provider
  final electricityProvider = ElectricityProvider(ElectricityDao(database));

  // Initialize room provider
  final roomProvider = RoomProvider(RoomDao(database));

  // Initialize smart plug provider
  final smartPlugProvider = SmartPlugProvider(SmartPlugDao(database));

  // Initialize water provider
  final waterProvider = WaterProvider(WaterDao(database));

  // Initialize gas provider
  final gasProvider = GasProvider(GasDao(database));

  // Connect providers to household changes
  if (householdProvider.selectedHouseholdId != null) {
    electricityProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    roomProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    smartPlugProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    waterProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    gasProvider.setHouseholdId(householdProvider.selectedHouseholdId);
  }

  runApp(ValtraApp(
    database: database,
    themeProvider: themeProvider,
    householdProvider: householdProvider,
    electricityProvider: electricityProvider,
    roomProvider: roomProvider,
    smartPlugProvider: smartPlugProvider,
    waterProvider: waterProvider,
    gasProvider: gasProvider,
  ));
}

class ValtraApp extends StatefulWidget {
  final AppDatabase database;
  final ThemeProvider themeProvider;
  final HouseholdProvider householdProvider;
  final ElectricityProvider electricityProvider;
  final RoomProvider roomProvider;
  final SmartPlugProvider smartPlugProvider;
  final WaterProvider waterProvider;
  final GasProvider gasProvider;

  const ValtraApp({
    super.key,
    required this.database,
    required this.themeProvider,
    required this.householdProvider,
    required this.electricityProvider,
    required this.roomProvider,
    required this.smartPlugProvider,
    required this.waterProvider,
    required this.gasProvider,
  });

  @override
  State<ValtraApp> createState() => _ValtraAppState();
}

class _ValtraAppState extends State<ValtraApp> {
  @override
  void initState() {
    super.initState();
    // Listen to household changes to update providers
    widget.householdProvider.addListener(_onHouseholdChanged);
  }

  @override
  void dispose() {
    widget.householdProvider.removeListener(_onHouseholdChanged);
    super.dispose();
  }

  void _onHouseholdChanged() {
    final householdId = widget.householdProvider.selectedHouseholdId;
    widget.electricityProvider.setHouseholdId(householdId);
    widget.roomProvider.setHouseholdId(householdId);
    widget.smartPlugProvider.setHouseholdId(householdId);
    widget.waterProvider.setHouseholdId(householdId);
    widget.gasProvider.setHouseholdId(householdId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.database),
        ChangeNotifierProvider<ThemeProvider>.value(
            value: widget.themeProvider),
        ChangeNotifierProvider<HouseholdProvider>.value(
            value: widget.householdProvider),
        ChangeNotifierProvider<ElectricityProvider>.value(
            value: widget.electricityProvider),
        ChangeNotifierProvider<RoomProvider>.value(
            value: widget.roomProvider),
        ChangeNotifierProvider<SmartPlugProvider>.value(
            value: widget.smartPlugProvider),
        ChangeNotifierProvider<WaterProvider>.value(
            value: widget.waterProvider),
        ChangeNotifierProvider<GasProvider>.value(
            value: widget.gasProvider),
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
            _buildCategoryChip(
              context,
              Icons.electric_bolt,
              l10n.electricity,
              AppColors.electricityColor,
              onTap: () => _navigateToElectricity(context),
            ),
            const SizedBox(height: 8),
            _buildCategoryChip(
              context,
              Icons.power,
              l10n.smartPlugs,
              AppColors.electricityColor,
              onTap: () => _navigateToSmartPlugs(context),
            ),
            const SizedBox(height: 8),
            _buildCategoryChip(
              context,
              Icons.local_fire_department,
              l10n.gas,
              AppColors.gasColor,
              onTap: () => _navigateToGas(context),
            ),
            const SizedBox(height: 8),
            _buildCategoryChip(
              context,
              Icons.water_drop,
              l10n.water,
              AppColors.waterColor,
              onTap: () => _navigateToWater(context),
            ),
            const SizedBox(height: 8),
            _buildCategoryChip(
              context,
              Icons.thermostat,
              l10n.heating,
              AppColors.heatingColor,
            ),
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
    Color color, {
    VoidCallback? onTap,
  }) {
    final chip = Chip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: chip,
      );
    }

    return chip;
  }

  void _navigateToElectricity(BuildContext context) {
    final householdProvider = context.read<HouseholdProvider>();
    if (householdProvider.selectedHousehold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectHousehold),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ElectricityScreen()),
    );
  }

  void _navigateToSmartPlugs(BuildContext context) {
    final householdProvider = context.read<HouseholdProvider>();
    if (householdProvider.selectedHousehold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectHousehold),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SmartPlugsScreen()),
    );
  }

  void _navigateToWater(BuildContext context) {
    final householdProvider = context.read<HouseholdProvider>();
    if (householdProvider.selectedHousehold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectHousehold),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WaterScreen()),
    );
  }

  void _navigateToGas(BuildContext context) {
    final householdProvider = context.read<HouseholdProvider>();
    if (householdProvider.selectedHousehold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectHousehold),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GasScreen()),
    );
  }
}
