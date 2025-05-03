// lib/services/order_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../core/api_service.dart';

class OrderService {
  final ApiService _apiService;
  final Dio _dio = Dio();

  OrderService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Submits an order to Poster API
  ///
  /// Returns the order ID if successful, null otherwise
  Future<String?> submitOrder({
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

      if (response.statusCode == 200 && response.data != null) {
        // Extract order ID from response
        final orderId = response.data["response"]?.toString();
        debugPrint('✅ Order submitted successfully with ID: $orderId');
        return orderId;
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
}
