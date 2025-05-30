import 'package:flutter/foundation.dart';
import 'package:poster_app/helpers/index.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../core/api_service.dart';

enum SearchResultType { category, product }

class SearchResult {
  final SearchResultType type;
  final dynamic data; // CategoryModel or ProductModel
  final String name;
  final String imageUrl;
  final int id;

  SearchResult({
    required this.type,
    required this.data,
    required this.name,
    required this.imageUrl,
    required this.id,
  });
}

class SearchProvider with ChangeNotifier {
  final CategoryProvider _categoryProvider;
  final ProductProvider _productProvider;
  final ApiService _apiService;

  List<SearchResult> _searchResults = [];
  String _query = '';
  bool _isLoading = false;
  bool _isGlobalSearch = false;

  // Getters
  List<SearchResult> get searchResults => _searchResults;

  String get query => _query;

  bool get isLoading => _isLoading;

  bool get isGlobalSearch => _isGlobalSearch;

  SearchProvider(
    this._categoryProvider,
    this._productProvider,
    this._apiService,
  );

  // Search in current visible categories
  Future<void> searchInCategories(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _query = '';
      _isGlobalSearch = false;
      notifyListeners();
      return;
    }

    _query = query;
    _isLoading = true;
    _isGlobalSearch = false;
    notifyListeners();

    try {
      final categories = _categoryProvider.categories;

      List<SearchResult> results = [];

      // Filter categories based on the query
      for (var category in categories) {
        if (category.name.toLowerCase().contains(query.toLowerCase())) {
          results.add(
            SearchResult(
              type: SearchResultType.category,
              data: category,
              name: category.name,
              imageUrl: category.imageUrl,
              id: category.id,
            ),
          );
        }
      }

      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching categories: $e');
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
    }
  }

  // Search in current visible products
  Future<void> searchInProducts(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _query = '';
      _isGlobalSearch = false;
      notifyListeners();
      return;
    }

    _query = query;
    _isLoading = true;
    _isGlobalSearch = false;
    notifyListeners();

    try {
      final products = _productProvider.products;

      List<SearchResult> results = [];

      // Filter products based on the query
      for (var product in products) {
        if (product.name.toLowerCase().contains(query.toLowerCase())) {
          results.add(
            SearchResult(
              type: SearchResultType.product,
              data: product,
              name: product.name,
              imageUrl: product.imageUrl,
              id: product.id,
            ),
          );
        }
      }

      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching products: $e');
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
    }
  }

  Future<void> globalSearch(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _query = '';
      _isGlobalSearch = false;
      notifyListeners();
      return;
    }

    debugPrint('🔍 Starting global search for: "$query"');
    _query = query;
    _isLoading = true;
    _isGlobalSearch = true;
    notifyListeners();

    try {
      List<SearchResult> results = [];
      List<ProductModel> allFoundProducts = []; // To collect all found products

      // First, make sure categories are loaded
      if (_categoryProvider.categories.isEmpty) {
        debugPrint('📋 Loading categories as they are empty');
        await _categoryProvider.loadCategories();
      }

      debugPrint(
        '📋 Searching in ${_categoryProvider.categories.length} categories',
      );

      // Search in categories
      for (var category in _categoryProvider.categories) {
        if (category.name.toLowerCase().contains(query.toLowerCase())) {
          debugPrint(
            '✅ Found matching category: ${category.name} (ID: ${category.id})',
          );
          results.add(
            SearchResult(
              type: SearchResultType.category,
              data: category,
              name: category.name,
              imageUrl: category.imageUrl,
              id: category.id,
            ),
          );
        }

        // Load and search in products for this category
        try {
          final products = await _apiService.fetchProducts(category.id);
          debugPrint(
            '📦 Fetched ${products.length} products for category: ${category.name}',
          );

          // Prepare products by selecting default modifiers
          for (var product in products) {
            // Ensure first modifier is selected if available and none is selected
            if (product.modifications != null &&
                product.modifications!.isNotEmpty &&
                product.selectedModification == null) {
              product.selectedModification = product.modifications!.first;
            }

            // Check for match in product name
            if (cleanProductName(
              product.name,
            ).toLowerCase().contains(query.toLowerCase())) {
              debugPrint(
                '✅ Found matching product: ${cleanProductName(product.name)} (ID: ${product.id})',
              );

              // Add to results
              results.add(
                SearchResult(
                  type: SearchResultType.product,
                  data: product,
                  // Product with default modifier selected
                  name: product.name,
                  imageUrl: product.imageUrl,
                  id: product.id,
                ),
              );

              // Add to the collection of all products for the provider
              allFoundProducts.add(product);
            }
          }
        } catch (e) {
          // Just log the error and continue with other categories
          debugPrint(
            '❌ Error fetching products for category ${category.id}: $e',
          );
        }
      }

      // Important: Add all found products to the ProductProvider using the public method
      if (allFoundProducts.isNotEmpty) {
        debugPrint(
          '⚙️ Adding ${allFoundProducts.length} products to ProductProvider',
        );
        _productProvider.addProducts(allFoundProducts);
      }

      debugPrint('🔍 Global search complete. Found ${results.length} results');
      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error in global search: $e');
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _query = '';
    _isGlobalSearch = false;
    notifyListeners();
  }
}
