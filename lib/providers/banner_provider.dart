// lib/providers/banner_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banner_model.dart';
import '../core/api_service.dart';
import '../core/mock_banner_service.dart';
import '../constant/index.dart';

class BannerProvider with ChangeNotifier {
  final ApiService _apiService;
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentIndex = 0;

  // Cache keys and durations
  static const String BANNER_CACHE_KEY = 'banner_data';
  static const int BANNER_CACHE_DURATION = 0;
      // 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

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
      // Check cache first
      final cachedBanners = await _getCachedBanners();
      if (cachedBanners != null) {
        debugPrint("✅ Loaded ${cachedBanners.length} banners from cache");
        _banners = cachedBanners;
        _isLoading = false;
        _hasError = false;
        notifyListeners();
        return;
      }

      debugPrint("🔍 Fetching banners from API...");

      // Get API base URL
      final apiBaseUrl = Constants.apiBaseUrl;
      final userId = Constants.userId;

      try {
        // Fetch from the specified endpoint without token
        final response = await Dio().get(
          '$apiBaseUrl/public/mobilebanner/$userId',
        );

        if (response.statusCode == 200 && response.data["data"] != null) {
          final List<dynamic> data = response.data["data"];
          _banners = data.map((json) => BannerModel.fromJson(json)).toList();

          // Cache the banners
          _cacheBanners(_banners);

          _isLoading = false;
          _hasError = false;
          debugPrint(
            "✅ Successfully loaded ${_banners.length} banners from API",
          );
        } else {
          throw Exception("Invalid API response format");
        }
      } catch (apiError) {
        // If API fails, fall back to mock data
        debugPrint("⚠️ API call failed, using mock data: $apiError");
        final mockData = await MockBannerService.getMockBannerResponse();

        if (mockData["status"] == "success" && mockData["data"] != null) {
          final List<dynamic> data = mockData["data"];
          _banners = data.map((json) => BannerModel.fromJson(json)).toList();
          _isLoading = false;
          _hasError = false;
          debugPrint("✅ Successfully loaded ${_banners.length} mock banners");
        } else {
          throw Exception("Invalid mock data format");
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading banners: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Cache banners for 7 days
  Future<void> _cacheBanners(List<BannerModel> banners) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializedBanners =
          banners.map((banner) => banner.toJson()).toList();

      final Map<String, dynamic> cacheObject = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': serializedBanners,
      };

      await prefs.setString(BANNER_CACHE_KEY, jsonEncode(cacheObject));
      debugPrint("✅ Cached ${banners.length} banners for 7 days");
    } catch (e) {
      debugPrint("❌ Error caching banners: $e");
      // Non-critical error, just log it
    }
  }

  // Get cached banners if available and not expired (7 days)
  Future<List<BannerModel>?> _getCachedBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(BANNER_CACHE_KEY);

      if (cachedData != null) {
        final Map<String, dynamic> bannerCache = jsonDecode(cachedData);
        final int timestamp = bannerCache['timestamp'] ?? 0;

        // Check if cache is still valid (7 days)
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            BANNER_CACHE_DURATION) {
          debugPrint(
            '✅ Found valid banner cache (age: ${((DateTime.now().millisecondsSinceEpoch - timestamp) / (24 * 60 * 60 * 1000)).toStringAsFixed(1)} days)',
          );
          final List<dynamic> cachedBanners = bannerCache['data'];
          return cachedBanners
              .map((json) => BannerModel.fromJson(json))
              .toList();
        } else {
          debugPrint(
            '⚠️ Banner cache expired (age: ${((DateTime.now().millisecondsSinceEpoch - timestamp) / (24 * 60 * 60 * 1000)).toStringAsFixed(1)} days)',
          );
          return null;
        }
      }

      debugPrint('⚠️ No banner cache found');
      return null;
    } catch (e) {
      debugPrint('❌ Error reading banner cache: $e');
      return null;
    }
  }

  // Refresh banners (force reload from API, ignoring cache)
  Future<void> refreshBanners() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔄 Refreshing banners from API (ignoring cache)...");

      // Get API base URL
      final apiBaseUrl = Constants.apiBaseUrl;
      final userId = Constants.userId;

      try {
        // Fetch from the specified endpoint without token
        final response = await Dio().get(
          '$apiBaseUrl/public/mobilebanner/$userId',
        );

        if (response.statusCode == 200 && response.data["data"] != null) {
          final List<dynamic> data = response.data["data"];
          _banners = data.map((json) => BannerModel.fromJson(json)).toList();

          // Update the cache with new data
          _cacheBanners(_banners);

          _isLoading = false;
          _hasError = false;
          debugPrint(
            "✅ Successfully refreshed ${_banners.length} banners from API",
          );
        } else {
          throw Exception("Invalid API response format");
        }
      } catch (apiError) {
        // If API fails, fall back to mock data
        debugPrint("⚠️ API call failed, using mock data: $apiError");
        final mockData = await MockBannerService.getMockBannerResponse();

        if (mockData["status"] == "success" && mockData["data"] != null) {
          final List<dynamic> data = mockData["data"];
          _banners = data.map((json) => BannerModel.fromJson(json)).toList();
          _isLoading = false;
          _hasError = false;
          debugPrint("✅ Successfully loaded ${_banners.length} mock banners");
        } else {
          throw Exception("Invalid mock data format");
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error refreshing banners: $e");

      // Try to use cached data if available, regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(BANNER_CACHE_KEY);

        if (cachedData != null) {
          final Map<String, dynamic> bannerCache = jsonDecode(cachedData);
          final List<dynamic> cachedBanners = bannerCache['data'];

          _banners =
              cachedBanners.map((json) => BannerModel.fromJson(json)).toList();
          _isLoading = false;
          _hasError = false;
          debugPrint("⚠️ Using cached banners due to refresh error");
          notifyListeners();
          return;
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear banner cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(BANNER_CACHE_KEY);
      debugPrint("✅ Banner cache cleared");
    } catch (e) {
      debugPrint("❌ Error clearing banner cache: $e");
    }
  }
}
