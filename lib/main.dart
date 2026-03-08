import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'database/app_database.dart';
import 'database/connection/shared.dart';
import 'database/daos/cost_config_dao.dart';
import 'database/daos/electricity_dao.dart';
import 'database/daos/gas_dao.dart';
import 'database/daos/heating_dao.dart';
import 'database/daos/household_dao.dart';
import 'database/daos/room_dao.dart';
import 'database/daos/smart_plug_dao.dart';
import 'database/daos/water_dao.dart';
import 'l10n/app_localizations.dart';
import 'providers/electricity_provider.dart';
import 'providers/gas_provider.dart';
import 'providers/heating_provider.dart';
import 'providers/household_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/backup_restore_provider.dart';
import 'providers/cost_config_provider.dart';
import 'providers/interpolation_settings_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/smart_plug_analytics_provider.dart';
import 'providers/room_provider.dart';
import 'providers/smart_plug_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/water_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/electricity_screen.dart';
import 'screens/gas_screen.dart';
import 'screens/heating_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/smart_plugs_screen.dart';
import 'screens/water_screen.dart';
import 'services/cost_calculation_service.dart';
import 'services/backup_restore_service.dart';
import 'services/gas_conversion_service.dart';
import 'services/interpolation/interpolation_service.dart';
import 'widgets/household_selector.dart';
import 'widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Initialize locale provider
  final localeProvider = LocaleProvider();
  await localeProvider.init();

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

  // Initialize heating provider
  final heatingProvider = HeatingProvider(HeatingDao(database));

  // Initialize interpolation settings provider
  final interpolationSettingsProvider = InterpolationSettingsProvider();
  await interpolationSettingsProvider.init();

  // Initialize cost config provider
  final costConfigProvider = CostConfigProvider(
    costConfigDao: CostConfigDao(database),
    costCalculationService: const CostCalculationService(),
  );

  // Initialize analytics provider
  final analyticsProvider = AnalyticsProvider(
    electricityDao: ElectricityDao(database),
    gasDao: GasDao(database),
    waterDao: WaterDao(database),
    heatingDao: HeatingDao(database),
    interpolationService: InterpolationService(),
    gasConversionService: GasConversionService(),
    settingsProvider: interpolationSettingsProvider,
    costConfigProvider: costConfigProvider,
  );

  // Initialize smart plug analytics provider
  final smartPlugAnalyticsProvider = SmartPlugAnalyticsProvider(
    smartPlugDao: SmartPlugDao(database),
    electricityDao: ElectricityDao(database),
    roomDao: RoomDao(database),
    interpolationService: InterpolationService(),
  );

  // Initialize backup/restore service and provider
  final backupRestoreService = BackupRestoreService();
  final backupRestoreProvider = BackupRestoreProvider(
    service: backupRestoreService,
  );

  // Connect providers to household changes
  if (householdProvider.selectedHouseholdId != null) {
    electricityProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    roomProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    smartPlugProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    waterProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    gasProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    heatingProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    analyticsProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    smartPlugAnalyticsProvider.setHouseholdId(householdProvider.selectedHouseholdId);
    costConfigProvider.setHouseholdId(householdProvider.selectedHouseholdId);
  }

  runApp(ValtraApp(
    database: database,
    themeProvider: themeProvider,
    localeProvider: localeProvider,
    householdProvider: householdProvider,
    electricityProvider: electricityProvider,
    roomProvider: roomProvider,
    smartPlugProvider: smartPlugProvider,
    waterProvider: waterProvider,
    gasProvider: gasProvider,
    heatingProvider: heatingProvider,
    interpolationSettingsProvider: interpolationSettingsProvider,
    analyticsProvider: analyticsProvider,
    smartPlugAnalyticsProvider: smartPlugAnalyticsProvider,
    costConfigProvider: costConfigProvider,
    backupRestoreProvider: backupRestoreProvider,
  ));
}

class ValtraApp extends StatefulWidget {
  final AppDatabase database;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final HouseholdProvider householdProvider;
  final ElectricityProvider electricityProvider;
  final RoomProvider roomProvider;
  final SmartPlugProvider smartPlugProvider;
  final WaterProvider waterProvider;
  final GasProvider gasProvider;
  final HeatingProvider heatingProvider;
  final InterpolationSettingsProvider interpolationSettingsProvider;
  final AnalyticsProvider analyticsProvider;
  final SmartPlugAnalyticsProvider smartPlugAnalyticsProvider;
  final CostConfigProvider costConfigProvider;
  final BackupRestoreProvider backupRestoreProvider;

