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
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _selectedHouseholdId = _prefs?.getInt(_selectedHouseholdKey);

    // Subscribe to household changes
    _householdsSubscription = _dao.watchAllHouseholds().listen((households) {
      _households = households;

      // If selected household was deleted, clear selection
      if (_selectedHouseholdId != null) {
        final stillExists =
            households.any((h) => h.id == _selectedHouseholdId);
        if (!stillExists) {
          _selectedHouseholdId = null;
          _prefs?.remove(_selectedHouseholdKey);
        }
      }

      // Auto-select first household if none selected and households exist
      if (_selectedHouseholdId == null && households.isNotEmpty) {
        _selectedHouseholdId = households.first.id;
        _prefs?.setInt(_selectedHouseholdKey, _selectedHouseholdId!);
      }

      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
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
    bool selectAfterCreate = true,
  }) async {
    final id = await _dao.insert(HouseholdsCompanion.insert(
      name: name,
      description: description != null ? Value(description) : const Value.absent(),
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
  }) async {
    await _dao.updateHousehold(HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
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
