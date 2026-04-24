import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
import 'providers/database_provider.dart';
import 'providers/interpolation_settings_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/smart_plug_analytics_provider.dart';
import 'providers/room_provider.dart';
import 'providers/smart_plug_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/water_provider.dart';
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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Initialize locale provider
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  // Initialize database
  final database = AppDatabase(openConnection());
  DatabaseProvider.instance.initialize(database);

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
    householdDao: HouseholdDao(database),
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

  removeSplashWhenReady(householdProvider);
}

/// Removes the native splash screen once the [HouseholdProvider] is ready.
///
/// If the provider is already initialized (the normal case — [init] is
/// awaited before this is called), the splash is removed on the next frame.
/// Otherwise falls back to waiting for the first [notifyListeners] call.
///
/// An optional [removeSplash] callback can be injected for testing.
@visibleForTesting
void removeSplashWhenReady(
  HouseholdProvider provider, {
  void Function()? removeSplash,
}) {
  final remove = removeSplash ?? FlutterNativeSplash.remove;

  void scheduleRemove() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      remove();
    });
  }

  // init() is awaited in main() before this is called, so the provider is
  // always initialized here.  Remove the splash on the next frame.
  if (provider.isInitialized) {
    scheduleRemove();
    return;
  }

  // Fallback: wait for init to complete (defensive, shouldn't happen).
  void listener() {
    if (provider.isInitialized) {
      provider.removeListener(listener);
      scheduleRemove();
    }
  }

  provider.addListener(listener);
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
    // Schedule provider updates after the current frame to avoid cascading
    // notifyListeners() calls during an active build/notification cycle.
    // Without this, cold-start triggers a stream event on HouseholdProvider
    // that synchronously notifies 9+ child providers, which can cause a
    // '_elements.contains(element)' assertion in the framework.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    });
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

/// Home screen with frosted glass household carousel and GlassCard navigation tiles.
///
/// Displays a horizontal PageView carousel of household cards at the top,
/// followed by category tiles for navigating to individual screens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int? _lastSelectedHouseholdId;

  @override
  void initState() {
    super.initState();
    // PageController is initialized without initial page here; we set it
    // in didChangeDependencies once we have access to the provider.
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<HouseholdProvider>();
    final households = provider.households;
    final selectedId = provider.selectedHouseholdId;

    // First time: initialize the page controller to the correct page
    if (_lastSelectedHouseholdId == null && selectedId != null) {
      final index = households.indexWhere((h) => h.id == selectedId);
      if (index >= 0 && index != _pageController.initialPage) {
        // Dispose and re-create with correct initial page
        _pageController.dispose();
        _pageController = PageController(
          viewportFraction: 0.92,
          initialPage: index,
        );
      }
    }
    _lastSelectedHouseholdId = selectedId;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      noAnimRoute(const SettingsScreen()),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
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
      noAnimRoute(screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          _buildHomeHub(context, l10n),
          buildLiquidGlassAppBar(
            context,
            title: '',
            showBackButton: false,
            actions: [
              const HouseholdSelector(),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _navigateToSettings(context),
                tooltip: l10n.settings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeHub(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(8, liquidGlassAppBarHeight(context) + 16, 8, 16),
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
          // Frosted glass household carousel
          _buildHouseholdCarousel(context, l10n),
          const SizedBox(height: 24),
          // 4 category GlassCards in a 2-column grid (Bento Grid)
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
                    _navigateToScreen(context, const ElectricityScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.power,
                label: l10n.smartPlugs,
                color: AppColors.electricityColor,
                onTap: () =>
                    _navigateToScreen(context, const SmartPlugsScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.local_fire_department,
                label: l10n.gas,
                color: AppColors.gasColor,
                onTap: () =>
                    _navigateToScreen(context, const GasScreen()),
              ),
              _buildCategoryCard(
                context,
                icon: Icons.thermostat,
                label: l10n.heating,
                color: AppColors.heatingColor,
                onTap: () =>
                    _navigateToScreen(context, const HeatingScreen()),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Water tile centered below the grid
          Center(
            child: SizedBox(
              width: (MediaQuery.of(context).size.width - 16) / 2,
              child: AspectRatio(
                aspectRatio: 1.4,
                child: _buildCategoryCard(
                  context,
                  icon: Icons.water_drop,
                  label: l10n.water,
                  color: AppColors.waterColor,
                  onTap: () =>
                      _navigateToScreen(context, const WaterScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCarousel(BuildContext context, AppLocalizations l10n) {
    return Consumer<HouseholdProvider>(
      builder: (context, provider, child) {
        final households = provider.households;

        if (households.isEmpty) {
          return _buildEmptyHouseholdCard(context, l10n);
        }

        // Reverse-sync: when selectedHouseholdId changes externally,
        // animate the carousel to the correct page.
        final selectedId = provider.selectedHouseholdId;
        if (selectedId != null && selectedId != _lastSelectedHouseholdId) {
          final newIndex = households.indexWhere((h) => h.id == selectedId);
          if (newIndex >= 0 && _pageController.hasClients) {
            final currentPage = _pageController.page?.round() ?? -1;
            if (currentPage != newIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    newIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          }
          _lastSelectedHouseholdId = selectedId;
        }

        return SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            itemCount: households.length,
            onPageChanged: (index) {
              provider.selectHousehold(households[index].id);
              _lastSelectedHouseholdId = households[index].id;
            },
            itemBuilder: (context, index) {
              final household = households[index];
              final isSelected = household.id == provider.selectedHouseholdId;
              return _HouseholdCard(
                household: household,
                isSelected: isSelected,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyHouseholdCard(
      BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                  .withValues(alpha: 0.8),
              border: Border.all(
                color: AppColors.ultraViolet.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.noHouseholds,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
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

/// A frosted glass card for displaying a single household in the carousel.
class _HouseholdCard extends StatelessWidget {
  final Household household;
  final bool isSelected;

  const _HouseholdCard({
    required this.household,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                  .withValues(alpha: 0.8),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : AppColors.ultraViolet.withValues(alpha: 0.2),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.ultraViolet.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  household.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (household.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    household.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${household.personCount} ${household.personCount == 1 ? l10n.person : l10n.persons}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
