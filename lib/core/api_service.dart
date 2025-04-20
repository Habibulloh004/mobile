import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../constant/index.dart';

class ApiService {
  final Dio _dio = Dio();
  String? _systemToken;

  // Cache keys
  static const String ADMIN_CACHE_KEY = 'admin_data';
  static const String CATEGORIES_CACHE_KEY = 'categories_data';
  static const String PRODUCTS_CACHE_PREFIX = 'products_data_';

  // Cache durations in milliseconds
  static const int ADMIN_CACHE_DURATION = 30 * 24 * 60 * 60 * 1000; // 1 month
  static const int CATEGORIES_CACHE_DURATION = 3 * 60 * 60 * 1000; // 3 hours
  static const int PRODUCTS_CACHE_DURATION = 1 * 60 * 60 * 1000; // 1 hour

  // Initialize with a default token for fallback
  ApiService() {
    // Set a default token from constants if available
    _systemToken = Constants.defaultApiToken;
  }

  // Fetch admin data with caching
  Future<Map<String, dynamic>> fetchAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(ADMIN_CACHE_KEY);

      if (cachedData != null) {
        final Map<String, dynamic> adminDataCache = jsonDecode(cachedData);
        final int timestamp = adminDataCache['timestamp'] ?? 0;

        // Check if cache is still valid
        if (DateTime.now().millisecondsSinceEpoch - timestamp < ADMIN_CACHE_DURATION) {
          print('✅ Using cached admin data');
          final data = adminDataCache['data'];
          _systemToken = data['system_token'];
          return data;
        }
      }

      // Cache expired or not available, fetch from API
      final userId = Constants.userId;
      final apiBaseUrl = Constants.apiBaseUrl;

      final response = await _dio.get('$apiBaseUrl/public/mobileadmin/$userId')
          .timeout(Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200 && response.data["data"] != null) {
        final Map<String, dynamic> adminData = response.data["data"];
        _systemToken = adminData['system_token'];

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': adminData
        };

        await prefs.setString(ADMIN_CACHE_KEY, jsonEncode(cacheObject));
        print('✅ Admin data fetched and cached');
        return adminData;
      } else {
        throw Exception("Invalid response format from server");
      }
    } catch (e) {
      print("❌ Error fetching admin data: $e");
      // Use cached data if available, regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(ADMIN_CACHE_KEY);
        if (cachedData != null) {
          final Map<String, dynamic> adminDataCache = jsonDecode(cachedData);
          print('⚠️ Using expired cached admin data due to error');
          return adminDataCache['data'];
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      // Return an empty object with default token if no cache is available
      return {"system_token": Constants.defaultApiToken};
    }
  }

  // Get system token - use cached value if available
  Future<String> getSystemToken() async {
    if (_systemToken != null && _systemToken!.isNotEmpty) {
      return _systemToken!;
    }

    try {
      final adminData = await fetchAdminData();
      _systemToken = adminData['system_token'] ?? Constants.defaultApiToken;
      print("🤍 taken token $adminData");
      return _systemToken!;
    } catch (e) {
      print("❌ Error retrieving system token: $e");
      return Constants.defaultApiToken;
    }
  }

  // Fetch categories with caching
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(CATEGORIES_CACHE_KEY);

      if (cachedData != null) {
        final Map<String, dynamic> categoriesCache = jsonDecode(cachedData);
        final int timestamp = categoriesCache['timestamp'] ?? 0;

        // Check if cache is still valid (3 hours)
        if (DateTime.now().millisecondsSinceEpoch - timestamp < CATEGORIES_CACHE_DURATION) {
          print('✅ Using cached categories data');
          final List<dynamic> cachedCategories = categoriesCache['data'];
          return cachedCategories.map((json) => CategoryModel.fromJson(json)).toList();
        }
      }

      // Cache expired or not available, fetch from API
      final token = await getSystemToken();

      print('🔍 Fetching categories with token: $token');

      final response = await _dio.get('https://joinposter.com/api/menu.getCategories',
          queryParameters: {'token': token});

      print('📊 Categories API response status: ${response.statusCode}');
      print('📊 Categories API response data: ${response.data}');

      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> data = response.data["response"];
        print('📊 Number of categories: ${data.length}');

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data
        };

        await prefs.setString(CATEGORIES_CACHE_KEY, jsonEncode(cacheObject));
        print('✅ Categories fetched and cached');

        final categories = data.map((json) => CategoryModel.fromJson(json)).toList();
        print('📊 Parsed categories: ${categories.length}');
        return categories;
      } else {
        print('⚠️ Invalid response format for categories');
        return [];
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");

      // Try to get categories from cache regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(CATEGORIES_CACHE_KEY);
        if (cachedData != null) {
          final Map<String, dynamic> categoriesCache = jsonDecode(cachedData);
          final List<dynamic> cachedCategories = categoriesCache['data'];
          print('⚠️ Using expired cached categories due to error');
          return cachedCategories.map((json) => CategoryModel.fromJson(json)).toList();
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      return []; // Return empty list if all fails
    }
  }

  // Fetch products with caching
  Future<List<ProductModel>> fetchProducts(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = '$PRODUCTS_CACHE_PREFIX$categoryId';
      final String? cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final Map<String, dynamic> productsCache = jsonDecode(cachedData);
        final int timestamp = productsCache['timestamp'] ?? 0;

        // Check if cache is still valid (1 hour)
        if (DateTime.now().millisecondsSinceEpoch - timestamp < PRODUCTS_CACHE_DURATION) {
          print('✅ Using cached products data for category $categoryId');
          final List<dynamic> cachedProducts = productsCache['data'];
          return cachedProducts.map((json) => ProductModel.fromJson(json)).toList();
        }
      }

      // Cache expired or not available, fetch from API
      final token = await getSystemToken();

      final response = await _dio.get('https://joinposter.com/api/menu.getProducts',
          queryParameters: {'token': token, 'category_id': categoryId});

      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> data = response.data["response"];

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data
        };

        await prefs.setString(cacheKey, jsonEncode(cacheObject));
        print('✅ Products for category $categoryId fetched and cached');
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("❌ Error fetching products: $e");

      // Try to get products from cache regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String cacheKey = '$PRODUCTS_CACHE_PREFIX$categoryId';
        final String? cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final Map<String, dynamic> productsCache = jsonDecode(cachedData);
          final List<dynamic> cachedProducts = productsCache['data'];
          print('⚠️ Using expired cached products due to error');
          return cachedProducts.map((json) => ProductModel.fromJson(json)).toList();
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      return []; // Return empty list if all fails
    }
  }

  // Clear all caches
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (var key in keys) {
        if (key == ADMIN_CACHE_KEY ||
            key == CATEGORIES_CACHE_KEY ||
            key.startsWith(PRODUCTS_CACHE_PREFIX)) {
          await prefs.remove(key);
        }
      }
      print('✅ All API caches cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}