  const ValtraApp({
    super.key,
    required this.database,
    required this.themeProvider,
    required this.localeProvider,
    required this.householdProvider,
    required this.electricityProvider,
    required this.roomProvider,
    required this.smartPlugProvider,
    required this.waterProvider,
    required this.gasProvider,
    required this.heatingProvider,
    required this.interpolationSettingsProvider,
    required this.analyticsProvider,
    required this.smartPlugAnalyticsProvider,
    required this.costConfigProvider,
    required this.backupRestoreProvider,
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
    widget.heatingProvider.setHouseholdId(householdId);
    widget.analyticsProvider.setHouseholdId(householdId);
    widget.smartPlugAnalyticsProvider.setHouseholdId(householdId);
    widget.costConfigProvider.setHouseholdId(householdId);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.database),
        ChangeNotifierProvider<ThemeProvider>.value(
            value: widget.themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(
            value: widget.localeProvider),
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
        ChangeNotifierProvider<HeatingProvider>.value(
            value: widget.heatingProvider),
        ChangeNotifierProvider<InterpolationSettingsProvider>.value(
            value: widget.interpolationSettingsProvider),
        ChangeNotifierProvider<AnalyticsProvider>.value(
            value: widget.analyticsProvider),
        ChangeNotifierProvider<SmartPlugAnalyticsProvider>.value(
            value: widget.smartPlugAnalyticsProvider),
        ChangeNotifierProvider<CostConfigProvider>.value(
            value: widget.costConfigProvider),
        ChangeNotifierProvider<BackupRestoreProvider>.value(
            value: widget.backupRestoreProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Valtra',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

/// Home screen with GlassBottomNav for primary navigation.
///
/// Uses Option B from the plan: bottom nav acts as a shortcut bar.
/// Index 0 shows the home hub with GlassCard navigation tiles.
/// Tapping bottom nav items 1-4 pushes to their screens via Navigator.push
/// and resets the index back to 0.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onBottomNavTap(int index) {
    if (index == 0) {
      // Home tab -- just stay on hub
      setState(() => _currentIndex = 0);
      return;
    }

    // For tabs 1-4, push to the screen and reset index to 0
    final householdProvider = context.read<HouseholdProvider>();
    if (householdProvider.selectedHousehold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectHousehold),
        ),
      );
      return;
    }

    Widget screen;
    switch (index) {
      case 1:
        screen = const ElectricityScreen();
      case 2:
        screen = const GasScreen();
      case 3:
        screen = const WaterScreen();
      case 4:
        screen = const AnalyticsScreen();
      default:
        return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) {
      // Reset to home after returning from pushed screen
      if (mounted) {
        setState(() => _currentIndex = 0);
      }
    });
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _navigateToScreen(Widget screen) {
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
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildGlassAppBar(
        context: context,
        title: l10n.appTitle,
        actions: [
          const HouseholdSelector(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: _buildHomeHub(context, l10n),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.electric_bolt),
            label: l10n.electricity,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_fire_department),
            label: l10n.gas,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.water_drop),
            label: l10n.water,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: l10n.analyticsHub,
          ),
        ],
      ),
      // NO floatingActionButton -- removed per FR-12.1.2
    );
  }

  Widget _buildHomeHub(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          // App icon and title
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
          const SizedBox(height: 24),
          // 6 category GlassCards in a 2-column grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              _buildCategoryCard(
                context,
                icon: Icons.electric_bolt,
                label: l10n.electricity,
                color: AppColors.electricityColor,
                onTap: () =>
                    _navigateToScreen(const ElectricityScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.power,
                label: l10n.smartPlugs,
                color: AppColors.electricityColor,
                onTap: () =>
                    _navigateToScreen(const SmartPlugsScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.local_fire_department,
                label: l10n.gas,
                color: AppColors.gasColor,
                onTap: () => _navigateToScreen(const GasScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.water_drop,
                label: l10n.water,
                color: AppColors.waterColor,
                onTap: () => _navigateToScreen(const WaterScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.thermostat,
                label: l10n.heating,
                color: AppColors.heatingColor,
                onTap: () =>
                    _navigateToScreen(const HeatingScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.analytics,
                label: l10n.analyticsHub,
                color: AppColors.ultraViolet,
                onTap: () =>
                    _navigateToScreen(const AnalyticsScreen()),
              ),
            ],
          ),
        ],
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

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
