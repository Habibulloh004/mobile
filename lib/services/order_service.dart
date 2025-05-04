// lib/services/order_service.dart - Updated to save orders locally
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../core/api_service.dart';

class OrderService {
  final ApiService _apiService;
  final Dio _dio = Dio();

  // Cache key for orders
  static const String ORDERS_CACHE_KEY = 'local_orders';

  OrderService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Submits an order to Poster API and saves it locally on success
  ///
  /// Returns the order ID if successful, null otherwise
  // Updated submitOrder method in the OrderService class
  Future<Map<String, dynamic>?> submitOrder({
    required List<Map<String, dynamic>> cartItems,
    required String phone,
    required String deliveryType, // "delivery" or "take away"
    required int appliedBonus,
    required String address,
    required String paymentMethod, // "card" or "cash"
    required String comment,
    required int deliveryFee,
    required String? spotId,
  }) async {
    try {
      debugPrint('🚀 Submitting order to Poster API...');

      // Get system token
      final token = await _apiService.getSystemToken();
      debugPrint('🔑 Using token: ${token.substring(0, 10)}...');

      // Format phone number (remove non-digit characters)
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      // Prepare products array
      final List<Map<String, dynamic>> formattedProducts = [];

      // Deep copy of cart items to preserve all details
      final List<Map<String, dynamic>> cartItemsCopy =
          cartItems.map((item) {
            return Map<String, dynamic>.from(item);
          }).toList();

      // Process items for API submission
      for (var item in cartItems) {
        final int productId = item['product_id'];
        final int quantity = item['quantity'] ?? 1;

        // Check modification type to format correctly
        if (item.containsKey('modification')) {
          // Case 1: Group modifications (string format)
          if (item['modification'] is String &&
              item['modification'].toString().isNotEmpty) {
            formattedProducts.add({
              "product_id": productId,
              "modification": item['modification'],
              "count": quantity,
            });
          }
          // Case 2: Regular modifications (object format)
          else if (item['modification'] is Map) {
            final modificationId = item['modification']['id'];
            formattedProducts.add({
              "product_id": productId,
              "modificator_id": modificationId,
              "count": quantity,
            });
          }
          // Case 3: Simple product with no modifications
          else {
            formattedProducts.add({"product_id": productId, "count": quantity});
          }
        }
        // Simple product with no modifications
        else {
          formattedProducts.add({"product_id": productId, "count": quantity});
        }
      }

      // Prepare comment object
      final Map<String, dynamic> commentObj = {
        "delivery_type": deliveryType == "delivery" ? "delivery" : "take away",
        "bonus": appliedBonus.toString(),
        "address": address,
        "payed_type": paymentMethod == "card" ? "card" : "cash",
        "comment": comment,
        "client_number": cleanPhone,
        "delivery_sum":
            deliveryType == "delivery" ? deliveryFee.toString() : "0",
      };

      // Build final request payload
      final Map<String, dynamic> payload = {
        "spot_id":
            deliveryType == "delivery"
                ? 1 // Default spot for delivery
                : int.tryParse(spotId ?? "1") ??
                    1, // Selected spot for takeaway
        "phone": cleanPhone,
        "products": formattedProducts,
        "comment": jsonEncode(commentObj), // Stringify comment object
      };

      debugPrint('📦 Order payload: ${jsonEncode(payload)}');

      // Submit order to Poster API
      final response = await _dio.post(
        'https://joinposter.com/api/incomingOrders.createIncomingOrder',
        queryParameters: {'token': token},
        data: payload,
      );

      if (response.statusCode == 200 && response.data["response"] != null) {
        // Extract order ID and full response for passing to the confirmation page
        final responseData = response.data["response"];
        debugPrint('✅ Order submitted successfully with ID: $responseData');

        // Get spot name if applicable
        String? spotName;
        if (deliveryType != "delivery" && spotId != null) {
          // Attempt to get spot name from API or other source
          // This would be better provided by a spot service
          debugPrint('🔍 Getting spot name for ID: $spotId');
        }

        // Create result object with order ID and original cart items
        // This ensures we maintain the original item data for the confirmation page
        final orderResult = {
          "order_id": responseData["incoming_order_id"]?.toString() ?? "",
          "items": cartItemsCopy, // Pass the complete original cart items
          "total": 0, // Will be calculated on confirmation page
          "subtotal": 0, // Will be calculated on confirmation page
          "delivery_fee": deliveryFee,
          "applied_bonus": appliedBonus,
          "address": address,
          "is_delivery": deliveryType == "delivery",
          "payment_method": paymentMethod,
          "spot_id": spotId,
          "spot_name": spotName, // Include spot name if available
        };

        // Save the order to local storage
        await _saveOrderLocally(orderResult);

        return orderResult;
      } else {
        debugPrint(
          '❌ Failed to submit order: ${response.statusCode} - ${response.data}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error submitting order: $e');
      return null;
    }
  }

  /// Save an order to local storage
  Future<void> _saveOrderLocally(Map<String, dynamic> orderData) async {
    try {
      debugPrint('💾 Saving order locally...');
      final prefs = await SharedPreferences.getInstance();

      // Get existing orders
      final String? existingOrdersJson = prefs.getString(ORDERS_CACHE_KEY);
      List<Map<String, dynamic>> orders = [];

      if (existingOrdersJson != null) {
        final List<dynamic> decodedOrders = jsonDecode(existingOrdersJson);
        orders = decodedOrders.cast<Map<String, dynamic>>();
      }

      // Calculate total and subtotal based on cart items
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        orderData['items'],
      );
      int subtotal = 0;

      // Process each item to ensure we preserve all modification details
      for (var item in items) {
        final int price = item['price'] ?? 0;
        final int quantity = item['quantity'] ?? 1;
        subtotal += price * quantity;

        // Debug log for item processing
        debugPrint('📦 Processing item for storage: ${item['name']}');

        // Make sure all modification details are preserved
        if (item.containsKey('modification_details')) {
          debugPrint('📦 Item has modification_details, preserving them');
        } else if (item.containsKey('modification') &&
            item['modification'] is Map) {
          // If we have a regular modification without details, create details
          debugPrint('📦 Creating modification_details for regular mod');
          item['modification_details'] = [item['modification']];
        }
      }

      // Update totals
      orderData['subtotal'] = subtotal;
      orderData['total'] =
          subtotal +
          (orderData['delivery_fee'] ?? 0) -
          (orderData['applied_bonus'] ?? 0);

      // Add date and status
      orderData['date'] = DateTime.now()
          .toString()
          .substring(0, 10)
          .replaceAll('-', '.');

      // Add to orders list
      orders.add(orderData);

      // Save back to prefs
      await prefs.setString(ORDERS_CACHE_KEY, jsonEncode(orders));
      debugPrint('✅ Order saved locally successfully');
    } catch (e) {
      debugPrint('❌ Error saving order locally: $e');
    }
  }

  /// Get all orders from local storage
  Future<List<Map<String, dynamic>>> getLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersJson = prefs.getString(ORDERS_CACHE_KEY);

      if (ordersJson != null) {
        final List<dynamic> decodedOrders = jsonDecode(ordersJson);
        debugPrint('📋 Found ${decodedOrders.length} local orders');
        return decodedOrders.cast<Map<String, dynamic>>();
      }

      debugPrint('📋 No local orders found');
      return [];
    } catch (e) {
      debugPrint('❌ Error retrieving local orders: $e');
      return [];
    }
  }
}
