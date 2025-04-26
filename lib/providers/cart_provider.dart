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

  // Update the CartProvider methods to handle both types of modifications

  void addItem(Map<String, dynamic> product) {
    debugPrint("📌 Adding item to cart: ${product['name']}");

    // Check if product has a modification
    bool hasModification =
        product.containsKey('modification') && product['modification'] != null;

    // Create a unique identifier that includes both product ID and modification ID (if any)
    String uniqueId = product['product_id'].toString();
    if (hasModification) {
      uniqueId += "_${product['modification']['id']}";
    }

    // Check if this exact product (with the same modification if any) already exists in cart
    final existingIndex = _cartItems.indexWhere((item) {
      // If the base product IDs don't match, it's definitely different
      if (item['product_id'] != product['product_id']) return false;

      // If one has a modification and the other doesn't, they're different
      bool itemHasModification =
          item.containsKey('modification') && item['modification'] != null;
      if (hasModification != itemHasModification) return false;

      // If both have modifications, compare the modification IDs
      if (hasModification && itemHasModification) {
        return item['modification']['id'] == product['modification']['id'];
      }

      // If we got here, both products have the same ID and neither has a modification
      return true;
    });

    if (existingIndex >= 0) {
      // If exact same product exists (including modification), update its quantity
      // If the product has a specified quantity, use it, otherwise increment by 1
      if (product.containsKey('quantity') && product['quantity'] > 0) {
        _cartItems[existingIndex]['quantity'] = product['quantity'];
        debugPrint(
          "🔄 Item updated in cart with quantity: ${product['quantity']}",
        );
      } else {
        _cartItems[existingIndex]['quantity'] += 1;
        debugPrint(
          "🔄 Item quantity incremented to: ${_cartItems[existingIndex]['quantity']}",
        );
      }
    } else {
      // If product is new, add it with specified quantity or default to 1
      int quantity =
          (product.containsKey('quantity') && product['quantity'] > 0)
              ? product['quantity']
              : 1;

      _cartItems.add({...product, 'quantity': quantity});
      debugPrint(
        "✅ New item added to cart: ${product['name']} (Qty: $quantity)",
      );
    }

    notifyListeners();
    _saveCartToCache();
  }

  void removeItem(Map<String, dynamic> product) {
    debugPrint("🗑️ Removing item from cart: ${product['name']}");

    bool hasModification =
        product.containsKey('modification') && product['modification'] != null;

    _cartItems.removeWhere((item) {
      // If product IDs don't match, keep the item
      if (item['product_id'] != product['product_id']) return false;

      // If one has a modification and the other doesn't, they're different
      bool itemHasModification =
          item.containsKey('modification') && item['modification'] != null;
      if (hasModification != itemHasModification) return false;

      // If both have modifications, compare the modification IDs
      if (hasModification && itemHasModification) {
        return item['modification']['id'] == product['modification']['id'];
      }

      // If we got here, both products have the same ID and neither has a modification
      return true;
    });

    notifyListeners();
    _saveCartToCache();
  }

  void updateQuantity(int productId, int change, {String? modificationId}) {
    // Find the item in the cart based on product ID and modification ID (if provided)
    final index = _cartItems.indexWhere((item) {
      // Check product ID match
      if (item['product_id'] != productId) return false;

      // If modification ID is provided, check for exact match
      if (modificationId != null) {
        bool hasModification =
            item.containsKey('modification') &&
            item['modification'] != null &&
            item['modification']['id'] != null;

        if (!hasModification)
          return false; // This item doesn't have modifications

        return item['modification']['id'] == modificationId;
      }

      // If no modification ID provided, only match products without modifications
      return !item.containsKey('modification') || item['modification'] == null;
    });

    if (index >= 0) {
      // Update the quantity
      _cartItems[index]['quantity'] += change;

      // Ensure quantity never goes below 1
      if (_cartItems[index]['quantity'] <= 0) {
        // Remove item from cart
        _cartItems.removeAt(index);
        debugPrint("🗑️ Item removed from cart due to zero quantity");
      } else {
        debugPrint("🔄 Updated quantity to ${_cartItems[index]['quantity']}");
      }

      notifyListeners();
      _saveCartToCache();
    } else {
      debugPrint("⚠️ Failed to find item in cart for updating quantity");
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
