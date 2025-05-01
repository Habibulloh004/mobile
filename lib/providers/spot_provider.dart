import 'package:flutter/foundation.dart';
import '../models/spot_model.dart';
import '../core/api_service.dart';

class SpotProvider with ChangeNotifier {
  final ApiService _apiService;
  List<SpotModel> _spots = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  SpotModel? _selectedSpot;

  SpotProvider(this._apiService) {
    loadSpots();
  }

  // Getters
  List<SpotModel> get spots => _spots;

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  String get errorMessage => _errorMessage;

  SpotModel? get selectedSpot => _selectedSpot;

  // Set selected spot
  void setSelectedSpot(SpotModel? spot) {
    _selectedSpot = spot;
    notifyListeners();
  }

  // Load spots from API
  Future<void> loadSpots() async {
    if (_spots.isNotEmpty && !_isLoading) {
      // If we already have data and are not currently loading, just return
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔍 Fetching spots from API...");
      final fetchedSpots = await _apiService.fetchSpots();

      _spots = fetchedSpots;
      _isLoading = false;
      _hasError = false;

      // Auto-select the first spot if none is selected
      if (_selectedSpot == null && _spots.isNotEmpty) {
        _selectedSpot = _spots.first;
      }

      debugPrint("✅ Successfully loaded ${_spots.length} spots");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading spots: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Refresh spots (force reload)
  Future<void> refreshSpots() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔄 Refreshing spots...");
      final fetchedSpots = await _apiService.fetchSpots();

      _spots = fetchedSpots;
      _isLoading = false;
      _hasError = false;

      // Make sure selected spot is still valid
      if (_selectedSpot != null) {
        final stillExists = _spots.any((spot) => spot.id == _selectedSpot!.id);
        if (!stillExists && _spots.isNotEmpty) {
          _selectedSpot = _spots.first;
        } else if (!stillExists) {
          _selectedSpot = null;
        }
      }

      debugPrint("✅ Successfully refreshed ${_spots.length} spots");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error refreshing spots: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get a spot by ID
  SpotModel? getSpotById(String spotId) {
    try {
      return _spots.firstWhere((spot) => spot.id == spotId);
    } catch (e) {
      return null;
    }
  }

  // Reset selected spot
  void resetSelection() {
    _selectedSpot = null;
    notifyListeners();
  }
}
