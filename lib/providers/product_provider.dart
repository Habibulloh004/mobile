import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentCategoryId = 0;

  ProductProvider(this._apiService);

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int get currentCategoryId => _currentCategoryId;

  Future<void> loadProducts(int categoryId) async {
    if (_currentCategoryId == categoryId && !_isLoading && _products.isNotEmpty) {
      // If we're already showing products for this category and not loading, just return
      return;
    }

    _isLoading = true;
    _hasError = false;
    _currentCategoryId = categoryId;
    notifyListeners();

    try {
      debugPrint("🔍 Fetching products for category $categoryId...");
      final fetchedProducts = await _apiService.fetchProducts(categoryId);

      _products = fetchedProducts;
      _isLoading = false;
      _hasError = false;
      debugPrint("✅ Successfully loaded ${_products.length} products");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading products: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get a product by ID
  ProductModel? getProductById(int productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      debugPrint("⚠️ Product not found with ID: $productId");
      return null;
    }
  }

  // Refresh products for current category (force reload)
  Future<void> refreshProducts() async {
    if (_currentCategoryId == 0) {
      return; // No category selected yet
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔄 Refreshing products for category $_currentCategoryId...");
      final fetchedProducts = await _apiService.fetchProducts(_currentCategoryId);

      _products = fetchedProducts;
      _isLoading = false;
      _hasError = false;
      debugPrint("✅ Successfully refreshed ${_products.length} products");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error refreshing products: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}