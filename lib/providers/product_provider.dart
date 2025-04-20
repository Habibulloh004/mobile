import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  bool isLoading = false;
  final ApiService _apiService;

  List<ProductModel> get products => _products;

  ProductProvider(this._apiService);

  Future<void> loadProducts(int categoryId) async {
    isLoading = true;
    notifyListeners();

    try {
      _products = await _apiService.fetchProducts(categoryId);
    } catch (e) {
      debugPrint("❌ Error loading products: $e");
      _products = [];
    }

    isLoading = false;
    notifyListeners();
  }
}