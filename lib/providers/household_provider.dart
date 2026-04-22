import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/daos/household_dao.dart';

/// Manages household state including the current selection and list of households.
///
/// Persists the selected household ID to SharedPreferences so the selection
/// survives app restarts.
class HouseholdProvider extends ChangeNotifier {
  static const _selectedHouseholdKey = 'selected_household_id';

  final HouseholdDao _dao;
  SharedPreferences? _prefs;

  List<Household> _households = [];
  int? _selectedHouseholdId;
  bool _isInitialized = false;

  StreamSubscription<List<Household>>? _householdsSubscription;

  HouseholdProvider(this._dao);

  /// Whether the provider has completed initialization.
  bool get isInitialized => _isInitialized;

  /// List of all households.
  List<Household> get households => List.unmodifiable(_households);

  /// The currently selected household, or null if none selected.
  Household? get selectedHousehold {
    if (_selectedHouseholdId == null) return null;
    return _households.cast<Household?>().firstWhere(
          (h) => h?.id == _selectedHouseholdId,
          orElse: () => null,
        );
  }

  /// The ID of the currently selected household.
  int? get selectedHouseholdId => _selectedHouseholdId;

  /// Initializes the provider by loading persisted household selection
  /// and setting up the households stream.
  ///
  /// Waits for the first stream emission so that [households] and
  /// [selectedHouseholdId] are fully resolved before the future completes.
  /// This prevents cascading [notifyListeners] calls after the widget tree
  /// is built (which caused `_dependents.isEmpty` assertion failures) and
  /// eliminates household flicker on cold start.
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _selectedHouseholdId = _prefs?.getInt(_selectedHouseholdKey);

    // Completer that resolves after the first stream emission, so callers
    // of init() (i.e. main()) can await a fully-populated provider.
    final firstEmission = Completer<void>();

    // Subscribe to household changes
    _householdsSubscription = _dao.watchAllHouseholds().listen((households) {
      _households = households;

      _reconcileSelection(households);

      // On the first emission, mark initialized and complete the future
      // *before* notifying listeners.  Subsequent emissions notify normally.
      if (!firstEmission.isCompleted) {
        _isInitialized = true;
        firstEmission.complete();
      }

      notifyListeners();
    });

    // Wait for the stream to deliver its initial snapshot.
    await firstEmission.future;
  }

  /// Reconciles [_selectedHouseholdId] against the current [households] list.
  ///
  /// - Clears the persisted selection if the household was deleted.
  /// - Auto-selects the first household when nothing is selected.
  void _reconcileSelection(List<Household> households) {
    if (_selectedHouseholdId != null) {
      final stillExists =
          households.any((h) => h.id == _selectedHouseholdId);
      if (!stillExists) {
        _selectedHouseholdId = null;
        _prefs?.remove(_selectedHouseholdKey);
      }
    }

    if (_selectedHouseholdId == null && households.isNotEmpty) {
      _selectedHouseholdId = households.first.id;
      _prefs?.setInt(_selectedHouseholdKey, _selectedHouseholdId!);
    }
  }

  /// Selects a household and persists the selection.
  Future<void> selectHousehold(int id) async {
    if (_selectedHouseholdId == id) return;

    _selectedHouseholdId = id;
    await _prefs?.setInt(_selectedHouseholdKey, id);
    notifyListeners();
  }

  /// Creates a new household and optionally selects it.
  Future<int> createHousehold(
    String name, {
    String? description,
    required int personCount,
    bool selectAfterCreate = true,
  }) async {
    final id = await _dao.insert(HouseholdsCompanion.insert(
      name: name,
      description: description != null ? Value(description) : const Value.absent(),
      personCount: personCount,
    ));

    if (selectAfterCreate) {
      await selectHousehold(id);
    }

    return id;
  }

  /// Updates an existing household.
  Future<void> updateHousehold(
    int id,
    String name, {
    String? description,
    int? personCount,
  }) async {
    await _dao.updateHousehold(HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      personCount: personCount != null ? Value(personCount) : const Value.absent(),
    ));
  }

  /// Deletes a household. Throws if the household has related data.
  /// Returns true if deletion was successful, false if blocked due to related data.
  Future<bool> deleteHousehold(int id) async {
    final hasData = await _dao.hasRelatedData(id);
    if (hasData) {
      return false;
    }

    await _dao.deleteHousehold(id);
    return true;
  }

  /// Checks if a household has related meters or readings.
  Future<bool> hasRelatedData(int id) async {
    return _dao.hasRelatedData(id);
  }

  @override
  void dispose() {
    _householdsSubscription?.cancel();
    super.dispose();
  }
}
