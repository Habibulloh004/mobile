import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final String posterApiToken;
  List<ProductModel> _products = [];
  bool isLoading = false;

  List<ProductModel> get products => _products;

  ProductProvider(this.posterApiToken);
  Future<void> loadProducts(int categoryId) async {
    isLoading = true;
    notifyListeners();

    final url = "https://joinposter.com/api/menu.getProducts?token=$posterApiToken";

    try {
      final response = await Dio().get(url);

      // ✅ Выводим полный JSON ответа от сервера
      debugPrint("📥 Получен JSON продуктов: ${response.data}");

      if (response.statusCode == 200 && response.data['response'] is List) {
        _products = (response.data['response'] as List)
            .where((item) => int.tryParse(item['menu_category_id'].toString()) == categoryId)
            .map((item) {
          // ✅ Выводим каждый товар перед парсингом
          debugPrint("🔍 Парсим продукт: $item");
          return ProductModel.fromJson(item);
        })
            .toList();
      } else {
        _products = [];
        debugPrint("⚠️ Продукты не найдены или неверный формат данных");
      }
    } catch (e) {
      debugPrint("❌ Ошибка загрузки товаров: $e");
      _products = [];
    }

    isLoading = false;
    notifyListeners();
  }


}
