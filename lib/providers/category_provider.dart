import 'package:flutter/foundation.dart';
import 'package:poster_app/models/category_model.dart';
import '../core/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  CategoryProvider(this._apiService);

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty && !_isLoading) {
      // We already have data and are not loading
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      print("Fetching categories from API...");
      final fetchedCategory = await _apiService.fetchCategories();

      _categories = fetchedCategory;
      _isLoading = false;
      _hasError = false;
      print("Successfully loaded ${_categories.length} categories");
      notifyListeners();
    } catch (e) {
      print("Error loading categories: $e");
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
      // We don't rethrow - we handle the error state in the provider
    }
  }
}