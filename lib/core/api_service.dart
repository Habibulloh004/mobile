import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/banner_model.dart';
import '../constant/index.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio();
  String? _systemToken;

  // Cache keys
  static const String ADMIN_CACHE_KEY = 'admin_data';
  static const String CATEGORIES_CACHE_KEY = 'categories_data';
  static const String PRODUCTS_CACHE_PREFIX = 'products_data_';
  static const String USER_CACHE_KEY = 'user_data';
  static const String ORDERS_CACHE_KEY = 'orders_data';
  static const String BANNER_CACHE_KEY = 'banner_data';

  // Cache durations in milliseconds
  static const int ADMIN_CACHE_DURATION = 30 * 24 * 60 * 60 * 1000; // 1 month
  static const int CATEGORIES_CACHE_DURATION = 3 * 60 * 60 * 1000; // 3 hours
  static const int PRODUCTS_CACHE_DURATION = 1 * 60 * 60 * 1000; // 1 hour
  static const int ORDERS_CACHE_DURATION = 24 * 60 * 60 * 1000; // 1 day
  static const int BANNER_CACHE_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days

  // Initialize with a default token for fallback
  ApiService() {
    // Set a default token from constants if available
    _systemToken = Constants.defaultApiToken;
    _initToken();
  }

  // Initialize token on startup
  Future<void> _initToken() async {
    try {
      await getSystemToken();
    } catch (e) {
      debugPrint("⚠️ Error initializing token: $e");
    }
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
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            ADMIN_CACHE_DURATION) {
          debugPrint('✅ Using cached admin data');
          final data = adminDataCache['data'];
          _systemToken = data['system_token'];
          return data;
        }
      }

      // Cache expired or not available, fetch from API
      final userId = Constants.userId;
      final apiBaseUrl = Constants.apiBaseUrl;

      final response = await _dio
          .get('$apiBaseUrl/public/mobileadmin/$userId')
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 && response.data["data"] != null) {
        final Map<String, dynamic> adminData = response.data["data"];
        _systemToken = adminData['system_token'];

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': adminData,
        };

        await prefs.setString(ADMIN_CACHE_KEY, jsonEncode(cacheObject));
        debugPrint('✅ Admin data fetched and cached');
        return adminData;
      } else {
        throw Exception("Invalid response format from server");
      }
    } catch (e) {
      debugPrint("❌ Error fetching admin data: $e");
      // Use cached data if available, regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(ADMIN_CACHE_KEY);
        if (cachedData != null) {
          final Map<String, dynamic> adminDataCache = jsonDecode(cachedData);
          debugPrint('⚠️ Using expired cached admin data due to error');
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
      debugPrint("🔑 Token retrieved: ${_systemToken!.substring(0, 10)}...");
      return _systemToken!;
    } catch (e) {
      debugPrint("❌ Error retrieving system token: $e");
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
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            CATEGORIES_CACHE_DURATION) {
          debugPrint('✅ Using cached categories data');
          final List<dynamic> cachedCategories = categoriesCache['data'];
          return cachedCategories
              .map((json) => CategoryModel.fromJson(json))
              .toList();
        }
      }

      // Cache expired or not available, fetch from API
      final token = await getSystemToken();

      debugPrint(
        '🔍 Fetching categories with token: ${token.substring(0, 10)}...',
      );

      final response = await _dio.get(
        'https://joinposter.com/api/menu.getCategories',
        queryParameters: {'token': token},
      );

      debugPrint('📊 Categories API response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> data = response.data["response"];
        debugPrint('📊 Number of categories: ${data.length}');

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        };

        await prefs.setString(CATEGORIES_CACHE_KEY, jsonEncode(cacheObject));
        debugPrint('✅ Categories fetched and cached');

        final categories =
            data.map((json) => CategoryModel.fromJson(json)).toList();
        debugPrint('📊 Parsed categories: ${categories.length}');
        return categories;
      } else {
        debugPrint('⚠️ Invalid response format for categories');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching categories: $e");

      // Try to get categories from cache regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(CATEGORIES_CACHE_KEY);
        if (cachedData != null) {
          final Map<String, dynamic> categoriesCache = jsonDecode(cachedData);
          final List<dynamic> cachedCategories = categoriesCache['data'];
          debugPrint('⚠️ Using expired cached categories due to error');
          return cachedCategories
              .map((json) => CategoryModel.fromJson(json))
              .toList();
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
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            PRODUCTS_CACHE_DURATION) {
          debugPrint('✅ Using cached products data for category $categoryId');
          final List<dynamic> cachedProducts = productsCache['data'];
          return cachedProducts
              .map((json) => ProductModel.fromJson(json))
              .toList();
        }
      }

      // Cache expired or not available, fetch from API
      final token = await getSystemToken();

      final response = await _dio.get(
        'https://joinposter.com/api/menu.getProducts',
        queryParameters: {'token': token, 'category_id': categoryId},
      );

      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> data = response.data["response"];
        debugPrint(
          '📊 Fetched ${data.length} products for category $categoryId',
        );

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        };

        await prefs.setString(cacheKey, jsonEncode(cacheObject));
        debugPrint('✅ Products for category $categoryId fetched and cached');
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        debugPrint('⚠️ Invalid response for products in category $categoryId');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching products: $e");

      // Try to get products from cache regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String cacheKey = '$PRODUCTS_CACHE_PREFIX$categoryId';
        final String? cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final Map<String, dynamic> productsCache = jsonDecode(cachedData);
          final List<dynamic> cachedProducts = productsCache['data'];
          debugPrint('⚠️ Using expired cached products due to error');
          return cachedProducts
              .map((json) => ProductModel.fromJson(json))
              .toList();
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      return []; // Return empty list if all fails
    }
  }

  // Fetch banners with caching
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(BANNER_CACHE_KEY);

      if (cachedData != null) {
        final Map<String, dynamic> bannersCache = jsonDecode(cachedData);
        final int timestamp = bannersCache['timestamp'] ?? 0;

        // Check if cache is still valid (7 days)
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            BANNER_CACHE_DURATION) {
          debugPrint('✅ Using cached banners data');
          final List<dynamic> cachedBanners = bannersCache['data'];
          return cachedBanners
              .map((json) => BannerModel.fromJson(json))
              .toList();
        }
      }

      // Cache expired or not available, fetch from API
      final userId = Constants.userId;
      final apiBaseUrl = Constants.apiBaseUrl;

      debugPrint('🔍 Fetching banners from API');

      final response = await _dio
          .get('$apiBaseUrl/public/mobilebanner/$userId')
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 && response.data["data"] != null) {
        final List<dynamic> data = response.data["data"];
        debugPrint('📊 Number of banners: ${data.length}');

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        };

        await prefs.setString(BANNER_CACHE_KEY, jsonEncode(cacheObject));
        debugPrint('✅ Banners fetched and cached');

        final banners = data.map((json) => BannerModel.fromJson(json)).toList();
        debugPrint('📊 Parsed banners: ${banners.length}');
        return banners;
      } else {
        debugPrint('⚠️ Invalid response format for banners');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching banners: $e");

      // Try to get banners from cache regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(BANNER_CACHE_KEY);
        if (cachedData != null) {
          final Map<String, dynamic> bannersCache = jsonDecode(cachedData);
          final List<dynamic> cachedBanners = bannersCache['data'];
          debugPrint('⚠️ Using expired cached banners due to error');
          return cachedBanners
              .map((json) => BannerModel.fromJson(json))
              .toList();
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      return []; // Return empty list if all fails
    }
  }

  // User authentication functions
  Future<Map<String, dynamic>?> loginUser(String phone, String password) async {
    try {
      debugPrint('🔑 Attempting login with phone: $phone');

      // Clean the phone number (remove +, spaces)
      String cleanPhone = phone.replaceAll("+", "").replaceAll(" ", "").trim();

      final response = await _dio.get(
        'https://joinposter.com/api/clients.getClients',
        queryParameters: {'token': await getSystemToken()},
      );

      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> clients = response.data["response"];

        // Find client with matching phone
        final client = clients.firstWhere(
          (c) => c["phone_number"] == cleanPhone,
          orElse: () => null,
        );

        if (client != null) {
          // Extract password from JSON comment field
          String? comment = client["comment"];
          String extractedPassword = "";

          if (comment != null && comment.isNotEmpty) {
            try {
              // Parse the JSON comment
              final commentJson = jsonDecode(comment);
              extractedPassword = commentJson["password"] ?? "";
            } catch (e) {
              debugPrint('❌ Error parsing comment JSON: $e');
            }
          }

          if (extractedPassword == password) {
            // Cache the client data
            _cacheClientData(client);

            debugPrint('✅ Login successful for user: ${client["lastname"]}');
            return client;
          } else {
            debugPrint('❌ Password mismatch');
            return null;
          }
        }
      }

      debugPrint('❌ User not found or invalid response');
      return null;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return null;
    }
  }

  Future<int?> registerUser(String name, String phone, String password) async {
    try {
      debugPrint('🔑 Attempting registration for: $name, $phone');

      // Clean the phone number (remove +, spaces)
      String cleanPhone = phone.replaceAll("+", "").replaceAll(" ", "").trim();

      // Create JSON string for comment
      final commentJson = jsonEncode({"password": password});

      final response = await _dio.post(
        'https://joinposter.com/api/clients.createClient',
        queryParameters: {'token': await getSystemToken()},
        data: {
          'client_name': name,
          'client_groups_id_client': 1,
          'phone': cleanPhone,
          'comment': commentJson, // Use JSON string
        },
      );

      if (response.statusCode == 200 && response.data["response"] != null) {
        final int clientId = response.data["response"];

        // After registration, get the full client data
        final clientData = await getClientById(clientId);
        if (clientData != null) {
          // Cache the client data
          _cacheClientData(clientData);
        }

        debugPrint('✅ Registration successful with ID: $clientId');
        return clientId;
      }

      debugPrint('❌ Registration failed: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getClientById(int clientId) async {
    try {
      final response = await _dio.get(
        'https://joinposter.com/api/clients.getClient',
        queryParameters: {
          'token': await getSystemToken(),
          'client_id': clientId,
        },
      );

      if (response.statusCode == 200 && response.data["response"] != null) {
        final clientData = response.data["response"];
        return clientData;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching client data: $e');
      return null;
    }
  }

  Future<void> _cacheClientData(Map<String, dynamic> clientData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save essential client info
      await prefs.setBool("isLoggedIn", true);
      await prefs.setInt(
        "client_id",
        int.parse(clientData["client_id"] ?? "0"),
      );
      await prefs.setString("name", clientData["lastname"] ?? "");
      await prefs.setString("phone", clientData["phone_number"] ?? "");
      await prefs.setString("bonus", clientData["bonus"] ?? "0");
      await prefs.setString("discount", clientData["discount_per"] ?? "0");

      // Cache addresses if available
      if (clientData["addresses"] != null &&
          clientData["addresses"].isNotEmpty) {
        List<dynamic> addresses = clientData["addresses"];
        List<String> addressList =
            addresses
                .map<String>((addr) => (addr["address1"] ?? "").toString())
                .where((addr) => addr.isNotEmpty)
                .toList();

        await prefs.setStringList("addresses", addressList);
      }

      // Cache the full response for advanced usage
      await prefs.setString("client_data", jsonEncode(clientData));

      debugPrint('✅ Client data cached successfully');
    } catch (e) {
      debugPrint('❌ Error caching client data: $e');
    }
  }

  Future<Map<String, dynamic>?> getLoggedInClientData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!isLoggedIn) {
        return null;
      }

      final String? cachedData = prefs.getString('client_data');
      if (cachedData != null && cachedData.isNotEmpty) {
        return jsonDecode(cachedData);
      }

      // If we have client ID but no cached data, fetch from API
      final clientId = prefs.getInt('client_id');
      if (clientId != null) {
        return await getClientById(clientId);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error retrieving client data: $e');
      return null;
    }
  }

  Future<void> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all client-related data
      await prefs.setBool("isLoggedIn", false);
      await prefs.remove("client_id");
      await prefs.remove("name");
      await prefs.remove("phone");
      await prefs.remove("bonus");
      await prefs.remove("discount");
      await prefs.remove("addresses");
      await prefs.remove("client_data");

      debugPrint('✅ Client data cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing client data: $e');
    }
  }

  // Mock orders for order history
  // Update this method in your ApiService class to match the OrderModel and OrderItem constructors

  // Mock orders for order history
  Future<List<OrderModel>> fetchOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is logged in
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (!isLoggedIn) {
        return [];
      }

      // For now, return mock data
      // In a real app, this would make an API call
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Simulate network delay

      return [
        OrderModel(
          id: "1",
          // Changed to String
          date: '01.03.2025',
          items: [
            OrderItem(
              id: "101",
              // Changed from productId to id
              name: 'Биг чизбургер',
              price: 3500000,
              imageUrl: 'assets/images/no_image.png',
              quantity: 2,
            ),
            OrderItem(
              id: "102",
              // Changed from productId to id
              name: 'Чизбургер',
              price: 3500000,
              imageUrl: 'assets/images/no_image.png',
              quantity: 2,
            ),
          ],
          subtotal: 14000000,
          deliveryFee: 1000000,
          total: 15000000,
          status: 'Доставлен',
          deliveryType: 'delivery',
        ),
        OrderModel(
          id: "2",
          // Changed to String
          date: '01.03.2025',
          items: [
            OrderItem(
              id: "103",
              // Changed from productId to id
              name: 'Биг чизбургер',
              price: 3500000,
              imageUrl: 'assets/images/no_image.png',
              quantity: 2,
            ),
            OrderItem(
              id: "104",
              // Changed from productId to id
              name: 'Чизбургер',
              price: 3500000,
              imageUrl: 'assets/images/no_image.png',
              quantity: 2,
            ),
          ],
          subtotal: 14000000,
          deliveryFee: 1000000,
          total: 15000000,
          status: 'В пути',
          deliveryType: 'delivery',
        ),
        OrderModel(
          id: "3",
          // Changed to String
          date: '01.03.2025',
          items: [
            OrderItem(
              id: "105",
              // Changed from productId to id
              name: 'Биг чизбургер',
              price: 3500000,
              imageUrl: 'assets/images/no_image.png',
              quantity: 2,
            ),
            OrderItem(
              id: "106",
              // Changed from productId to id
              name: 'Чизбургер',
              price: 3500000,
              imageUrl: 'assets/images/no_image.png',
              quantity: 2,
            ),
          ],
          subtotal: 14000000,
          deliveryFee: 1000000,
          total: 15000000,
          status: 'Доставлен',
          deliveryType: 'pickup',
        ),
      ];
    } catch (e) {
      debugPrint('❌ Error fetching order history: $e');
      return [];
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
            key == BANNER_CACHE_KEY ||
            key.startsWith(PRODUCTS_CACHE_PREFIX)) {
          await prefs.remove(key);
        }
      }
      debugPrint('✅ All API caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
}
