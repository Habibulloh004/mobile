import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/index.dart';
import '../models/product_model.dart';

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

  // Find an item in the cart by product ID and modification ID
  int _findCartItemIndex(Map<String, dynamic> product) {
    // Extract the modification ID if present
    final String? modificationId =
        product.containsKey('modification') && product['modification'] != null
            ? product['modification']['id']?.toString()
            : null;

    for (int i = 0; i < _cartItems.length; i++) {
      final item = _cartItems[i];

      // If product IDs don't match, this is not our item
      if (item['product_id'] != product['product_id']) {
        continue;
      }

      // Check modification match
      final bool itemHasModification =
          item.containsKey('modification') && item['modification'] != null;
      final String? itemModificationId =
          itemHasModification ? item['modification']['id']?.toString() : null;

      // Both have the same modification status (either both have modifications or neither does)
      if ((modificationId == null && itemModificationId == null) ||
          (modificationId != null && itemModificationId == modificationId)) {
        return i;
      }
    }

    return -1; // Item not found
  }

  void addItem(Map<String, dynamic> product) {
    debugPrint("📌 Adding item to cart: ${product['name']}");

    // Find this exact product in the cart
    final existingIndex = _findCartItemIndex(product);

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

    final index = _findCartItemIndex(product);
    if (index >= 0) {
      _cartItems.removeAt(index);
      notifyListeners();
      _saveCartToCache();
      debugPrint("✅ Item removed successfully");
    } else {
      debugPrint("⚠️ Item not found in cart");
    }
  }

  void updateQuantity(int productId, int change, {String? modificationId}) {
    // Create a dummy product to use _findCartItemIndex
    final Map<String, dynamic> dummyProduct = {'product_id': productId};

    // Add modification if provided
    if (modificationId != null) {
      dummyProduct['modification'] = {'id': modificationId};
    }

    final index = _findCartItemIndex(dummyProduct);

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

  // Add a product model directly to cart
  void addProductModel(ProductModel product) {
    final cartItem = product.toCartItem();
    addItem(cartItem);
  }
}
