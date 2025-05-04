import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:poster_app/services/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/banner_model.dart';
import '../models/spot_model.dart';
import '../constant/index.dart';
import '../models/admin_model.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio();
  String? _systemToken;
  AdminModel? _adminData;

  // Cache keys
  static const String ADMIN_CACHE_KEY = 'admin_data';
  static const String CLIENT_CACHE_KEY = 'client_data';
  static const String CATEGORIES_CACHE_KEY = 'categories_data';
  static const String PRODUCTS_CACHE_PREFIX = 'products_data_';
  static const String USER_CACHE_KEY = 'user_data';
  static const String ORDERS_CACHE_KEY = 'orders_data';
  static const String BANNER_CACHE_KEY = 'banner_data';
  static const String SPOTS_CACHE_KEY = 'spots_data';

  // Flag to force refresh client data
  bool _forceRefreshClientData = false;

  // Cache durations in milliseconds
  static const int CATEGORIES_CACHE_DURATION = 3 * 60 * 60 * 1000; // 3 hours
  static const int PRODUCTS_CACHE_DURATION = 1 * 60 * 60 * 1000; // 1 hour
  static const int ORDERS_CACHE_DURATION = 24 * 60 * 60 * 1000; // 1 day
  static const int BANNER_CACHE_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days
  static const int ADMIN_CACHE_DURATION = 30 * 24 * 60 * 60 * 1000; // 30 days
  static const int SPOTS_CACHE_DURATION = 10 * 24 * 60 * 60 * 1000; // 10 days

  // Initialize with default token
  ApiService() {
    _systemToken = Constants.defaultApiToken;
    _initToken();
  }

  // Method to force refresh client data on next request
  void invalidateClientCache() {
    _forceRefreshClientData = true;
    debugPrint('📊 Client cache invalidated, will refresh on next request');
  }

  // Initialize token on startup
  Future<void> _initToken() async {
    try {
      await getSystemToken();
    } catch (e) {
      debugPrint("⚠️ Error initializing token: $e");
    }
  }

  Future<String> getSystemToken() async {
    // Check if we already have a cached token
    if (_systemToken != null && _systemToken!.isNotEmpty) {
      return _systemToken!;
    }

    try {
      // Try to fetch admin data which contains the token
      final adminData = await fetchAdminData();

      // Safely extract token using bracket notation
      if (adminData != null && adminData.containsKey('system_token')) {
        _systemToken = adminData['system_token'];

        // If token is non-empty, use it
        if (_systemToken != null && _systemToken!.isNotEmpty) {
          debugPrint(
            "🔑 Token retrieved: ${_systemToken!.length > 10 ? _systemToken!.substring(0, 10) + '...' : _systemToken}",
          );
          return _systemToken!;
        }
      }

      // If we get here, either adminData was null or token was empty
      // Fall back to default token
      debugPrint("⚠️ Using default token as no valid token was found");
      return Constants.defaultApiToken;
    } catch (e) {
      debugPrint("❌ Error retrieving system token: $e");
      return Constants.defaultApiToken;
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

        // Parse and store the delivery fee
        if (adminData.containsKey('delivery')) {
          debugPrint('✅ Retrieved delivery fee: ${adminData['delivery']}');
        } else {
          debugPrint('⚠️ Delivery fee not found in admin data');
        }

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

  Future<int> getDeliveryFee() async {
    debugPrint(
      '📦 getDeliveryFee called - fetching delivery fee from admin data',
    );

    try {
      // Fetch admin data which contains the delivery fee
      final adminData = await fetchAdminData();

      if (adminData != null) {
        // Debug log the raw data to see what's available
        debugPrint('📋 Admin data keys: ${adminData.keys.join(", ")}');

        if (adminData.containsKey('delivery')) {
          // Log the actual delivery value from admin data for debugging
          debugPrint(
            '📋 Raw delivery value: ${adminData['delivery']} (type: ${adminData['delivery'].runtimeType})',
          );

          // Parse the delivery fee with proper handling for different types
          var deliveryValue = adminData['delivery'];
          int deliveryFee = 0;

          try {
            // Handle different data types appropriately
            if (deliveryValue is int) {
              deliveryFee = deliveryValue;
              debugPrint('✅ Delivery fee parsed as int: $deliveryFee');
            } else if (deliveryValue is double) {
              deliveryFee = deliveryValue.toInt();
              debugPrint(
                '✅ Delivery fee parsed as double and converted to int: $deliveryFee',
              );
            } else if (deliveryValue is String) {
              // Try to parse as string
              String deliveryStr = deliveryValue.trim();

              // Handle empty strings
              if (deliveryStr.isEmpty) {
                debugPrint('⚠️ Delivery fee is empty string, returning 0');
                return 0;
              }

              // If string contains non-numeric chars, try to clean it
              if (!RegExp(r'^\d+$').hasMatch(deliveryStr)) {
                String cleanedStr = deliveryStr.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                debugPrint(
                  '🔄 Cleaned delivery string: "$deliveryStr" -> "$cleanedStr"',
                );
                deliveryStr = cleanedStr;
              }

              if (deliveryStr.isEmpty) {
                debugPrint('⚠️ Delivery fee contains no numbers, returning 0');
                return 0;
              }

              deliveryFee = int.parse(deliveryStr);
              debugPrint('✅ Delivery fee parsed from string: $deliveryFee');
            } else {
              // Unknown type, use default value of 0
              debugPrint('⚠️ Unknown delivery fee type, returning 0');
              deliveryFee = 0;
            }

            // Save to SharedPreferences to update the cached value
            try {
              final prefs = await SharedPreferences.getInstance();
              final String? cachedData = prefs.getString(ADMIN_CACHE_KEY);

              if (cachedData != null) {
                final Map<String, dynamic> adminDataCache = jsonDecode(
                  cachedData,
                );
                final Map<String, dynamic> data = adminDataCache['data'];

                // Update the delivery value in the cached data
                data['delivery'] = deliveryFee;

                // Save the updated data back to cache
                final Map<String, dynamic> updatedCache = {
                  'timestamp': adminDataCache['timestamp'],
                  'data': data,
                };

                await prefs.setString(
                  ADMIN_CACHE_KEY,
                  jsonEncode(updatedCache),
                );
                debugPrint(
                  '✅ Updated delivery fee in cached admin data: $deliveryFee',
                );
              }
            } catch (e) {
              debugPrint('⚠️ Error updating cached admin data: $e');
            }

            debugPrint('✅ Final delivery fee: $deliveryFee');
            return deliveryFee;
          } catch (e) {
            debugPrint('⚠️ Error parsing delivery fee: $e, returning 0');
            return 0;
          }
        } else {
          debugPrint(
            '⚠️ Delivery fee field not found in admin data, returning 0',
          );
          return 0;
        }
      } else {
        debugPrint('⚠️ Admin data is null, returning 0');
        return 0;
      }
    } catch (e) {
      debugPrint("❌ Error fetching admin data for delivery fee: $e");
      // Return 0 as a fallback
      return 0;
    }
  }

  // User authentication functions (modified for proper caching)
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

        // Find client with matching phone - try both phone and phone_number fields
        final client = clients.firstWhere(
          (c) => c["phone_number"] == cleanPhone || c["phone"] == cleanPhone,
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
            // Cache the complete response for client data
            final Map<String, dynamic> fullResponse = {
              "response": [client],
            };

            // Store the full response structure with the client data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString("userData", jsonEncode(fullResponse));

            // Also cache the individual client data as before (for backward compatibility)
            _cacheClientData(client, permanent: true);

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
          // Store in the new format compatible with the login function
          final Map<String, dynamic> fullResponse = {
            "response": [clientData],
          };

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("userData", jsonEncode(fullResponse));

          // Also cache using the old method for backward compatibility
          _cacheClientData(clientData, permanent: true);

          // After successful registration, fetch admin data to update caches
          await fetchAdminFromServer();
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

  // Method to fetch admin data after registration
  Future<void> fetchAdminFromServer() async {
    try {
      final userId = Constants.userId;
      final apiBaseUrl = Constants.apiBaseUrl;

      debugPrint('🔄 Updating admin data from server after registration...');

      // Use the correct endpoint as specified: /public/admins/{userId}
      final response = await _dio
          .get('$apiBaseUrl/public/admins/$userId')
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ Admin data updated successfully after registration');

        // Cache the admin data - could be processed further if needed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_data_full', jsonEncode(response.data));
      }
    } catch (e) {
      debugPrint('❌ Error updating admin data after registration: $e');
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

  Future<void> _cacheClientData(
    Map<String, dynamic> clientData, {
    bool permanent = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save essential client info for backward compatibility
      await prefs.setBool("isLoggedIn", true);
      await prefs.setInt(
        "client_id",
        int.parse(clientData["client_id"] ?? "0"),
      );
      await prefs.setString("name", clientData["lastname"] ?? "");

      // Store both phone formats if available
      await prefs.setString(
        "phone",
        clientData["phone_number"] ?? clientData["phone"] ?? "",
      );

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

      // For permanent cache (after login/register), store client data
      if (permanent) {
        // Store in the old format for backward compatibility
        await prefs.setString("client_data", jsonEncode(clientData));
        debugPrint('✅ Client data cached in legacy format');

        // Also ensure the userData format is stored (if not already)
        final String? existingUserData = prefs.getString("userData");
        if (existingUserData == null || existingUserData.isEmpty) {
          // Create the full response structure
          final Map<String, dynamic> fullResponse = {
            "response": [clientData],
          };
          await prefs.setString("userData", jsonEncode(fullResponse));
          debugPrint('✅ Client data cached in userData format');
        }
      } else {
        // Store with timestamp for normal cache invalidation (for the old format)
        final cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': clientData,
        };
        await prefs.setString(
          "client_data_with_timestamp",
          jsonEncode(cacheObject),
        );
        debugPrint('✅ Client data cached with timestamp');
      }
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

      // Check if we need to force refresh
      if (_forceRefreshClientData) {
        debugPrint('🔄 Forcing refresh of client data from server');
        _forceRefreshClientData = false; // Reset the flag

        // Fetch fresh data from server
        final clientId = prefs.getInt('client_id');
        if (clientId != null) {
          final freshData = await getClientById(clientId);
          if (freshData != null) {
            // Cache the fresh data (as permanent)
            _cacheClientData(freshData, permanent: true);
            return freshData;
          }
        }
      }

      // Try to get permanent cached data first
      final String? cachedData = prefs.getString('client_data');
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('✅ Using permanently cached client data');
        return jsonDecode(cachedData);
      }

      // If no permanent cache, try timestamp-based cache
      final String? timestampCachedData = prefs.getString(
        'client_data_with_timestamp',
      );
      if (timestampCachedData != null && timestampCachedData.isNotEmpty) {
        final cacheObject = jsonDecode(timestampCachedData);
        debugPrint('✅ Using timestamp-based client data cache');
        return cacheObject['data'];
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
      await prefs.remove("client_data_with_timestamp");

      debugPrint('✅ Client data cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing client data: $e');
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

  Future<List<SpotModel>> fetchSpots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(SPOTS_CACHE_KEY);

      if (cachedData != null) {
        final Map<String, dynamic> spotsCache = jsonDecode(cachedData);
        final int timestamp = spotsCache['timestamp'] ?? 0;

        // Check if cache is still valid (10 days)
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            SPOTS_CACHE_DURATION) {
          debugPrint('✅ Using cached spots data');
          final List<dynamic> cachedSpots = spotsCache['data'];
          return cachedSpots.map((json) => SpotModel.fromJson(json)).toList();
        }
      }

      // Cache expired or not available, fetch from API
      final token = await getSystemToken();

      debugPrint(
        '🔍 Fetching spots from API with token: ${token.substring(0, 10)}...',
      );

      final response = await _dio.get(
        'https://joinposter.com/api/access.getSpots',
        queryParameters: {'token': token},
      );

      debugPrint('📊 Spots API response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data["response"] != null) {
        final List<dynamic> data = response.data["response"];
        debugPrint('📊 Number of spots: ${data.length}');

        // Cache the response with timestamp
        final Map<String, dynamic> cacheObject = {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        };

        await prefs.setString(SPOTS_CACHE_KEY, jsonEncode(cacheObject));
        debugPrint('✅ Spots fetched and cached');

        final spots = data.map((json) => SpotModel.fromJson(json)).toList();
        debugPrint('📊 Parsed spots: ${spots.length}');
        return spots;
      } else {
        debugPrint('⚠️ Invalid response format for spots');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching spots: $e");

      // Try to get spots from cache regardless of age
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? cachedData = prefs.getString(SPOTS_CACHE_KEY);
        if (cachedData != null) {
          final Map<String, dynamic> spotsCache = jsonDecode(cachedData);
          final List<dynamic> cachedSpots = spotsCache['data'];
          debugPrint('⚠️ Using expired cached spots due to error');
          return cachedSpots.map((json) => SpotModel.fromJson(json)).toList();
        }
      } catch (_) {
        // Ignore cache reading errors
      }

      return []; // Return empty list if all fails
    }
  }

  // Fixed fetchOrderHistory method for ApiService
  // Place this method in lib/core/api_service.dart

  Future<List<OrderModel>> fetchOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is logged in
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (!isLoggedIn) {
        return [];
      }

      // Create an instance of OrderService
      final orderService = OrderService(apiService: this);

      // Get orders from local storage
      final ordersList = await orderService.getLocalOrders();

      if (ordersList.isEmpty) {
        debugPrint('📋 No orders found in history, returning empty list');
        return [];
      }

      // Convert the raw order data to OrderModel objects
      final List<OrderModel> orderModels = [];

      for (var orderData in ordersList) {
        try {
          // Extract items from the order data
          final List<Map<String, dynamic>> itemsData =
              List<Map<String, dynamic>>.from(orderData['items'] ?? []);

          // Convert to OrderItem objects
          final List<OrderItem> orderItems =
              itemsData.map((item) {
                // Keep modification as is - can be String, Map or null
                // The OrderItem constructor will handle it
                return OrderItem(
                  id: item['product_id'].toString(),
                  name: item['name'] ?? 'Unknown Product',
                  price: item['price'] ?? 0,
                  imageUrl: item['imageUrl'] ?? 'assets/images/no_image.png',
                  quantity: item['quantity'] ?? 1,
                  modification: item['modification'], // Pass as is
                );
              }).toList();

          // Create OrderModel
          final OrderModel order = OrderModel(
            id:
                orderData['order_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            date:
                orderData['date'] ?? DateTime.now().toString().substring(0, 10),
            items: orderItems,
            subtotal: orderData['subtotal'] ?? 0,
            deliveryFee: orderData['delivery_fee'] ?? 0,
            total: orderData['total'] ?? 0,
            status: orderData['status'] ?? 'В обработке',
            deliveryType:
                orderData['is_delivery'] == true ? 'delivery' : 'pickup',
            address: orderData['address'],
            spotId: orderData['spot_id'],
            spotName: orderData['spot_name'],
          );

          orderModels.add(order);
        } catch (e) {
          debugPrint('❌ Error parsing order: $e');
          // Print more debug info to help diagnose the problem
          debugPrint('Order data causing error: ${orderData.toString()}');
        }
      }

      // Sort orders by date (newest first)
      orderModels.sort((a, b) {
        final DateTime dateA = _parseDate(a.date);
        final DateTime dateB = _parseDate(b.date);
        return dateB.compareTo(dateA);
      });

      debugPrint(
        '📋 Successfully loaded ${orderModels.length} orders from local storage',
      );
      return orderModels;
    } catch (e) {
      debugPrint('❌ Error fetching order history: $e');
      return [];
    }
  }

  // Helper method to parse date strings
  DateTime _parseDate(String date) {
    try {
      // Check if date is in format DD.MM.YYYY
      if (date.contains('.')) {
        final parts = date.split('.');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      }

      // Fallback to parsing ISO date
      return DateTime.parse(date);
    } catch (e) {
      // Return current date if parsing fails
      return DateTime.now();
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
