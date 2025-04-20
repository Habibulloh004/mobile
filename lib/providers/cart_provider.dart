import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/index.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  static const String CART_CACHE_KEY = 'cart_items';

  // Optional delivery info
  bool _isDelivery = true; // true = delivery, false = pickup
  double _deliveryFee = 10000; // 10,000 sum

  CartProvider() {
    _loadCartFromCache();
  }

  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isDelivery => _isDelivery;
  double get deliveryFee => _isDelivery ? _deliveryFee : 0;

  // Set delivery method
  void setDeliveryMethod(bool isDelivery) {
    _isDelivery = isDelivery;
    notifyListeners();
    _saveCartToCache();
  }

  // Load cart from local storage
  Future<void> _loadCartFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString(CART_CACHE_KEY);

      if (cartData != null && cartData.isNotEmpty) {
        final Map<String, dynamic> cartCache = jsonDecode(cartData);

        _cartItems = List<Map<String, dynamic>>.from(cartCache['items'] ?? []);
        _isDelivery = cartCache['isDelivery'] ?? true;

        debugPrint('✅ Loaded ${_cartItems.length} items from cart cache');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading cart from cache: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCartToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> cartData = {
        'items': _cartItems,
        'isDelivery': _isDelivery,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(CART_CACHE_KEY, jsonEncode(cartData));
      debugPrint('✅ Saved ${_cartItems.length} items to cart cache');
    } catch (e) {
      debugPrint('❌ Error saving cart to cache: $e');
    }
  }

  // Add item to cart
  void addItem(Map<String, dynamic> product) {
    debugPrint("📌 Adding item to cart: ${product['name']}");

    // Check if product already exists in cart
    final existingIndex = _cartItems.indexWhere(
            (item) => item['product_id'] == product['product_id']
    );

    if (existingIndex >= 0) {
      // If product exists, increase quantity
      _cartItems[existingIndex]['quantity'] += 1;
      debugPrint("🔄 Item already in cart, increased quantity to ${_cartItems[existingIndex]['quantity']}");
    } else {
      // If product is new, add it with quantity 1
      _cartItems.add({...product, 'quantity': 1});
      debugPrint("✅ New item added to cart: ${product['name']}");
    }

    notifyListeners();
    _saveCartToCache();
  }

  // Remove item from cart
  void removeItem(Map<String, dynamic> product) {
    debugPrint("🗑️ Removing item from cart: ${product['name']}");

    _cartItems.removeWhere((item) => item['product_id'] == product['product_id']);
    notifyListeners();
    _saveCartToCache();
  }

  // Update item quantity
  void updateQuantity(int productId, int change) {
    final index = _cartItems.indexWhere((item) => item['product_id'] == productId);

    if (index >= 0) {
      _cartItems[index]['quantity'] += change;

      if (_cartItems[index]['quantity'] <= 0) {
        // If quantity is 0 or less, remove item from cart
        _cartItems.removeAt(index);
        debugPrint("🗑️ Item removed from cart due to zero quantity");
      } else {
        debugPrint("🔄 Updated quantity to ${_cartItems[index]['quantity']}");
      }

      notifyListeners();
      _saveCartToCache();
    }
  }

  // Get total price of items in cart
  double get subtotal {
    double total = 0.0;
    for (var item in _cartItems) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    return total;
  }

  // Get total price including delivery
  double get total {
    return subtotal + (_isDelivery ? _deliveryFee : 0);
  }

  // Clear all items from cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    _saveCartToCache();
  }

  // Check if cart is empty
  bool get isEmpty => _cartItems.isEmpty;

  // Get total number of items in cart
  int get itemCount {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }
}