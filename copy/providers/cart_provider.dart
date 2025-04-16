import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addItem(Map<String, dynamic> product) {
    _cartItems.add(product);
    notifyListeners();
  }

  void removeItem(Map<String, dynamic> product) {
    _cartItems.remove(product);
    notifyListeners();
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _cartItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  Future<void> loadCart() async {
    // Реализация загрузки корзины (если требуется)
  }
}
