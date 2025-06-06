// lib/providers/cart_provider.dart - Update to handle delivery fee properly

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/index.dart';
import '../models/product_model.dart';
import '../core/api_service.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  static const String CART_CACHE_KEY = 'cart_items';

  // Delivery info
  bool _isDelivery = true; // true = delivery, false = pickup
  int _deliveryFee = 0; // Initialize with 0

  // Remove the loading indicator flag since we don't need it anymore
  // bool _isLoadingDeliveryFee = false;

  final ApiService _apiService;

  CartProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService() {
    _loadCartFromCache();
    // Immediately start loading the delivery fee
    _loadDeliveryFee();
  }

  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;

  bool get isDelivery => _isDelivery;

  // Delivery fee getter - always return the actual loaded value
  int get deliveryFee {
    // If delivery is not selected, return 0 regardless
    if (!_isDelivery) return 0;

    // Log the current delivery fee value
    debugPrint('📦 Current delivery fee: $_deliveryFee');

    // Return the actual loaded value
    return _deliveryFee;
  }

  // Remove the isLoadingDeliveryFee getter since we're not using loaders anymore
  // bool get isLoadingDeliveryFee => _isLoadingDeliveryFee;

  // Load delivery fee from admin data - simplified since we're not showing loaders
  Future<void> _loadDeliveryFee() async {
    debugPrint('📦 Loading delivery fee from admin data...');

    try {
      // Call the getDeliveryFee method from ApiService
      final loadedFee = await _apiService.getDeliveryFee();

      // Log the loaded fee for debugging
      debugPrint('✅ Successfully loaded delivery fee: $loadedFee');

      // Set the delivery fee
      _deliveryFee = loadedFee;

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading delivery fee: $e');
      // Keep _deliveryFee as is in case of error, we don't need to set a default anymore
      notifyListeners();
    }
  }

  // Force reload the delivery fee - simplified since we're not showing loaders
  Future<void> refreshDeliveryFee() async {
    debugPrint('🔄 Refreshing delivery fee');

    try {
      // Call the getDeliveryFee method from ApiService
      final loadedFee = await _apiService.getDeliveryFee();
      debugPrint('✅ Successfully refreshed delivery fee: $loadedFee');

      // Set the delivery fee
      _deliveryFee = loadedFee;
    } catch (e) {
      debugPrint('❌ Error refreshing delivery fee: $e');
      // Keep current value in case of error
    } finally {
      notifyListeners();
    }
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

        // Debug log
        debugPrint('✅ Loaded ${_cartItems.length} items from cart cache');

        // Log loaded price values to debug
        for (var item in _cartItems) {
          debugPrint(
            '📊 Loaded item: ${item['name']}, price: ${item['price']}',
          );
        }

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

  // Find an item in the cart by product ID and modification data
  int _findCartItemIndex(Map<String, dynamic> product) {
    for (int i = 0; i < _cartItems.length; i++) {
      final item = _cartItems[i];

      // If product IDs don't match, this is not our item
      if (item['product_id'] != product['product_id']) {
        continue;
      }

      // Case 1: Group modifications as JSON string
      if (product.containsKey('modification') &&
          product['modification'] is String &&
          item.containsKey('modification') &&
          item['modification'] is String) {
        // Compare the actual modification content
        try {
          List<dynamic> productMods = jsonDecode(product['modification']);
          List<dynamic> itemMods = jsonDecode(item['modification']);

          // Sort both lists to ensure consistent comparison
          productMods.sort(
            (a, b) => a['m'].toString().compareTo(b['m'].toString()),
          );
          itemMods.sort(
            (a, b) => a['m'].toString().compareTo(b['m'].toString()),
          );

          // If the modifications are different, this is a different item
          if (jsonEncode(productMods) != jsonEncode(itemMods)) {
            continue;
          }

          return i;
        } catch (e) {
          debugPrint("Error comparing modifications: $e");
          continue;
        }
      }

      // Case 2: Regular modification object
      if (product.containsKey('modification') &&
          product['modification'] is Map &&
          item.containsKey('modification') &&
          item['modification'] is Map) {
        final itemModId = item['modification']['id']?.toString();
        final productModId = product['modification']['id']?.toString();

        if (itemModId == productModId) {
          return i;
        }
      }

      // Case 3: Neither has modifications
      if ((!product.containsKey('modification') ||
              product['modification'] == null) &&
          (!item.containsKey('modification') || item['modification'] == null)) {
        return i;
      }
    }

    return -1; // Item not found
  }

  void addItem(Map<String, dynamic> product) {
    debugPrint(
      "📌 Adding item to cart: ${product['name']}, price: ${product['price']}",
    );

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

      // Make a deep copy to ensure we don't modify the original product
      Map<String, dynamic> newItem = {...product, 'quantity': quantity};

      // Preserve modification details for display in cart
      if (product.containsKey('modification_details')) {
        newItem['modification_details'] = product['modification_details'];
      }

      _cartItems.add(newItem);
      debugPrint(
        "✅ New item added to cart: ${product['name']} (Qty: $quantity, Price: ${product['price']})",
      );
    }

    // Ensure delivery fee is loaded when adding items
    if (_isDelivery) {
      _loadDeliveryFee();
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

  void updateQuantity(
    int productId,
    int change, {
    String? modificationId,
    String? groupModifications,
  }) {
    try {
      // Create a dummy product to use _findCartItemIndex
      final Map<String, dynamic> dummyProduct = {'product_id': productId};

      // Add modification if provided
      if (modificationId != null) {
        dummyProduct['modification'] = {'id': modificationId};
      } else if (groupModifications != null) {
        dummyProduct['modification'] = groupModifications;
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
    } catch (e) {
      debugPrint("❌ Error updating cart item quantity: $e");
    }
  }

  // Get total price of items in cart
  int get subtotal {
    int total = 0;
    for (var item in _cartItems) {
      // Safely handle price and quantity types
      int price = 0;
      int quantity = 1;

      // Convert price to int if needed
      if (item['price'] is int) {
        price = item['price'] as int;
      } else if (item['price'] is double) {
        price = (item['price'] as double).toInt();
      } else if (item['price'] != null) {
        try {
          price = int.parse(item['price'].toString());
        } catch (e) {
          debugPrint('❌ Error parsing price: $e');
        }
      }

      // Convert quantity to int if needed
      if (item['quantity'] is int) {
        quantity = item['quantity'] as int;
      } else if (item['quantity'] is double) {
        quantity = (item['quantity'] as double).toInt();
      } else if (item['quantity'] != null) {
        try {
          quantity = int.parse(item['quantity'].toString());
        } catch (e) {
          debugPrint('❌ Error parsing quantity: $e');
        }
      }

      total += price * quantity;
      debugPrint(
        '🧮 Cart item: ${item['name']} - $price × $quantity = ${price * quantity}',
      );
    }

    debugPrint('🧮 Cart subtotal: $total');
    return total;
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
    return _cartItems.fold(0, (sum, item) {
      int quantity = 1;
      if (item['quantity'] is int) {
        quantity = item['quantity'] as int;
      } else if (item['quantity'] is double) {
        quantity = (item['quantity'] as double).toInt();
      } else if (item['quantity'] != null) {
        try {
          quantity = int.parse(item['quantity'].toString());
        } catch (e) {
          debugPrint('❌ Error parsing quantity for itemCount: $e');
        }
      }
      return sum + quantity;
    });
  }

  // Add a product model directly to cart
  void addProductModel(ProductModel product) {
    final cartItem = product.toCartItem();

    // Debug log the price before adding to cart
    debugPrint(
      "📊 Adding product model to cart: ${product.name}, original price: ${product.price}, effective price: ${product.effectivePrice}",
    );

    addItem(cartItem);
  }

  // Modified total getter in CartProvider
  // Get total price including delivery (as int)
  int get total {
    final currentDeliveryFee =
        deliveryFee; // Use the getter which handles delivery/pickup mode
    debugPrint(
      '🧮 Cart total calculation: subtotal($subtotal) + deliveryFee($currentDeliveryFee) = ${subtotal + currentDeliveryFee}',
    );
    return subtotal + currentDeliveryFee;
  }

  Future<void> prepareForCheckout() async {
    debugPrint('🛒 Preparing cart for checkout...');

    // Always refresh the delivery fee before checkout
    if (_isDelivery) {
      await refreshDeliveryFee();
    }

    // Force refresh of client data to get latest bonus
    await _apiService.refreshClientData();

    debugPrint(
      '🛒 Cart ready for checkout with delivery fee: $_deliveryFee (applied: ${_isDelivery ? "yes" : "no"})',
    );
  }

  // Improved handling of delivery fee in ensureDeliveryFeeLoaded method
  Future<int> ensureDeliveryFeeLoaded() async {
    debugPrint('📦 Ensuring delivery fee is loaded');

    // Only apply refresh if delivery is selected
    if (_isDelivery) {
      await refreshDeliveryFee(); // Always refresh for reliability
    } else {
      // If pickup is selected, make sure delivery fee is 0
      _deliveryFee = 0;
    }

    return _isDelivery ? _deliveryFee : 0;
  }

  // Make sure delivery method updates handle the fee properly
  void setDeliveryMethod(bool isDelivery) {
    debugPrint(
      '🚚 Setting delivery method: ${isDelivery ? "Delivery" : "Pickup"}',
    );
    _isDelivery = isDelivery;

    // Ensure delivery fee is loaded when switching to delivery
    if (isDelivery) {
      refreshDeliveryFee(); // Always refresh when switching to delivery
    } else {
      // When switching to pickup, explicitly set delivery fee to 0
      _deliveryFee = 0;
    }

    notifyListeners();
    _saveCartToCache();
  }
}
