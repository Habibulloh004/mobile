import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../core/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  CategoryProvider(this._apiService) {
    loadCategories();
  }

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty && !_isLoading) {
      // If we already have data and are not currently loading, just return
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔍 Fetching categories from API...");
      final fetchedCategories = await _apiService.fetchCategories();

      _categories = fetchedCategories;
      _isLoading = false;
      _hasError = false;
      debugPrint("✅ Successfully loaded ${_categories.length} categories");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading categories: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Refresh categories (force reload)
  Future<void> refreshCategories() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      debugPrint("🔄 Refreshing categories...");
      final fetchedCategories = await _apiService.fetchCategories();

      _categories = fetchedCategories;
      _isLoading = false;
      _hasError = false;
      debugPrint("✅ Successfully refreshed ${_categories.length} categories");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error refreshing categories: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}