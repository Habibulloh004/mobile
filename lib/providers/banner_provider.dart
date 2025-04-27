import 'package:flutter/foundation.dart';
import '../models/banner_model.dart';
import '../core/api_service.dart';

class BannerProvider with ChangeNotifier {
  final ApiService _apiService;
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentIndex = 0;

  // Constructor
  BannerProvider(this._apiService) {
    loadBanners();
  }

  // Getters
  List<BannerModel> get banners => _banners;

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  String get errorMessage => _errorMessage;

  int get currentIndex => _currentIndex;

  // Set current banner index
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Load banners from API
  Future<void> loadBanners() async {
    if (_banners.isNotEmpty && !_isLoading) {
      // If we already have data and are not currently loading, just return
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔍 Fetching banners from API...");
      final fetchedBanners = await _apiService.fetchBanners();

      _banners = fetchedBanners;
      _isLoading = false;
      _hasError = false;
      debugPrint("✅ Successfully loaded ${_banners.length} banners");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading banners: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Refresh banners (force reload from API)
  Future<void> refreshBanners() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔄 Refreshing banners...");
      final fetchedBanners = await _apiService.fetchBanners();

      _banners = fetchedBanners;
      _isLoading = false;
      _hasError = false;
      debugPrint("✅ Successfully refreshed ${_banners.length} banners");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error refreshing banners: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
