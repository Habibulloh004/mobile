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

  // Add this method to your ProductProvider class

  // Add a new product to the provider's list
  void addProduct(ProductModel product) {
    // Check if product already exists to avoid duplicates
    if (!_products.any((p) => p.id == product.id)) {
      _products.add(product);
      notifyListeners();
    }
  }

  // Add multiple products at once
  void addProducts(List<ProductModel> newProducts) {
    bool productsAdded = false;

    for (var product in newProducts) {
      // Add only if not already present
      if (!_products.any((p) => p.id == product.id)) {
        _products.add(product);
        productsAdded = true;
      }
    }

    if (productsAdded) {
      notifyListeners();
    }
  }

  Future<void> loadProducts(int categoryId) async {
    if (_currentCategoryId == categoryId &&
        !_isLoading &&
        _products.isNotEmpty) {
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
  // Get a product by ID
  ProductModel? getProductById(int productId) {
    try {
      debugPrint(
        '🔍 Searching for product with ID: $productId among ${products.length} products',
      );
      final product = _products.firstWhere(
        (product) => product.id == productId,
      );
      debugPrint('✅ Found product: ${product.name}');
      return product;
    } catch (e) {
      debugPrint("⚠️ Product not found with ID: $productId");
      return null;
    }
  }

  // Fetch a specific product by ID (useful when product isn't in current list)
  Future<ProductModel?> fetchProductById(int productId) async {
    debugPrint('🔍 Attempting to fetch specific product with ID: $productId');
    _isLoading = true;
    notifyListeners();

    try {
      // First check if already in our list
      final existingProduct = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => null as ProductModel,
      );

      if (existingProduct != null) {
        debugPrint('✅ Product found in existing list: ${existingProduct.name}');
        _isLoading = false;
        notifyListeners();
        return existingProduct;
      }

      // If not in current list, need to fetch it
      // This requires a new API endpoint or searching through categories
      debugPrint('🔄 Product not in current list, refreshing all products');
      await refreshProducts();

      // Check again after refresh
      final refreshedProduct = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => null as ProductModel,
      );

      _isLoading = false;
      notifyListeners();

      if (refreshedProduct != null) {
        debugPrint('✅ Product found after refresh: ${refreshedProduct.name}');
        return refreshedProduct;
      } else {
        debugPrint('❌ Product still not found after refresh');
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching product by ID: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
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
      final fetchedProducts = await _apiService.fetchProducts(
        _currentCategoryId,
      );

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
