import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final String posterApiToken;
  List<CategoryModel> _categories = [];
  bool isLoading = true;

  List<CategoryModel> get categories => _categories;

  CategoryProvider(this.posterApiToken);

  Future<void> loadCategories() async {
    final url = "https://joinposter.com/api/menu.getCategories?token=$posterApiToken";

    try {
      final response = await Dio().get(url);

      if (response.statusCode == 200 && response.data["response"] is List) {
        _categories = (response.data["response"] as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      } else {
        _categories = [];
      }
    } catch (e) {
      debugPrint("❌ Ошибка загрузки категорий: $e");
      _categories = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
