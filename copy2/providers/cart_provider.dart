import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];  // Список товаров в корзине

  List<Map<String, dynamic>> get cartItems => _cartItems;  // Геттер для получения списка товаров

  void addItem(Map<String, dynamic> product) {
    print("📌 addItem вызван для ${product['product_id']}"); // ✅ Проверка
    final existingIndex = _cartItems.indexWhere(
            (item) => item['product_id'] == product['product_id']);
    if (existingIndex >= 0) {
      print("🔄 Товар уже в корзине, увеличиваем количество");
      _cartItems[existingIndex]['quantity'] += 1;
    } else {
      print("✅ Новый товар добавлен в корзину: ${product['name']}");
      _cartItems.add({...product, 'quantity': 1});
    }

    notifyListeners();
  }


  void removeItem(Map<String, dynamic> product) {
    // ✅ Удаляем товар по `product_id`
    _cartItems.removeWhere((item) => item['product_id'] == product['product_id']);
    notifyListeners();  // ✅ Обновляем UI
  }

  void updateQuantity(int productId, int change) {
    final index = _cartItems.indexWhere((item) => item['product_id'] == productId);
    if (index >= 0) {
      _cartItems[index]['quantity'] += change;
      if (_cartItems[index]['quantity'] <= 0) {
        _cartItems.removeAt(index); // Если количество стало 0 — удаляем товар
      }
      notifyListeners();
    }
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _cartItems) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    return total;
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
